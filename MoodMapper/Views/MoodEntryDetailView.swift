//
//  MoodEntryDetailView.swift
//  MoodMapper
//
//  Created by Ethan on 30/9/2025.
//

import SwiftUI

struct MoodEntryDetailView: View {
    let emoji: String = "💀"
    let score: Int16 = 3
    var tint: Color = .blue
    var date: Date = Date()
    var locationName: String? = "Default location"
    var notes: String? = "Default notes text"
    
    var body: some View {
        GlassEffectContainer {
            VStack {
                MoodMarkerView(emoji: emoji, tint: tint, size: 100, locationName: locationName, date: date)
                
                Text("Feeling \(Utils.feeling(for: score))")
                    .font(.headline)
                
                HStack {
                    GlassyPillView(systemImage: "calendar", text: date.formatted(.dateTime.year().month().day()), tint: tint)
                    GlassyPillView(systemImage: "clock", text: date.formatted(.dateTime.hour().minute()))
                }
                
                if let locationName, !locationName.isEmpty {
                    GlassyPillView(systemImage: "mappin.circle.fill", text: locationName)
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
            
        }
    }
}

#Preview {
    MoodEntryDetailView()
}
