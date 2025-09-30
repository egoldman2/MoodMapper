//
//  Utils.swift
//  MoodMapper
//
//  Created by Ethan on 30/9/2025.
//

import SwiftUI

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

}
