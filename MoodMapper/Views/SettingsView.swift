//
//  SettingsView.swift
//  MoodMapper
//
//  Created by Ethan on 5/10/2025.
//

import SwiftUI
import CoreData

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var syncService: FirestoreSyncService
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var alertAction: (() -> Void)?
    @State private var isProcessing = false
    @State private var showTestAlert = false
    @State private var testResult = ""
    
    var body: some View {
        NavigationStack {
            List {
                // Sync Status Section
                Section("Sync Status") {
                    HStack {
                        Image(systemName: syncService.isEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(syncService.isEnabled ? .green : .red)
                        Text("Sync is \(syncService.isEnabled ? "Enabled" : "Disabled")")
                            .font(.headline)
                    }
                    
                    if !syncService.isEnabled {
                        Button("Enable Sync") {
                            syncService.enableSync()
                        }
                        .foregroundColor(.blue)
                    } else {
                        Button("Disable Sync") {
                            syncService.disableSync()
                        }
                        .foregroundColor(.orange)
                    }
                }
                
                // Data Management Section
                Section("Data Management") {
                    Button(action: {
                        showAlert(
                            title: "Force Sync to Firebase",
                            message: "This will upload all your local mood entries to Firebase. Continue?",
                            action: {
                                isProcessing = true
                                syncService.forceSyncToFirebase()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    isProcessing = false
                                }
                            }
                        )
                    }) {
                        HStack {
                            Image(systemName: "icloud.and.arrow.up")
                                .foregroundColor(.blue)
                            Text("Force Sync to Firebase")
                            Spacer()
                            if isProcessing {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .disabled(isProcessing)
                    
                    Button(action: {
                        showAlert(
                            title: "Overwrite Local with Firebase",
                            message: "⚠️ WARNING: This will replace ALL your local mood entries with Firebase data. This action cannot be undone. Continue?",
                            action: {
                                isProcessing = true
                                syncService.overwriteLocalWithFirebase()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    isProcessing = false
                                }
                            }
                        )
                    }) {
                        HStack {
                            Image(systemName: "icloud.and.arrow.down")
                                .foregroundColor(.green)
                            Text("Restore from Firebase")
                            Spacer()
                            if isProcessing {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .disabled(isProcessing)
                    
                    Button(action: {
                        showAlert(
                            title: "Overwrite Firebase with Local",
                            message: "⚠️ WARNING: This will replace ALL Firebase data with your local mood entries. This action cannot be undone. Continue?",
                            action: {
                                isProcessing = true
                                syncService.overwriteFirebaseWithLocal()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    isProcessing = false
                                }
                            }
                        )
                    }) {
                        HStack {
                            Image(systemName: "icloud.and.arrow.up.fill")
                                .foregroundColor(.orange)
                            Text("Upload Local to Firebase")
                            Spacer()
                            if isProcessing {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .disabled(isProcessing)
                }
                
                // Data Information Section
                Section("Data Information") {
                    DataInfoRow(
                        title: "Local Entries",
                        count: localEntryCount,
                        icon: "internaldrive",
                        color: .blue
                    )
                    
                    DataInfoRow(
                        title: "Firebase Entries",
                        count: firebaseEntryCount,
                        icon: "icloud",
                        color: .green
                    )
                }
                
                // Debug Section
                Section("Debug") {
                    Button(action: {
                        syncService.testFirebaseConnection { success, message in
                            DispatchQueue.main.async {
                                testResult = message
                                showTestAlert = true
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "wrench.and.screwdriver")
                                .foregroundColor(.purple)
                            Text("Test Firebase Connection")
                        }
                    }
                    
                    Button(action: {
                        clearAllLocalData()
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.red)
                            Text("Clear All Local Data")
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Continue", role: .destructive) {
                    alertAction?()
                }
            } message: {
                Text(alertMessage)
            }
            .alert("Firebase Connection Test", isPresented: $showTestAlert) {
                Button("OK") { }
            } message: {
                Text(testResult)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var localEntryCount: Int {
        let request = NSFetchRequest<MoodEntry>(entityName: "MoodEntry")
        request.predicate = NSPredicate(format: "isSoftDeleted == NO OR isSoftDeleted == nil")
        return (try? viewContext.count(for: request)) ?? 0
    }
    
    private var firebaseEntryCount: Int {
        return syncService.firebaseEntryCount
    }
    
    // MARK: - Helper Methods
    
    private func showAlert(title: String, message: String, action: @escaping () -> Void) {
        alertTitle = title
        alertMessage = message
        alertAction = action
        showingAlert = true
    }
    
    private func clearAllLocalData() {
        print("🔴 Clear All Data button pressed")
        
        // Show warning before clearing
        showAlert(
            title: "Clear All Data",
            message: "This will delete all your mood entries and restart the app. This action cannot be undone.",
            action: {
                print("🔴 User confirmed - starting clear operation")
                
                // Clear all data
                let request = NSFetchRequest<NSFetchRequestResult>(entityName: "MoodEntry")
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
                
                do {
                    try viewContext.execute(deleteRequest)
                    try viewContext.save()
                    print("✅ Cleared all local data")
                    
                    // Restart the app
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        print("🔴 Restarting app...")
                        exit(0)
                    }
                } catch {
                    print("❌ Failed to clear local data: \(error)")
                }
            }
        )
    }
}

struct DataInfoRow: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(title)
            
            Spacer()
            
            Text("\(count)")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    SettingsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(FirestoreSyncService(context: PersistenceController.preview.container.viewContext))
}
