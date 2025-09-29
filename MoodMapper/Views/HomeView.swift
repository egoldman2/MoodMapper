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
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MoodEntry.timestamp, ascending: false)],
        animation: .default
    )
    private var items: FetchedResults<MoodEntry>
    @State private var showingAdd = false

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(items) { item in
                            EntryRow(item: item)
                        }
                        .onDelete(perform: delete)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Mood Mapper")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton().disabled(items.isEmpty)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddEntry { new in
                    let item = MoodEntry(context: viewContext)
                    item.id = UUID()
                    item.score = Int16(new.mood)
                    item.timestamp = new.date
                    item.note = new.note
                    // Record location only if attributes exist in the model
                    let attributes = item.entity.attributesByName
                    if attributes.keys.contains("latitude") {
                        item.setValue(new.latitude, forKey: "latitude")
                    }
                    if attributes.keys.contains("longitude") {
                        item.setValue(new.longitude, forKey: "longitude")
                    }
                    try? viewContext.save()
                }
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
            Text(emoji(for: Int(item.score)))
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
                    Text("No notes")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .italic()
                }
            }
        }
        .padding(.vertical, 6)
    }

    private func emoji(for mood: Int) -> String {
        let emojis = ["😞", "😕", "😐", "🙂", "😄"]
        let idx = max(0, min(4, mood - 1))
        return emojis[idx]
    }
}

#Preview {
    HomeView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(LocationService())
}
