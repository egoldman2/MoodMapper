//
//  MapView.swift
//  MoodMapper
//
//  Created by Ethan on 29/9/2025.
//

import SwiftUI
import MapKit
import CoreData
import CoreLocation

struct MapView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var locationService: LocationService
    @EnvironmentObject private var syncService: FirestoreSyncService

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MoodEntry.timestamp, ascending: false)],
        animation: .default
    )
    private var entries: FetchedResults<MoodEntry>

    @State private var position: MapCameraPosition = .automatic
    @State private var selectedEntry: MoodEntry?

    var body: some View {
        ZStack {
            
            Map(position: $position) {
                UserAnnotation()
                ForEach(entries, id: \.objectID) { entry in
                    if let coord = coordinate(for: entry) {
                        Annotation("", coordinate: coord) {
                            Button {
                                selectedEntry = entry
                            } label: {
                                MoodMarkerView(
                                    emoji: Utils.emoji(for: entry.score),
                                    tint:  Utils.emojiColour(for: entry.score),
                                    locationName: entry.placename ?? "Unknown",
                                    date: entry.timestamp
                                )
                            }
                        }
                    }
                }
            }
            .task { setInitialCamera() }
            
            VStack {
                QuoteBubbleView()
                    .padding(.top, 40)
            }
            
            
            if let entry = selectedEntry {
                VStack {
                    MoodEntryDetailView(entry: entry)
                        .shadow(radius: 8)
                    
                    Button {
                        withAnimation(.snappy) { selectedEntry = nil }
                    } label: {
                        Label("Close", systemImage: "xmark.circle.fill")
                            .font(.headline)
                    }
                    .buttonStyle(.glass)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)


                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.snappy, value: selectedEntry)
        .onChange(of: entries.count) { _, newCount in
            // Clear selected entry if entries become empty
            if newCount == 0 {
                selectedEntry = nil
            }
        }
    }

    private func setInitialCamera() {
        if let user = locationService.coordinate {
            position = .region(MKCoordinateRegion(center: user,
                                                  span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)))
        } else if let first = entries.compactMap({ coordinate(for: $0) }).first {
            position = .region(MKCoordinateRegion(center: first,
                                                  span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)))
        }
    }

    private func coordinate(for entry: MoodEntry) -> CLLocationCoordinate2D? {
        let attributes = entry.entity.attributesByName
        guard attributes.keys.contains("latitude"),
              attributes.keys.contains("longitude"),
              let lat = entry.value(forKey: "latitude") as? Double,
              let lon = entry.value(forKey: "longitude") as? Double else {
            return nil
        }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}

#Preview {
    MapView()
        .environmentObject(LocationService())
        .environmentObject(FirestoreSyncService(context: PersistenceController.preview.container.viewContext))
}
