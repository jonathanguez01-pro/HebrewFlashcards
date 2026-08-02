import Foundation
import Combine

enum HomeLoadState: Equatable {
    case idle
    case loading
    case loaded(source: VocabLoadSource)
    case failed(message: String)
}

@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var loadState: HomeLoadState = .idle
    @Published private(set) var allLevels: [VocabLevel] = []

    @Published var selectedTier: String?
    @Published var selectedLevelName: String?
    @Published var selectedType: Int?

    private let repository: any VocabRepositoryProtocol

    init(repository: any VocabRepositoryProtocol) {
        self.repository = repository
    }

    var availableTiers: [String] {
        let present = Set(allLevels.map(\.tier))
        return CurriculumTier.order.filter { present.contains($0) }
    }

    var levelsForSelectedTier: [String] {
        guard let selectedTier else { return [] }
        let names = Set(allLevels.filter { $0.tier == selectedTier }.map(\.level))
        let preferred = CurriculumTier.levelsByTier[selectedTier] ?? []
        let ordered = preferred.filter { names.contains($0) }
        let extras = names.subtracting(ordered).sorted()
        return ordered + extras
    }

    var needsTypePicker: Bool {
        guard let selectedLevelName else { return false }
        return CurriculumTier.multiPackLevels[selectedLevelName] != nil
            || allLevels.contains { $0.level == selectedLevelName && $0.type != nil }
    }

    var availableTypes: [Int] {
        guard let selectedTier, let selectedLevelName else { return [] }
        return allLevels
            .filter { $0.tier == selectedTier && $0.level == selectedLevelName }
            .compactMap(\.type)
            .sorted()
    }

    var selectedVocabLevel: VocabLevel? {
        guard let selectedTier, let selectedLevelName else { return nil }
        if needsTypePicker {
            guard let selectedType else { return nil }
            return allLevels.first {
                $0.tier == selectedTier && $0.level == selectedLevelName && $0.type == selectedType
            }
        }
        return allLevels.first {
            $0.tier == selectedTier && $0.level == selectedLevelName && $0.type == nil
        } ?? allLevels.first {
            $0.tier == selectedTier && $0.level == selectedLevelName
        }
    }

    var canStartStudying: Bool {
        selectedVocabLevel != nil
    }

    func load() async {
        loadState = .loading
        do {
            let result = try await repository.load()
            allLevels = result.levels
            loadState = .loaded(source: result.source)
            applyDefaultSelectionIfNeeded()
        } catch {
            let message = (error as? LocalizedError)?.errorDescription
                ?? error.localizedDescription
            loadState = .failed(message: message)
        }
    }

    func selectTier(_ tier: String) {
        selectedTier = tier
        selectedLevelName = levelsForSelectedTier.first
        selectedType = nil
        syncTypeSelection()
    }

    func selectLevel(_ level: String) {
        selectedLevelName = level
        selectedType = nil
        syncTypeSelection()
    }

    func selectType(_ type: Int) {
        selectedType = type
    }

    private func applyDefaultSelectionIfNeeded() {
        if selectedTier == nil {
            selectedTier = availableTiers.first
        }
        if selectedLevelName == nil || !levelsForSelectedTier.contains(where: { $0 == selectedLevelName }) {
            selectedLevelName = levelsForSelectedTier.first
        }
        syncTypeSelection()
    }

    private func syncTypeSelection() {
        guard needsTypePicker else {
            selectedType = nil
            return
        }
        if let selectedType, availableTypes.contains(selectedType) {
            return
        }
        selectedType = availableTypes.first
    }
}
