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
    private var lastLocalChangeTime: Date = Date.distantPast
    
    @Published var isEnabled = true
    @Published var dataCleared = false
    @Published var firebaseEntryCount = 0
    @Published var isSynced = false
    @Published var lastSyncDate: Date?
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func start() {
        print("🔄 Starting FirestoreSyncService")
        
        // Test Firebase connection first
        if let user = Auth.auth().currentUser {
            if user.isAnonymous {
                print("❌ Anonymous user detected - sync disabled")
                isEnabled = false
                return
            } else {
                print("✅ User already authenticated: \(user.uid)")
            }
        } else {
            print("❌ No authenticated user - sync will not work")
            isEnabled = false
            return
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
        
        // 2) Perform initial sync
        performInitialSync()
        
        // 3) Listen for remote changes
        attachRemoteListener()
        
        // 4) Fetch initial Firebase count
        fetchFirebaseEntryCount()
    }
    
    func disableSync() {
        print("🚫 Disabling sync")
        isEnabled = false
    }
    
    func enableSync() {
        print("✅ Enabling sync")
        isEnabled = true
        // Trigger sync status update
        updateSyncStatus()
    }
    
    /// Triggers a data refresh across all views
    func triggerDataRefresh() {
        DispatchQueue.main.async {
            // Force Core Data context refresh first
            self.context.refreshAllObjects()
            self.context.processPendingChanges()
            
            // Update sync status
            self.updateSyncStatus()
            
            // Then trigger UI refresh
            self.dataCleared.toggle()
            // Reset after a brief moment to allow views to react
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.dataCleared.toggle()
            }
        }
    }
    
    // MARK: - Initial Sync Methods
    
    private func performInitialSync() {
        print("🔄 Performing initial sync...")
        guard let col = userCollection() else {
            print("❌ No user collection available for initial sync")
            return
        }
        
        // Check if we have a lastPullKey - if not, this is first time sync
        let hasLastPull = UserDefaults.standard.object(forKey: lastPullKey) != nil
        
        if !hasLastPull {
            print("🔄 First time sync - pulling all Firebase data")
            pullAllFirebaseData(from: col)
        } else {
            print("🔄 Incremental sync - pulling changes since last sync")
            // The remote listener will handle incremental changes
            updateSyncStatus()

            fetchFirebaseEntryCount()
        }
    }
    
    private func pullAllFirebaseData(from col: CollectionReference) {
        col.getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Failed to fetch Firebase data: \(error)")
                DispatchQueue.main.async {
                    self.isSynced = false
                }
                return
            }
            
            guard let snapshot = snapshot else {
                print("❌ No snapshot received")
                DispatchQueue.main.async {
                    self.isSynced = false
                }
                return
            }
            
            print("📥 Fetched \(snapshot.documents.count) documents from Firebase")
            
            self.context.perform {
                // Import all Firebase documents
                for document in snapshot.documents {
                    let data = document.data()
                    self.createLocalEntry(from: data)
                }
                
                // Save context
                do {
                    try self.context.save()
                    print("✅ Successfully synced Firebase data to local")
                    
                    // Update lastPullKey
                    UserDefaults.standard.set(Date(), forKey: self.lastPullKey)
                    
                    DispatchQueue.main.async {
                        self.isSynced = true
                        self.lastSyncDate = Date()
                        self.firebaseEntryCount = snapshot.documents.count
                    }
                } catch {
                    print("❌ Failed to save context: \(error)")
                    DispatchQueue.main.async {
                        self.isSynced = false
                    }
                }
            }
        }
    }
    
    private func updateSyncStatus() {
        // Compare local and Firebase entry counts
        let localCount = getLocalEntryCount()
        let firebaseCount = firebaseEntryCount
        
        DispatchQueue.main.async {
            // Data is synced if:
            // 1. Both local and Firebase have the same count (and count > 0)
            // 2. Both are empty (count == 0)
            // 3. We have a recent lastPullKey (within last 5 minutes)
            let countsMatch = localCount == firebaseCount
            let bothEmpty = localCount == 0 && firebaseCount == 0
            let hasRecentSync = self.hasRecentSync()
            
            self.isSynced = (countsMatch && (localCount > 0 || bothEmpty)) || hasRecentSync
            
            if self.isSynced {
                self.lastSyncDate = UserDefaults.standard.object(forKey: self.lastPullKey) as? Date
            }
            
            print("🔄 Sync status update - Local: \(localCount), Firebase: \(firebaseCount), Synced: \(self.isSynced)")
        }
    }
    
    private func hasRecentSync() -> Bool {
        guard let lastPull = UserDefaults.standard.object(forKey: lastPullKey) as? Date else {
            return false
        }
        // Consider synced if last pull was within last 5 minutes
        return Date().timeIntervalSince(lastPull) < 300 // 5 minutes
    }
    
    private func getLocalEntryCount() -> Int {
        let request = NSFetchRequest<MoodEntry>(entityName: "MoodEntry")
        request.predicate = NSPredicate(format: "isSoftDeleted == NO OR isSoftDeleted == nil")
        return (try? context.count(for: request)) ?? 0
    }
    
    // MARK: - Firebase Count Methods
    
    func fetchFirebaseEntryCount() {
        guard let col = userCollection() else {
            print("❌ No user collection available for count")
            return
        }
        
        col.getDocuments { [weak self] snapshot, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Failed to fetch Firebase count: \(error)")
                    self?.firebaseEntryCount = 0
                    self?.isSynced = false
                } else if let snapshot = snapshot {
                    print("📊 Firebase entry count: \(snapshot.documents.count)")
                    self?.firebaseEntryCount = snapshot.documents.count
                    self?.updateSyncStatus()
                } else {
                    print("❌ No snapshot received for count")
                    self?.firebaseEntryCount = 0
                    self?.isSynced = false
                }
            }
        }
    }
    
    // MARK: - Debug Methods
    
    func testFirebaseConnection(completion: @escaping (Bool, String) -> Void) {
        print("🧪 Testing Firebase connection...")
        
        // Check authentication
        if let user = Auth.auth().currentUser {
            if user.isAnonymous {
                print("❌ Anonymous user - sync not allowed")
                completion(false, "Anonymous users cannot sync. Please sign in with email/password.")
                return
            } else {
                print("✅ User authenticated: \(user.uid)")
            }
        } else {
            print("❌ No authenticated user")
            completion(false, "No authenticated user")
            return
        }
        
        // Check Firestore connection
        guard let col = userCollection() else {
            print("❌ Cannot get user collection")
            completion(false, "Cannot get user collection")
            return
        }
        
        print("✅ User collection path: \(col.path)")
        
        // Test write
        let testDoc = col.document("test")
        testDoc.setData([
            "test": true,
            "timestamp": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                print("❌ Test write failed: \(error)")
                completion(false, "Test write failed: \(error.localizedDescription)")
            } else {
                print("✅ Test write successful")
                // Clean up test document
                testDoc.delete { error in
                    if let error = error {
                        print("⚠️ Failed to delete test document: \(error)")
                        completion(true, "Connection successful, but cleanup failed: \(error.localizedDescription)")
                    } else {
                        print("✅ Test document cleaned up")
                        completion(true, "Firebase connection test passed! ✅")
                    }
                }
            }
        }
    }
    
    // MARK: - Data Override Methods
    
    /// Overwrites local Core Data with Firebase data
    func overwriteLocalWithFirebase() {
        print("🔄 Starting overwrite: Local ← Firebase")
        guard let col = userCollection() else {
            print("❌ No user collection available")
            return
        }
        
        // Disable sync temporarily to prevent conflicts
        let wasEnabled = isEnabled
        isEnabled = false
        
        col.getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Failed to fetch Firebase data: \(error)")
                self.isEnabled = wasEnabled
                return
            }
            
            guard let snapshot = snapshot else {
                print("❌ No snapshot received")
                self.isEnabled = wasEnabled
                return
            }
            
            print("📥 Fetched \(snapshot.documents.count) documents from Firebase")
            
            self.context.perform {
                // Clear all local MoodEntry objects
                self.clearAllLocalEntries()
                
                // Import all Firebase documents
                for document in snapshot.documents {
                    let data = document.data()
                    self.createLocalEntry(from: data)
                }
                
                // Save context
                do {
                    try self.context.save()
                    print("✅ Successfully overwrote local data with Firebase")

                    // Trigger UI refresh after successful data import
                    DispatchQueue.main.async {
                        self.triggerDataRefresh()
                    }
                } catch {
                    print("❌ Failed to save context: \(error)")
                }
                
                // Update Firebase count
                DispatchQueue.main.async {
                    self.firebaseEntryCount = snapshot.documents.count
                }
                
                // Re-enable sync
                self.isEnabled = wasEnabled
            }
        }
    }
    
    /// Overwrites Firebase with local Core Data
    func overwriteFirebaseWithLocal() {
        print("🔄 Starting overwrite: Firebase ← Local")
        guard let col = userCollection() else {
            print("❌ No user collection available")
            return
        }
        
        // Disable sync temporarily to prevent conflicts
        let wasEnabled = isEnabled
        isEnabled = false
        
        context.perform { [weak self] in
            guard let self = self else { return }
            
            // Fetch all local MoodEntry objects
            let request = NSFetchRequest<MoodEntry>(entityName: "MoodEntry")
            request.predicate = NSPredicate(format: "isSoftDeleted == NO OR isSoftDeleted == nil")
            
            do {
                let localEntries = try self.context.fetch(request)
                print("📤 Found \(localEntries.count) local entries to upload")
                
                // Clear Firebase collection first
                self.clearFirebaseCollection(col: col) { [weak self] in
                    guard let self = self else { return }
                    
                    // Upload all local entries
                    self.uploadLocalEntries(localEntries, to: col) { [weak self] in
                        guard let self = self else { return }
                        print("✅ Successfully overwrote Firebase with local data")
                        
                        // Update Firebase count
                        DispatchQueue.main.async {
                            self.firebaseEntryCount = localEntries.count
                        }
                        
                        self.isEnabled = wasEnabled
                    }
                }
            } catch {
                print("❌ Failed to fetch local entries: \(error)")
                self.isEnabled = wasEnabled
            }
        }
    }
    
    /// Force sync all local changes to Firebase
    func forceSyncToFirebase() {
        print("🔄 Force syncing local changes to Firebase")
        guard let col = userCollection() else {
            print("❌ No user collection available")
            return
        }
        
        context.perform { [weak self] in
            guard let self = self else { return }
            
            let request = NSFetchRequest<MoodEntry>(entityName: "MoodEntry")
            request.predicate = NSPredicate(format: "isSoftDeleted == NO OR isSoftDeleted == nil")
            
            do {
                let localEntries = try self.context.fetch(request)
                print("📤 Force syncing \(localEntries.count) local entries")
                
                for entry in localEntries {
                    self.pushUpsert(entry, to: col)
                }
                
                print("✅ Force sync completed")
            } catch {
                print("❌ Failed to force sync: \(error)")
            }
        }
    }
    
    deinit { listener?.remove() }

    // MARK: - Helpers
    
    private func userCollection() -> CollectionReference? {
        guard let user = Auth.auth().currentUser else { 
            print("❌ No authenticated user - sync will not work")
            return nil 
        }
        
        // Don't allow sync for anonymous users
        if user.isAnonymous {
            print("❌ Anonymous user detected - sync disabled")
            return nil
        }
        
        print("✅ User authenticated with UID: \(user.uid)")
        return db.collection("users").document(user.uid).collection("moodEntries")
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
        
        // Track when we make local changes
        lastLocalChangeTime = Date()
        
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
        
        // Hard delete: actually remove documents from Firebase
        let deletedMoodEntries = deletes.filter { $0.entity.name == "MoodEntry" }
        print("🗑️ Processing \(deletedMoodEntries.count) deleted MoodEntry objects")
        for obj in deletedMoodEntries {
            guard let entry = obj as? MoodEntry else { continue }
            guard let id = entry.id else { continue }
            print("🗑️ Hard-deleting entry \(id.uuidString)")
            col.document(id.uuidString).delete { error in
                if let error = error {
                    print("❌ Failed to delete entry \(id.uuidString): \(error)")
                } else {
                    print("✅ Successfully deleted entry \(id.uuidString)")
                }
            }
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
            "lastModified": Timestamp(date: lastModified)
        ]
        
        col.document(id.uuidString).setData(data, merge: true) { [weak self] error in
            if let error = error {
                print("❌ Failed to push entry \(id.uuidString): \(error)")
                DispatchQueue.main.async {
                    self?.isSynced = false
                }
            } else {
                print("✅ Successfully pushed entry \(id.uuidString)")
                DispatchQueue.main.async {
                    self?.updateSyncStatus()
                }
            }
        }
    }
    
    private func applyRemoteChanges(snap: QuerySnapshot) {
        // Skip processing if we're already applying remote changes to prevent circular sync
        guard !isApplyingRemoteChanges else {
            print("🚫 Skipping remote changes - already processing")
            return
        }
        
        // Skip processing if we just made local changes (within last 3 seconds)
        // This prevents circular sync when local deletions trigger remote changes
        let timeSinceLastLocalChange = Date().timeIntervalSince(lastLocalChangeTime)
        if timeSinceLastLocalChange < 3.0 {
            print("🚫 Skipping remote changes - too soon after local change (\(timeSinceLastLocalChange)s ago)")
            return
        }
        
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
                
                // Apply fields (hard deletes mean documents are actually removed)
                entry.setValue(id, forKey: "id")
                entry.setValue((data["score"] as? Int) ?? 0, forKey: "score")
                entry.setValue(data["note"] as? String ?? "", forKey: "note")
                entry.setValue((data["timestamp"] as? Timestamp)?.dateValue() ?? Date(), forKey: "timestamp")
                entry.setValue(data["latitude"] as? Double, forKey: "latitude")
                entry.setValue(data["longitude"] as? Double, forKey: "longitude")
                entry.setValue(data["placename"] as? String ?? "", forKey: "placename")
                entry.setValue(remoteLM, forKey: "lastModified")
            }
            try? self.context.save()
            self.isApplyingRemoteChanges = false
            
            // Update Firebase count and sync status after processing changes
            DispatchQueue.main.async {
                self.firebaseEntryCount = snap.documents.count
                self.updateSyncStatus()
            }
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
    
    // MARK: - Override Helper Methods
    
    private func clearAllLocalEntries() {
        let request = NSFetchRequest<MoodEntry>(entityName: "MoodEntry")
        
        do {
            let entries = try context.fetch(request)
            for entry in entries {
                context.delete(entry)
            }
            try context.save()
            print("🗑️ Cleared \(entries.count) local MoodEntry objects")
        } catch {
            print("❌ Failed to clear local entries: \(error)")
        }
    }
    
    private func createLocalEntry(from data: [String: Any]) {
        guard let idStr = data["id"] as? String,
              let id = UUID(uuidString: idStr) else {
            print("❌ Invalid ID in Firebase data")
            return
        }
        
        let entry = MoodEntry(context: context)
        entry.setValue(id, forKey: "id")
        entry.setValue((data["score"] as? Int) ?? 0, forKey: "score")
        entry.setValue(data["note"] as? String ?? "", forKey: "note")
        entry.setValue((data["timestamp"] as? Timestamp)?.dateValue() ?? Date(), forKey: "timestamp")
        entry.setValue(data["latitude"] as? Double, forKey: "latitude")
        entry.setValue(data["longitude"] as? Double, forKey: "longitude")
        entry.setValue(data["placename"] as? String ?? "", forKey: "placename")
        entry.setValue((data["lastModified"] as? Timestamp)?.dateValue() ?? Date(), forKey: "lastModified")
        
        print("📝 Created local entry: \(idStr)")
    }
    
    private func clearFirebaseCollection(col: CollectionReference, completion: @escaping () -> Void) {
        col.getDocuments { snapshot, error in
            if let error = error {
                print("❌ Failed to fetch Firebase documents for clearing: \(error)")
                completion()
                return
            }
            
            guard let snapshot = snapshot else {
                print("❌ No snapshot for clearing")
                completion()
                return
            }
            
            let batch = col.firestore.batch()
            for document in snapshot.documents {
                batch.deleteDocument(document.reference)
            }
            
            batch.commit { error in
                if let error = error {
                    print("❌ Failed to clear Firebase collection: \(error)")
                } else {
                    print("🗑️ Cleared Firebase collection")
                }
                completion()
            }
        }
    }
    
    private func uploadLocalEntries(_ entries: [MoodEntry], to col: CollectionReference, completion: @escaping () -> Void) {
        let batch = col.firestore.batch()
        
        for entry in entries {
            guard let id = entry.id else { continue }
            
            let data: [String: Any] = [
                "id": id.uuidString,
                "score": entry.score,
                "note": entry.note ?? "",
                "timestamp": Timestamp(date: entry.timestamp ?? Date()),
                "latitude": entry.latitude != 0 ? entry.latitude : NSNull(),
                "longitude": entry.longitude != 0 ? entry.longitude : NSNull(),
                "placename": entry.placename ?? "",
                "lastModified": Timestamp(date: entry.lastModified ?? Date())
            ]
            
            let docRef = col.document(id.uuidString)
            batch.setData(data, forDocument: docRef)
        }
        
        batch.commit { error in
            if let error = error {
                print("❌ Failed to upload local entries: \(error)")
            } else {
                print("📤 Uploaded \(entries.count) local entries to Firebase")
            }
            completion()
        }
    }
}
