//
//  MoodMapperApp.swift
//  MoodMapper
//
//  Created by Ethan on 29/9/2025.
//

import SwiftUI
import CoreData
import FirebaseCore
import FirebaseAuth
import CoreLocation

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
      FirebaseApp.configure()
      FirebaseConfiguration.shared.setLoggerLevel(.debug)
      // No longer signing in anonymously - user must authenticate with email/password

      return true
  }
}

@main
struct MoodMapperApp: App {
    let persistenceController = PersistenceController.shared
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @StateObject private var locationService = LocationService()
    @StateObject private var authService = AuthenticationService()
    @StateObject private var syncService: FirestoreSyncService
    
    init() {
        let ctx = PersistenceController.shared.container.viewContext
        _syncService = StateObject(wrappedValue: FirestoreSyncService(context: ctx))
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isLoading {
                    LoadingView()
                } else if authService.isAuthenticated && !authService.isAnonymous {
                    // Check location permission before showing main content
                    if locationService.authorizationStatus == .authorizedWhenInUse || 
                       locationService.authorizationStatus == .authorizedAlways {
                        ContentView()
                            .environment(\.managedObjectContext, persistenceController.container.viewContext)
                            .environmentObject(locationService)
                            .environmentObject(authService)
                            .environmentObject(syncService)
                            .onAppear {
                                syncService.start()
                            }
                    } else {
                        LocationPermissionView()
                            .environmentObject(locationService)
                    }
                } else {
                    AuthenticationView {
                        // Authentication successful - sync service will be enabled
                        syncService.start()
                    }
                    .environmentObject(authService)
                }
            }
        }
    }
}
