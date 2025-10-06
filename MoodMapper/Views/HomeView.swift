//
//  HomeView.swift
//  MoodMapper
//
//  Created by Ethan on 29/9/2025.
//

import SwiftUI
import CoreData

struct HomeView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var syncService: FirestoreSyncService
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MoodEntry.timestamp, ascending: false)],
        animation: .default
    )
    private var items: FetchedResults<MoodEntry>

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(items, id: \.objectID) { item in
                            NavigationLink {
                                MoodEntryMapView(entry: item)
                            } label : {
                                EntryRow(item: item)
                            }
                        }
                        .onDelete(perform: delete)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Mood Mapper")
            .onChange(of: syncService.dataCleared) { _, _ in
                // Trigger view refresh when data is cleared
                viewContext.refreshAllObjects()
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "face.smiling")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No entries yet")
                .font(.headline)
            Text("Tap the plus to add your first mood.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .multilineTextAlignment(.center)
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}

private struct EntryRow: View {
    let item: MoodEntry

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(Utils.emoji(for: item.score))
                .font(.largeTitle)
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text((item.timestamp ?? Date()).formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                if let note = item.note, !note.isEmpty {
                    Text(note)
                        .font(.body)
                        .lineLimit(2)
                } else {
                    Text("Feeling " + Utils.feeling(for: item.score))
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .italic()
                }
            }
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    HomeView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(LocationService())
}
