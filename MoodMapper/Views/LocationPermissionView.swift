//
//  LocationPermissionView.swift
//  MoodMapper
//
//  Created by Ethan on 6/10/2025.
//

import SwiftUI
import CoreLocation

struct LocationPermissionView: View {
    @EnvironmentObject private var locationService: LocationService
    @State private var showingSettings = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 30) {
                Spacer()
                
                // Location icon
                Image(systemName: "location.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                    .symbolEffect(.pulse, options: .repeating)
                
                // Title
                Text("Location Access Required")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                // Description
                VStack(spacing: 16) {
                    Text("MoodMapper needs access to your location to:")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Record where you log your moods")
                                .font(.body)
                        }
                        
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Show your mood history on a map")
                                .font(.body)
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Permission status and action
                VStack(spacing: 20) {
                    if locationService.authorizationStatus == .denied || locationService.authorizationStatus == .restricted {
                        // Permission denied - show settings button
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.orange)
                            
                            Text("Location access was denied")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("Please enable location access in Settings to continue using MoodMapper.")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            Button("Open Settings") {
                                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(settingsUrl)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                    } else {
                        // Request permission
                        VStack(spacing: 16) {
                            Button("Allow Location Access") {
                                locationService.requestWhenInUseAuthorization()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            
                            Text("MoodMapper requires location permissions to function correctly.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    LocationPermissionView()
        .environmentObject(LocationService())
}
