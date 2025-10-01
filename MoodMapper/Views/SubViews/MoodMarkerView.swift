//
//  MoodMarkerView.swift
//  MoodMapper
//
//  Created by Ethan on 30/9/2025.
//

import SwiftUI

struct MoodMarkerView: View {
    let emoji: String
    var tint: Color = .blue
    var size: CGFloat = 60
    var locationName: String? = nil
    var date: Date? = nil
    var isInteractive: Bool = true
    var onMoreInfo: (() -> Void)? = nil
    
    @State private var isCalloutPresented: Bool = false

    var body: some View {
        ZStack {
            // The circular glass badge
            Circle()
                .fill(Color.clear)
                .frame(width: size, height: size)
                .overlay(
                    Text(emoji)
                        .font(.system(size: size * 0.58))
                )
                .contentShape(Circle())
                .glassEffect(.regular.tint(tint.opacity(0.3)).interactive(), in: .circle)
            
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        MoodMarkerView(emoji: "😄", tint: .blue, size: 48, locationName: "Home", date: .now) { }
        MoodMarkerView(emoji: "😐", tint: .yellow, size: 48, locationName: "Office", date: .now) { }
        MoodMarkerView(emoji: "😞", tint: .red, size: 48, locationName: "Gym", date: .now) { }
    }
    .padding()
}
