import Foundation

protocol VocabRepositoryProtocol: Sendable {
    /// Full load including which source supplied the data (remote / cache / bundle).
    func load() async throws -> VocabLoadResult
}

enum VocabLoadSource: String, Equatable, Sendable {
    case remote
    case diskCache
    case bundledFallback
}

struct VocabLoadResult: Equatable, Sendable {
    let levels: [VocabLevel]
    let source: VocabLoadSource
}

/// Loads vocabulary on every launch using:
/// 1) remote fetch → cache & return
/// 2) connectivity failure → disk cache
/// 3) missing disk cache → bundled fallback
/// HTTP / decoding errors are surfaced (no silent cache fallback).
final class VocabRepository: VocabRepositoryProtocol, @unchecked Sendable {
    private let api: VocabAPIClient
    private let cache: any VocabCacheStoring
    private let bundled: any BundledVocabLoading

    init(
        api: VocabAPIClient = VocabAPIClient(),
        cache: any VocabCacheStoring,
        bundled: any BundledVocabLoading = BundledVocabLoader()
    ) {
        self.api = api
        self.cache = cache
        self.bundled = bundled
    }

    func load() async throws -> VocabLoadResult {
        do {
            let remote = try await api.fetchVocabulary()
            try cache.save(remote)
            return VocabLoadResult(levels: remote, source: .remote)
        } catch {
            if ConnectivityClassifier.isConnectivityFailure(error) {
                return try loadOfflineFallback()
            }
            throw mapThrown(error)
        }
    }

    private func loadOfflineFallback() throws -> VocabLoadResult {
        if cache.hasCache {
            let cached = try cache.load()
            return VocabLoadResult(levels: cached, source: .diskCache)
        }
        let bundledLevels = try bundled.load()
        return VocabLoadResult(levels: bundledLevels, source: .bundledFallback)
    }

    private func mapThrown(_ error: Error) -> Error {
        if let vocabError = error as? VocabError { return vocabError }
        if let urlError = error as? URLError { return urlError }
        return VocabError.underlying(error.localizedDescription)
    }
}
