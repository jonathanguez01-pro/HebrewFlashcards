//
//  FlashcardViewModel.swift
//  HebrewFlashcards
//
//  Created by Jonathan Guez on 02/08/2026.
//
//  Flashcard session state: current card, flip, next, shuffle, and progress.
//

import Foundation
import Combine

@MainActor
final class FlashcardViewModel: ObservableObject {
    @Published private(set) var cards: [WordPair]
    @Published private(set) var index: Int = 0
    @Published private(set) var isShowingEnglish: Bool = false
    @Published private(set) var didCompletePack: Bool = false

    init(level: VocabLevel) {
        self.cards = level.pairs
    }

    /// Test / preview helper.
    init(cards: [WordPair], index: Int = 0, isShowingEnglish: Bool = false) {
        self.cards = cards
        self.index = min(max(0, index), max(cards.count - 1, 0))
        self.isShowingEnglish = isShowingEnglish
    }

    var currentCard: WordPair? {
        guard cards.indices.contains(index) else { return nil }
        return cards[index]
    }

    var progressText: String {
        guard !cards.isEmpty else { return "0 / 0" }
        return "\(index + 1) / \(cards.count)"
    }

    var hasCards: Bool { !cards.isEmpty }

    var isOnLastCard: Bool {
        !cards.isEmpty && index == cards.count - 1
    }

    func flip() {
        isShowingEnglish.toggle()
    }

    /// Advances to the next card, or marks the pack complete when leaving the last card.
    func next() {
        guard !cards.isEmpty else { return }
        isShowingEnglish = false

        if isOnLastCard {
            didCompletePack = true
            return
        }

        index += 1
    }

    func shuffle() {
        guard !cards.isEmpty else { return }
        var nextCards = cards
        if cards.count > 1 {
            for _ in 0..<5 {
                nextCards.shuffle()
                if nextCards != cards { break }
            }
        }
        cards = nextCards
        restartDeck()
    }

    func studyAgain() {
        restartDeck()
    }

    private func restartDeck() {
        index = 0
        isShowingEnglish = false
        didCompletePack = false
    }
}
