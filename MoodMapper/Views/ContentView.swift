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

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MoodEntry.id, ascending: true)],
        animation: .default)
    private var items: FetchedResults<MoodEntry>
    @State private var showHomeOverlay = false

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
                        withAnimation(.snappy) { showHomeOverlay.toggle() }
                    } label: {
                        Image(systemName: showHomeOverlay ? "house.fill" : "house")
                        .imageScale(.large)
                    }
                }
            }
        }
    }

    

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
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

