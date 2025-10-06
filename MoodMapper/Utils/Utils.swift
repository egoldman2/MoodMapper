//
//  Utils.swift
//  MoodMapper
//
//  Created by Ethan on 30/9/2025.
//

import SwiftUI
import CoreData

struct Utils {
    static func emoji(for mood: Int16) -> String {
        let emojis = ["😞", "😕", "😐", "🙂", "😄"]
        let idx = max(0, min(4, mood - 1))
        return emojis[Int(idx)]
    }
    
    static func emojiColour(for mood: Int16) -> Color {
        let colours: [Color] = [.red, .yellow, .orange, .green, .blue]
        let idx = max(0, min(4, mood - 1))
        return colours[Int(idx)]
    }
    
    static func feeling(for mood: Int16) -> String {
        let feelings: [String] = ["Sad", "Unhappy", "Neutral", "Happy", "Euphoric"]
        let idx = max(0, min(4, mood - 1))
        return feelings[Int(idx)]
    }
    
    // MARK: - Error Handling Utilities
    
    /// Handles Core Data save errors gracefully
    static func handleCoreDataSaveError(_ error: Error, context: NSManagedObjectContext, operation: String = "save") {
        let nsError = error as NSError
        print("❌ Core Data \(operation) error: \(nsError), \(nsError.userInfo)")
        
        // Log specific error types for better debugging
        print("❌ Unknown Core Data error: \(nsError.localizedDescription)")
        
        // Rollback changes to maintain data integrity
        context.rollback()
    }
    
    /// Handles Core Data fetch errors gracefully
    static func handleCoreDataFetchError(_ error: Error, operation: String = "fetch") -> [Any] {
        let nsError = error as NSError
        print("❌ Core Data \(operation) error: \(nsError), \(nsError.userInfo)")
        
        // Return empty array for fetch operations
        return []
    }
    
    /// Handles network errors gracefully
    static func handleNetworkError(_ error: Error, operation: String = "network request") {
        print("❌ Network \(operation) error: \(error.localizedDescription)")
        
        let urlError = error as? URLError
        print("❌ Other network error: \(urlError?.localizedDescription ?? "Unknown error occured")")
    }
    
    /// Handles Firebase errors gracefully
    static func handleFirebaseError(_ error: Error, operation: String = "Firebase operation") {
        print("❌ Firebase \(operation) error: \(error.localizedDescription)")
        
        // Log specific Firebase error types
        let firebaseError = error as NSError
        print("❌ Firebase error code: \(firebaseError.code)")
    }
}
