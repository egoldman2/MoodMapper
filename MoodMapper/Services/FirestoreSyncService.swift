//
//  FirestoreSyncService.swift
//  MoodMapper
//
//  Created by Ethan on 5/10/2025.
//


import Foundation
import CoreData
import FirebaseFirestore
import FirebaseAuth
import Combine

final class FirestoreSyncService: ObservableObject {
    private let context: NSManagedObjectContext
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private let lastPullKey = "sync.lastPull"
    private var isApplyingRemoteChanges = false
    private var isEnabled = true
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func start() {
        print("🔄 Starting FirestoreSyncService")
        
        // Test Firebase connection first
        if let user = Auth.auth().currentUser {
            print("✅ User already authenticated: \(user.uid)")
        } else {
            print("❌ No authenticated user - sync will not work")
        }
        
        // 1) Observe local changes
        NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextDidSave,
            object: context,
            queue: .main
        ) { [weak self] note in
            print("🔔 Core Data notification received from context: \(String(describing: note.object))")
            self?.pushLocalChanges(note: note)
        }
        
        // 2) Listen for remote changes
        attachRemoteListener()
    }
    
    func disableSync() {
        print("🚫 Disabling sync")
        isEnabled = false
    }
    
    func enableSync() {
        print("✅ Enabling sync")
        isEnabled = true
    }
    
    deinit { listener?.remove() }

    // MARK: - Helpers
    
    private func userCollection() -> CollectionReference? {
        guard let uid = Auth.auth().currentUser?.uid else { 
            print("❌ No authenticated user - sync will not work")
            return nil 
        }
        print("✅ User authenticated with UID: \(uid)")
        return db.collection("users").document(uid).collection("moodEntries")
    }
    
    private func attachRemoteListener() {
        guard let col = userCollection() else { return }
        let since = UserDefaults.standard.object(forKey: lastPullKey) as? Date
        let query: Query = (since != nil)
            ? col.whereField("lastModified", isGreaterThan: Timestamp(date: since!))
            : col
        
        listener = query.addSnapshotListener { [weak self] snap, err in
            guard let self = self, let snap = snap, err == nil else { return }
            self.applyRemoteChanges(snap: snap)
            // Only update lastPullKey if we actually processed changes
            if !snap.documentChanges.isEmpty {
                UserDefaults.standard.set(Date(), forKey: self.lastPullKey)
                print("✅ Updated lastPullKey to: \(Date())")
            }
        }
    }
    
    private func pushLocalChanges(note: Notification) {
        print("💾 Core Data save detected - checking for sync...")
        print("🔍 Notification object: \(String(describing: note.object))")
        print("🔍 Expected context: \(context)")
        if let notificationContext = note.object as? NSManagedObjectContext {
            print("🔍 Notification matches our context: \(notificationContext === context)")
        } else {
            print("🔍 Notification object is not a context")
        }
        
        // Don't push changes if sync is disabled
        guard isEnabled else { 
            print("🚫 Sync disabled")
            return 
        }
        // Don't push changes if we're currently applying remote changes
        guard !isApplyingRemoteChanges else { 
            print("🚫 Skipping push - applying remote changes")
            return 
        }
        guard let col = userCollection() else { 
            print("🚫 No user collection available")
            return 
        }
        let inserts = note.userInfo?[NSInsertedObjectsKey] as? Set<NSManagedObject> ?? Set()
        let updates = note.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject> ?? Set()
        let deletes = note.userInfo?[NSDeletedObjectsKey] as? Set<NSManagedObject> ?? Set()
        
        print("📊 Core Data changes: \(inserts.count) inserts, \(updates.count) updates, \(deletes.count) deletes")
        
        // Debug: Print entity names
        for obj in inserts {
            print("📝 Inserted: \(obj.entity.name ?? "unknown")")
        }
        for obj in updates {
            print("📝 Updated: \(obj.entity.name ?? "unknown")")
        }
        for obj in deletes {
            print("📝 Deleted: \(obj.entity.name ?? "unknown")")
        }
        
        let changed = inserts.union(updates).filter { $0.entity.name == "MoodEntry" }
        print("🔄 Pushing \(changed.count) changed MoodEntry objects")
        for obj in changed { pushUpsert(obj as! MoodEntry, to: col) }
        
        // Soft-delete: mark in the cloud instead of removing document
        for obj in deletes where obj.entity.name == "MoodEntry" {
            guard let entry = obj as? MoodEntry else { continue }
            guard let id = entry.id else { continue }
            col.document(id.uuidString).setData([
                "id": id.uuidString,
                "isSoftDeleted": true,
                "lastModified": Timestamp(date: (entry.value(forKey: "lastModified") as? Date) ?? Date())
            ], merge: true)
        }
    }
    
    private func pushUpsert(_ entry: MoodEntry, to col: CollectionReference) {
        guard let id = entry.id else { 
            print("❌ Entry has no ID, skipping")
            return 
        }
        let lastModified = entry.lastModified ?? Date()
        print("🔄 Pushing entry \(id.uuidString) with lastModified: \(lastModified)")
        
        let data: [String: Any] = [
            "id": id.uuidString,
            "score": entry.score,
            "note": entry.note ?? "",
            "timestamp": Timestamp(date: entry.timestamp ?? Date()),
            "latitude": entry.latitude != 0 ? entry.latitude : NSNull(),
            "longitude": entry.longitude != 0 ? entry.longitude : NSNull(),
            "placename": entry.placename ?? "",
            "isSoftDeleted": entry.isSoftDeleted,
            "lastModified": Timestamp(date: lastModified)
        ]
        
        col.document(id.uuidString).setData(data, merge: true) { error in
            if let error = error {
                print("❌ Failed to push entry \(id.uuidString): \(error)")
            } else {
                print("✅ Successfully pushed entry \(id.uuidString)")
            }
        }
    }
    
    private func applyRemoteChanges(snap: QuerySnapshot) {
        isApplyingRemoteChanges = true
        context.perform {
            for change in snap.documentChanges {
                let data = change.document.data()
                guard let idStr = data["id"] as? String, let id = UUID(uuidString: idStr) else { continue }
                
                // Fetch or create local object
                let entry = self.fetchOrCreate(id: id)
                
                // Conflict resolution (last write wins by timestamp)
                let remoteLM = (data["lastModified"] as? Timestamp)?.dateValue() ?? .distantPast
                let localLM = (entry.value(forKey: "lastModified") as? Date) ?? .distantPast
                guard remoteLM >= localLM else { continue }
                
                // Apply fields
                if let isSoftDeleted = data["isSoftDeleted"] as? Bool, isSoftDeleted {
                    // Soft-delete locally as well
                    self.context.delete(entry)
                } else {
                    entry.setValue(id, forKey: "id")
                    entry.setValue((data["score"] as? Int) ?? 0, forKey: "score")
                    entry.setValue(data["note"] as? String ?? "", forKey: "note")
                    entry.setValue((data["timestamp"] as? Timestamp)?.dateValue() ?? Date(), forKey: "timestamp")
                    entry.setValue(data["latitude"] as? Double, forKey: "latitude")
                    entry.setValue(data["longitude"] as? Double, forKey: "longitude")
                    entry.setValue(data["placename"] as? String ?? "", forKey: "placename")
                    entry.setValue(false, forKey: "isSoftDeleted")
                    entry.setValue(remoteLM, forKey: "lastModified")
                }
            }
            try? self.context.save()
            self.isApplyingRemoteChanges = false
        }
    }
    
    private func fetchOrCreate(id: UUID) -> MoodEntry {
        let req = NSFetchRequest<MoodEntry>(entityName: "MoodEntry")
        req.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        req.fetchLimit = 1
        if let found = try? context.fetch(req).first { return found }
        let obj = MoodEntry(context: context)
        obj.setValue(id, forKey: "id")
        return obj
    }
}
