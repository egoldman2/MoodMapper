//
//  MoodEntryMapView.swift
//  MoodMapper
//
//  Created by Ethan on 5/10/2025.
//

import SwiftUI
import MapKit
import CoreData

struct MoodEntryMapView: View {
    var entry: MoodEntry
    
    @State private var position: MapCameraPosition
    @State private var showDetail = false
    
    init(entry: MoodEntry) {
        self.entry = entry
        
        // Set up the map region based on the entry's location
        if entry.latitude != 0, entry.longitude != 0 {
            let region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: entry.latitude + 0.004, longitude: entry.longitude),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
            self._position = State(initialValue: .region(region))
        } else {
            // Default to Sydney if no location
            let region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: -33.8688, longitude: 151.2093),
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
            self._position = State(initialValue: .region(region))
        }
    }
    
    var body: some View {
        ZStack {
            Map(position: $position) {
                Annotation("", coordinate: CLLocationCoordinate2D(
                    latitude: entry.latitude,
                    longitude: entry.longitude
                )) {
                    MoodMarkerView(emoji: Utils.emoji(for: entry.score), tint: Utils.emojiColour(for: entry.score), isInteractive: false)
                }
            }
            .ignoresSafeArea()
            .disabled(true)
            
            // Detail view overlay
            VStack {
                MoodEntryDetailView(entry: entry)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showDetail)
                
                Spacer()
            }
        }
    }
        
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let previewEntry = MoodEntry(context: context)
    previewEntry.score = 4
    previewEntry.timestamp = Date()
    previewEntry.placename = "Sydney Opera House"
    previewEntry.note = "Beautiful day at the opera house!"
    previewEntry.latitude = -33.8568
    previewEntry.longitude = 151.2153
    
    return MoodEntryMapView(entry: previewEntry)
        .environment(\.managedObjectContext, context)
}
