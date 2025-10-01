//
//  MoodEntryDetailView.swift
//  MoodMapper
//
//  Created by Ethan on 30/9/2025.
//

import SwiftUI
import MapKit
import CoreData

struct MoodEntryDetailView: View {
    var entry: MoodEntry
    
    var score: Int16 { entry.score}
    var date: Date { entry.timestamp ?? Date() }
    var locationName: String? { entry.placename }
    var notes: String? { entry.note }

    // Computed properties for emoji and tint
    var emoji: String {
        Utils.emoji(for: score)
    }
    var tint: Color {
        Utils.emojiColour(for: score)
    }
    
    var body: some View {
        VStack {
            GlassEffectContainer {
                VStack {
                    MoodMarkerView(emoji: emoji, tint: tint, size: 100, locationName: locationName, date: date, isInteractive: false)
                    
                    Text("Feeling \(Utils.feeling(for: score))")
                        .font(.headline)
                    
                    HStack {
                        GlassyPillView(systemImage: "calendar", text: date.formatted(.dateTime.year().month().day()), tint: tint)
                        GlassyPillView(systemImage: "clock", text: date.formatted(.dateTime.hour().minute()), tint: tint)
                    }
                    
                    if let locationName, !locationName.isEmpty {
                        GlassyPillView(systemImage: "mappin.circle.fill", text: locationName, tint: tint)
                    }
                    
                    if let notes, !notes.isEmpty {
                        VStack(alignment: .leading) {
                            Text("Notes")
                                .font(.headline)
                            Text(notes)
                                .font(.body)
                                .foregroundStyle(.primary)
                        }
                        .padding(16)
                        .glassEffect(.regular.tint(tint.opacity(0.18)), in: .rect(cornerRadius: 16))
                        
                    }
                    
                    
                    
                    
                }
                .padding(20)
                .glassEffect(.regular.tint(tint.opacity(0.25)).interactive(), in: .rect(cornerRadius: 24))
                .padding(20)
                
            }
        }
        
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let previewEntry = MoodEntry(context: context)
    previewEntry.score = 4
    previewEntry.timestamp = Date()
    previewEntry.placename = "Home"
    previewEntry.note = "Feeling great! Finally, some sunshine!"
    previewEntry.latitude = -33.8688
    previewEntry.longitude = 151.2093

    return MoodEntryDetailView(entry: previewEntry)
        .environment(\.managedObjectContext, context)
}
