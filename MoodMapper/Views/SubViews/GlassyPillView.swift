//
//  GlassyPillView.swift
//  MoodMapper
//
//  Created by Ethan on 30/9/2025.
//

import SwiftUI

struct GlassyPillView: View {
    var systemImage: String = "house"
    var text: String = "Default text"
    var tint: Color? = .blue

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .imageScale(.medium)
            Text(text)
                .font(.subheadline)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .glassEffect(.regular.tint((tint ?? .accentColor).opacity(0.16)), in: .capsule)
        .overlay(
            Capsule().strokeBorder(.white.opacity(0.10), lineWidth: 1)
        )
    }

}

#Preview {
    GlassyPillView()
}
