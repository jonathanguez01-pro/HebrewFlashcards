//
//  VocabCacheStore.swift
//  HebrewFlashcards
//
//  Created by Jonathan Guez on 02/08/2026.
//
//  FileManager JSON cache in Application Support plus bundled fallback loader.
//

import Foundation

protocol VocabCacheStoring: Sendable {
    func save(_ levels: [VocabLevel]) throws
    func load() throws -> [VocabLevel]
    var hasCache: Bool { get }
}

/// Persists the vocabulary JSON under Application Support so offline study
/// survives OS cache pressure and device restores.
///
/// `FileManager` / `JSONEncoder` / `JSONDecoder` are not `Sendable`, so this
/// type keeps only a `URL` and creates those helpers per call (Swift 6–safe).
struct VocabCacheStore: VocabCacheStoring {
    private let fileURL: URL

    init(
        fileManager: FileManager = .default,
        fileName: String = "vocab_cache.json"
    ) throws {
        let support = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = support.appendingPathComponent("HebrewFlashcards", isDirectory: true)
        if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        self.fileURL = directory.appendingPathComponent(fileName)
    }

    /// Test-friendly initializer with an explicit file URL.
    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    var hasCache: Bool {
        FileManager.default.fileExists(atPath: fileURL.path)
    }

    func save(_ levels: [VocabLevel]) throws {
        let data = try JSONEncoder().encode(levels)
        try data.write(to: fileURL, options: .atomic)
    }

    func load() throws -> [VocabLevel] {
        guard hasCache else { throw VocabError.cacheMissing }
        let data = try Data(contentsOf: fileURL)
        do {
            let levels = try JSONDecoder().decode([VocabLevel].self, from: data)
            guard !levels.isEmpty else { throw VocabError.emptyVocabulary }
            return levels
        } catch let error as VocabError {
            throw error
        } catch {
            throw VocabError.decodingFailed(error.localizedDescription)
        }
    }
}

protocol BundledVocabLoading: Sendable {
    func load() throws -> [VocabLevel]
}

struct BundledVocabLoader: BundledVocabLoading {
    private let resourceName: String

    init(resourceName: String = "vocab_fallback") {
        self.resourceName = resourceName
    }

    func load() throws -> [VocabLevel] {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "json") else {
            throw VocabError.bundledFallbackMissing
        }
        let data = try Data(contentsOf: url)
        do {
            let levels = try JSONDecoder().decode([VocabLevel].self, from: data)
            guard !levels.isEmpty else { throw VocabError.emptyVocabulary }
            return levels
        } catch let error as VocabError {
            throw error
        } catch {
            throw VocabError.decodingFailed(error.localizedDescription)
        }
    }
}
