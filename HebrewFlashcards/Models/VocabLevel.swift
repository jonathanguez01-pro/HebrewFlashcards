//
//  VocabLevel.swift
//  HebrewFlashcards
//
//  Created by Jonathan Guez on 02/08/2026.
//
//  Codable level pack model and curriculum tier/level/type metadata.
//

import Foundation

struct VocabLevel: Codable, Equatable, Identifiable, Sendable {
    let tier: String
    let level: String
    let type: Int?
    let pairs: [WordPair]

    var id: String {
        if let type {
            return "\(tier)|\(level)|\(type)"
        }
        return "\(tier)|\(level)|nil"
    }

    var hasMultipleTypes: Bool {
        type != nil
    }

    var displayTitle: String {
        if let type {
            return "\(level) · Pack \(type)"
        }
        return level
    }
}

enum CurriculumTier {
    static let order = ["Foundation", "Flow", "Freedom"]

    static let levelsByTier: [String: [String]] = [
        "Foundation": ["Red", "Orange", "Pink", "Yellow"],
        "Flow": ["Light Blue", "Blue", "Lime", "Green"],
        "Freedom": ["Dark Green", "Turquoise", "Indigo", "Purple"]
    ]

    /// Freedom levels that ship multiple content packs.
    static let multiPackLevels: [String: Int] = [
        "Dark Green": 4,
        "Turquoise": 4,
        "Indigo": 6
    ]
}
