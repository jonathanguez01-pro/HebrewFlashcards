//
//  VocabError.swift
//  HebrewFlashcards
//
//  Created by Jonathan Guez on 02/08/2026.
//
//  Domain errors for networking, decoding, cache, and bundled fallback failures.
//

import Foundation

enum VocabError: Error, LocalizedError, Equatable {
    case invalidURL
    case invalidHTTPStatus(Int)
    case decodingFailed(String)
    case emptyVocabulary
    case cacheMissing
    case bundledFallbackMissing
    case underlying(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The vocabulary URL is invalid."
        case .invalidHTTPStatus(let code):
            return "The server returned an unexpected status code (\(code))."
        case .decodingFailed(let detail):
            return "Could not decode vocabulary data. \(detail)"
        case .emptyVocabulary:
            return "Vocabulary data was empty."
        case .cacheMissing:
            return "No cached vocabulary is available."
        case .bundledFallbackMissing:
            return "Bundled fallback vocabulary is missing."
        case .underlying(let message):
            return message
        }
    }
}
