import Foundation

protocol VocabCacheStoring: Sendable {
    func save(_ levels: [VocabLevel]) throws
    func load() throws -> [VocabLevel]
    var hasCache: Bool { get }
}

/// Persists the vocabulary JSON under Application Support so offline study
/// survives OS cache pressure and device restores.
struct VocabCacheStore: VocabCacheStoring {
    private let fileURL: URL
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        fileManager: FileManager = .default,
        fileName: String = "vocab_cache.json",
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) throws {
        self.fileManager = fileManager
        self.encoder = encoder
        self.decoder = decoder

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
    init(
        fileURL: URL,
        fileManager: FileManager = .default,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.fileURL = fileURL
        self.fileManager = fileManager
        self.encoder = encoder
        self.decoder = decoder
    }

    var hasCache: Bool {
        fileManager.fileExists(atPath: fileURL.path)
    }

    func save(_ levels: [VocabLevel]) throws {
        let data = try encoder.encode(levels)
        try data.write(to: fileURL, options: .atomic)
    }

    func load() throws -> [VocabLevel] {
        guard hasCache else { throw VocabError.cacheMissing }
        let data = try Data(contentsOf: fileURL)
        do {
            let levels = try decoder.decode([VocabLevel].self, from: data)
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
    private let bundle: Bundle
    private let resourceName: String
    private let decoder: JSONDecoder

    init(
        bundle: Bundle = .main,
        resourceName: String = "vocab_fallback",
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.bundle = bundle
        self.resourceName = resourceName
        self.decoder = decoder
    }

    func load() throws -> [VocabLevel] {
        guard let url = bundle.url(forResource: resourceName, withExtension: "json") else {
            throw VocabError.bundledFallbackMissing
        }
        let data = try Data(contentsOf: url)
        do {
            let levels = try decoder.decode([VocabLevel].self, from: data)
            guard !levels.isEmpty else { throw VocabError.emptyVocabulary }
            return levels
        } catch let error as VocabError {
            throw error
        } catch {
            throw VocabError.decodingFailed(error.localizedDescription)
        }
    }
}
