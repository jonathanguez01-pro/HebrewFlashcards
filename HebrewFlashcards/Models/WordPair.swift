//
//  WordPair.swift
//  HebrewFlashcards
//
//  Created by Jonathan Guez on 02/08/2026.
//
//  Codable Hebrew/English vocabulary pair model.
//

import Foundation

struct WordPair: Codable, Equatable, Identifiable, Sendable {
    var id: String { "\(hebrew)|\(english)" }
    let hebrew: String
    let english: String
}
