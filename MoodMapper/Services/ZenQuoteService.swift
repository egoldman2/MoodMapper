//
//  ZenQuoteService.swift
//  MoodMapper
//
//  Created by Ethan on 6/10/2025.
//

import Foundation

struct Quote: Identifiable, Codable {
    let id: String
    let text: String
    let author: String?
}

// Example: using Quotable API
enum QuoteAPIError: Error {
    case invalidURL
    case serverError(Error)
    case badResponse
    case decodingError(Error)
}

class ZenQuoteService {
    
    // Default quote to display when API fails
    private let defaultQuote = Quote(
        id: "default",
        text: "Something went wrong, but that's okay. Every moment is a chance to start fresh.",
        author: "MoodMapper"
    )
    
    func fetchRandom() async -> Quote {
        do {
            guard let url = URL(string: "https://zenquotes.io/api/random") else {
                return defaultQuote
            }
            let (data, resp) = try await URLSession.shared.data(from: url)
            guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                return defaultQuote
            }
            struct ZQ: Codable {
                let q: String
                let a: String
            }
            let arr = try JSONDecoder().decode([ZQ].self, from: data)
            guard let first = arr.first else {
                return defaultQuote
            }
            return Quote(id: UUID().uuidString, text: first.q, author: first.a)
        } catch {
            // Return default quote on any error
            return defaultQuote
        }
    }
}
