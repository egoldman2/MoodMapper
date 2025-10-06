//
//  QuoteBubbleView.swift
//  MoodMapper
//
//  Created by Ethan on 6/10/2025.
//

import SwiftUI

struct QuoteBubbleView: View {
    @State private var quoteText: String = ""
    @State private var quoteAuthor: String? = nil
    @State private var quoteLoadError: String? = nil
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            GlassEffectContainer {
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: "quote.bubble.fill")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.tint)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Inspirational quote")
                            .font(.headline)
                            .fontWeight(.semibold)
                            
                        if let error = quoteLoadError {
                            Text(error)
                                .font(.subheadline)
                                .foregroundStyle(.red)
                                .lineLimit(2)
                        } else {
                            Text(quoteText.isEmpty ? "Fetching a little inspiration…" : "\"\(quoteText)\"")
                                .font(.subheadline)
                                .italic()
                                .foregroundStyle(.secondary)
                                .lineLimit(!isExpanded ? 2 : 6)
                        }
                        if isExpanded, let author = quoteAuthor, quoteLoadError == nil, !author.isEmpty {
                            Text("— \(author)")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            
                            Button("Fetch another") {
                                Task {
                                    await loadQuote()
                                    
                                }
                                isExpanded = true
                            }
                        }
                        
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
            }
            .padding(16)
            .glassEffect()
            .padding()
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }
            .task {
                await loadQuote()
            }

            Spacer()
        }
    }
    
    @MainActor
    private func loadQuote() async {
        let quote = await ZenQuoteService().fetchRandom()
        self.quoteText = quote.text
        self.quoteAuthor = quote.author
        self.isExpanded = false
        self.quoteLoadError = nil
    }
}

#Preview {
    QuoteBubbleView()
}
