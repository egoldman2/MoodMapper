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
      Auth.auth().signInAnonymously { result, error in
          if let error = error {
              print("Anon auth failed:", error)
          } else {
              print("Anon auth UID:", result?.user.uid ?? "unknown")
          }
      }

      return true
  }
}

@main
struct MoodMapperApp: App {
    let persistenceController = PersistenceController.shared
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @StateObject private var locationService = LocationService()
    @StateObject private var syncService: FirestoreSyncService
    
    init() {
        let ctx = PersistenceController.shared.container.viewContext
        _syncService = StateObject(wrappedValue: FirestoreSyncService(context: ctx))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(locationService)
                .onAppear {
                    locationService.requestWhenInUseAuthorization()
                    syncService.start()
                }
        }
    }
}
