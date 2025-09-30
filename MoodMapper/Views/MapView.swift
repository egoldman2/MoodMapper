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

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MoodEntry.timestamp, ascending: false)],
        animation: .default
    )
    private var entries: FetchedResults<MoodEntry>

    @State private var position: MapCameraPosition = .automatic

    var body: some View {
        VStack {
            Map(position: $position) {
                UserAnnotation()
                ForEach(entries) { entry in
                    if let coord = coordinate(for: entry) {
                        Annotation("", coordinate: coord) {
                            MoodMarkerView(emoji: Utils.emoji(for: entry.score), tint: Utils.emojiColour(for: entry.score))
                        }
                    }
                }
            }
            .task { setInitialCamera() }
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
}
