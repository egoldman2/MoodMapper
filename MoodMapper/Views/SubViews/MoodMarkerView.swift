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
        .onTapGesture {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                isCalloutPresented.toggle()
            }
        }
        .popover(isPresented: $isCalloutPresented, attachmentAnchor: .rect(.bounds), arrowEdge: .bottom) {
            VStack(alignment: .center, spacing: 8) {
                if let locationName {
                    Text(locationName)
                        .font(.headline)
                }
                if let date {
                    Text(date, format: .dateTime.year().month().day().hour().minute())
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                if onMoreInfo != nil {
                    Button {
                        isCalloutPresented = false
                        onMoreInfo?()
                    } label: {
                        Label("View more", systemImage: "chevron.right.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
            .padding(12)
            .presentationCompactAdaptation(.popover)
        }
        .shadow(radius: 2)
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
