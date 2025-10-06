//
//  AddEntry.swift
//  MoodMapper
//
//  Created by Ethan on 29/9/2025.
//

import SwiftUI
import CoreLocation

struct AddEntry: View {
    struct NewEntry: Identifiable, Hashable {
        let id = UUID()
        var mood: Int // 1 (low) ... 5 (high)
        var date: Date
        var note: String
        var latitude: Double? = nil
        var longitude: Double? = nil
        var locationName: String? = nil
    }

    @Environment(\.dismiss) private var dismiss

    // Callback invoked when the user taps Save
    var onSave: ((NewEntry) -> Void)? = nil

    @State private var mood: Int = 3
    @State private var date: Date = Date()
    @State private var note: String = ""
    @State private var today: Bool = true
    @State private var locationName: String = ""
    @FocusState private var noteFocused: Bool
    @EnvironmentObject private var locationService: LocationService
    @State private var includeLocation: Bool = true

    private let moodEmojis = ["😞", "😕", "😐", "🙂", "😄"]

    private var canSave: Bool {
        (1...5).contains(mood)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Mood") {
                    // Large, current mood preview
                    HStack {
                        Spacer(minLength: 0)
                        Text(moodEmojis[max(0, min(4, mood - 1))])
                            .font(.system(size: 48))
                        Spacer(minLength: 0)
                    }
                    Picker("Mood", selection: $mood) {
                        ForEach(1...5, id: \.self) { value in
                            Text(moodEmojis[value - 1])
                                .tag(value)
                        }
                    }
                    .pickerStyle(.segmented)
                    .controlSize(.large)
                }

                Section("When") {
                    Toggle(isOn: $today, label: {
                        Text("Today?")
                    })
                    if (!today) {
                        DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    }
                    
                }

                Section("Location") {
                    
                    TextField("Location Name", text: $locationName)
                    
                    Toggle("Attach current location", isOn: $includeLocation)
                        .onChange(of: includeLocation) { _, newValue in
                            if newValue {
                                locationService.requestLocation()
                            }
                        }
                    if includeLocation {
                        if let coord = locationService.coordinate {
                            Text(String(format: "Lat: %.4f, Lon: %.4f", coord.latitude, coord.longitude))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        } else {
                            HStack(spacing: 8) {
                                ProgressView()
                                Text("Locating…")
                            }
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("Location won’t be saved.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Notes") {
                    TextEditor(text: $note)
                        .frame(minHeight: 120)
                        .focused($noteFocused)
                        .submitLabel(.done)
                        .onSubmit { noteFocused = false }
                }
            }
            .navigationTitle("New Entry")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
            .onAppear {
                locationService.requestWhenInUseAuthorization()
                if includeLocation {
                    locationService.requestLocation()
                }
            }
        }
    }

    private func save() {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let coord = includeLocation ? locationService.coordinate : nil
        let entry = NewEntry(
            mood: mood,
            date: date,
            note: trimmed,
            latitude: coord?.latitude,
            longitude: coord?.longitude,
            locationName: locationName
        )
        onSave?(entry)
        dismiss()
    }
}

#Preview {
    AddEntry { new in
        // Preview sink for saved entries
        let lat = new.latitude.map { String(format: "%.4f", $0) } ?? "nil"
        let lon = new.longitude.map { String(format: "%.4f", $0) } ?? "nil"
        print("Saved entry: mood=\(new.mood), date=\(new.date), note=\(new.note), lat=\(lat), lon=\(lon)")
    }
    .environmentObject(LocationService())
}
