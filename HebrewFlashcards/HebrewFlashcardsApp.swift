//
//  HebrewFlashcardsApp.swift
//  HebrewFlashcards
//
//  Created by Jonathan Guez on 02/08/2026.
//
//  App entry point. Wires cache, API client (with DEBUG mock), and root ContentView.
//

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

        #if DEBUG
        let api = VocabAPIClient(client: MockFailingHTTPClient(mode: DebugAPIMock.mode))
        print("🧪 [Debug] API mock mode = \(DebugAPIMock.mode)")
        repository = VocabRepository(api: api, cache: cache)
        #else
        repository = VocabRepository(cache: cache)
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView(repository: repository)
                .tint(Brand.accent)
        }
    }
}
