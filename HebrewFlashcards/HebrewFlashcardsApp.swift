import SwiftUI

@main
struct HebrewFlashcardsApp: App {
    private let repository: VocabRepository

    init() {
        let cache: VocabCacheStore
        do {
            cache = try VocabCacheStore()
        } catch {
            // Fallback to temporary directory if Application Support is unavailable.
            let temp = FileManager.default.temporaryDirectory
                .appendingPathComponent("HebrewFlashcards", isDirectory: true)
            try? FileManager.default.createDirectory(at: temp, withIntermediateDirectories: true)
            cache = VocabCacheStore(fileURL: temp.appendingPathComponent("vocab_cache.json"))
        }
        repository = VocabRepository(cache: cache)
    }

    var body: some Scene {
        WindowGroup {
            ContentView(repository: repository)
                .tint(Brand.accent)
        }
    }
}
