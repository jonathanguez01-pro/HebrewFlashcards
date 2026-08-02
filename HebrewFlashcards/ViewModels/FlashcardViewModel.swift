import Foundation
import Combine

@MainActor
final class FlashcardViewModel: ObservableObject {
    @Published private(set) var cards: [WordPair]
    @Published private(set) var index: Int = 0
    @Published private(set) var isShowingEnglish: Bool = false

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

    func flip() {
        isShowingEnglish.toggle()
    }

    func next() {
        guard !cards.isEmpty else { return }
        index = (index + 1) % cards.count
        isShowingEnglish = false
    }

    func shuffle() {
        guard cards.count > 1 else { return }
        var nextCards = cards
        for _ in 0..<5 {
            nextCards.shuffle()
            if nextCards != cards { break }
        }
        cards = nextCards
        index = 0
        isShowingEnglish = false
    }
}
