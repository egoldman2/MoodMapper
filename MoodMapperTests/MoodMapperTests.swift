//
//  MoodMapperTests.swift
//  MoodMapperTests
//
//  Created by Ethan on 29/9/2025.
//

import Testing
import CoreData
import XCTest
@testable import MoodMapper

struct MoodMapperTests {
    
    // MARK: - Core Data Tests
    
    @Test func testMoodEntryCreation() async throws {
        let context = await PersistenceController.preview.container.viewContext
        
        try await context.perform {
            // Clear any existing entries first
            let fetchRequest: NSFetchRequest<MoodEntry> = MoodEntry.fetchRequest()
            let existingEntries = try context.fetch(fetchRequest)
            for entry in existingEntries {
                context.delete(entry)
            }
            if context.hasChanges {
                try context.save()
            }
            
            let entry = MoodEntry(context: context)
            entry.id = UUID()
            entry.score = 3
            entry.timestamp = Date()
            entry.note = "Test mood entry"
            entry.latitude = 37.7749
            entry.longitude = -122.4194
            entry.placename = "San Francisco"
            
            try context.save()
            #expect(entry.score == 3)
            #expect(entry.note == "Test mood entry")
            #expect(entry.latitude == 37.7749)
            #expect(entry.longitude == -122.4194)
        }
    }
    
    @Test func testMoodEntryDeletion() async throws {
        let context = await PersistenceController.preview.container.viewContext
        
        try await context.perform {
            // Clear any existing entries first
            let fetchRequest: NSFetchRequest<MoodEntry> = MoodEntry.fetchRequest()
            let existingEntries = try context.fetch(fetchRequest)
            for entry in existingEntries {
                context.delete(entry)
            }
            if context.hasChanges {
                try context.save()
            }
            
            let entry = MoodEntry(context: context)
            entry.id = UUID()
            entry.score = 4
            entry.timestamp = Date()
            
            try context.save()
            
            let entries = try context.fetch(fetchRequest)
            #expect(entries.count == 1)
            
            context.delete(entry)
            try context.save()
            
            let entriesAfterDelete = try context.fetch(fetchRequest)
            #expect(entriesAfterDelete.count == 0)
        }
    }
    
    // MARK: - Utility Function Tests
    
    @Test func testEmojiMapping() {
        #expect(Utils.emoji(for: 1) == "😞")
        #expect(Utils.emoji(for: 2) == "😕")
        #expect(Utils.emoji(for: 3) == "😐")
        #expect(Utils.emoji(for: 4) == "🙂")
        #expect(Utils.emoji(for: 5) == "😄")
        
        // Test edge cases
        #expect(Utils.emoji(for: 0) == "😞") // Should clamp to 1
        #expect(Utils.emoji(for: 6) == "😄") // Should clamp to 5
    }
    
    @Test func testFeelingMapping() {
        #expect(Utils.feeling(for: 1) == "Sad")
        #expect(Utils.feeling(for: 2) == "Unhappy")
        #expect(Utils.feeling(for: 3) == "Neutral")
        #expect(Utils.feeling(for: 4) == "Happy")
        #expect(Utils.feeling(for: 5) == "Euphoric")
    }
    
    @Test func testEmojiColorMapping() {
        let color1 = Utils.emojiColour(for: 1)
        let color2 = Utils.emojiColour(for: 2)
        let color3 = Utils.emojiColour(for: 3)
        let color4 = Utils.emojiColour(for: 4)
        let color5 = Utils.emojiColour(for: 5)
        
        // Test that different mood scores return different colors
        #expect(color1 != color2)
        #expect(color2 != color3)
        #expect(color3 != color4)
        #expect(color4 != color5)
    }
    
    // MARK: - Error Handling Tests
    
    @MainActor @Test func testCoreDataSaveErrorHandling() {
        let context = PersistenceController.preview.container.viewContext
        let entry = MoodEntry(context: context)
        entry.id = UUID()
        entry.score = 3
        entry.timestamp = Date()
        
        // This should not crash the app
        Utils.handleCoreDataSaveError(NSError(domain: "TestError", code: 1, userInfo: nil), context: context, operation: "test save")
    }
    
    @Test func testCoreDataFetchErrorHandling() {
        let result = Utils.handleCoreDataFetchError(NSError(domain: "TestError", code: 1, userInfo: nil), operation: "test fetch")
        #expect(result.isEmpty)
    }
    
    @Test func testNetworkErrorHandling() {
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil)
        // This should not crash the app
        Utils.handleNetworkError(error, operation: "test network")
    }
    
    @Test func testFirebaseErrorHandling() {
        let error = NSError(domain: "FirebaseError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test Firebase error"])
        // This should not crash the app
        Utils.handleFirebaseError(error, operation: "test Firebase")
    }
    
    // MARK: - Data Validation Tests
    
    @MainActor @Test func testMoodScoreValidation() {
        // Test valid mood scores
        for score in 1...5 {
            let entry = MoodEntry(context: PersistenceController.preview.container.viewContext)
            entry.score = Int16(score)
            #expect(entry.score >= 1 && entry.score <= 5)
        }
    }
    
    @MainActor @Test func testLocationDataValidation() {
        let entry = MoodEntry(context: PersistenceController.preview.container.viewContext)
        entry.latitude = 37.7749
        entry.longitude = -122.4194
        
        #expect(entry.latitude >= -90 && entry.latitude <= 90)
        #expect(entry.longitude >= -180 && entry.longitude <= 180)
    }
}


// MARK: - Performance Tests
final class MoodMapperPerformanceTests: XCTestCase {
    @MainActor
    func testMoodEntryCreationPerformance() {
        measure {
            let context = PersistenceController.preview.container.viewContext
            context.performAndWait {
                do {
                    // Clear existing entries first
                    let fetchRequest: NSFetchRequest<MoodEntry> = MoodEntry.fetchRequest()
                    let existingEntries = try context.fetch(fetchRequest)
                    for entry in existingEntries {
                        context.delete(entry)
                    }
                    if context.hasChanges {
                        try context.save()
                    }
                    
                    for i in 0..<100 {
                        let entry = MoodEntry(context: context)
                        entry.id = UUID()
                        entry.score = Int16((i % 5) + 1)
                        entry.timestamp = Date()
                        entry.note = "Performance test entry \(i)"
                    }
                    try context.save()
                } catch {
                    context.rollback()
                }
            }
        }
    }

    func testEmojiMappingPerformance() {
        measure {
            for _ in 0..<1000 {
                _ = Utils.emoji(for: Int16.random(in: 1...5))
            }
        }
    }
}

