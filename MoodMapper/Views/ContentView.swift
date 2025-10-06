//
//  ContentView.swift
//  MoodMapper
//
//  Created by Ethan on 29/9/2025.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var syncService: FirestoreSyncService

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MoodEntry.id, ascending: true)],
        animation: .default)
    private var items: FetchedResults<MoodEntry>
    @State private var showHomeOverlay = false
    @State private var showSettings = false
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            ZStack {
                MapView()
                    .ignoresSafeArea()

                if showHomeOverlay {
                    HomeView()
                        .scrollContentBackground(.hidden)
                        .background(.ultraThinMaterial)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(1)
                }
            }
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        withAnimation(.snappy) { showSettings.toggle() }
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .imageScale(.large)
                    }
                }
                
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        withAnimation(.snappy) { showHomeOverlay.toggle() }
                    } label: {
                        Image(systemName: showHomeOverlay ? "house.fill" : "house")
                        .imageScale(.large)
                    }
                }
                
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        withAnimation(.snappy) { showAdd.toggle() }
                    } label: {
                        Image(systemName: "plus")
                            .imageScale(.large)
                    }
                }
                
                
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showAdd) {
                AddEntry { new in
                    let item = MoodEntry(context: viewContext)
                    item.id = UUID()
                    item.score = Int16(new.mood)
                    item.timestamp = new.date
                    item.note = new.note
                    item.placename = new.locationName
                    // Record location only if attributes exist in the model
                    let attributes = item.entity.attributesByName
                    if attributes.keys.contains("latitude") {
                        item.setValue(new.latitude, forKey: "latitude")
                    }
                    if attributes.keys.contains("longitude") {
                        item.setValue(new.longitude, forKey: "longitude")
                    }
                    if attributes.keys.contains("placename") {
                        item.setValue(new.locationName, forKey: "placename")
                    }
                    try? viewContext.save()
                }
            }
            .onChange(of: syncService.dataCleared) { _, _ in
                // Trigger view refresh when data is cleared
                viewContext.refreshAllObjects()
            }
        }
    }

    

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                print("Failed to save context: \(error)")
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(LocationService())
}

