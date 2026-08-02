//
//  VocabRepository.swift
//  HebrewFlashcards
//
//  Created by Jonathan Guez on 02/08/2026.
//
//  Repository that loads vocab: remote → disk cache → bundled fallback.
//

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
        print("🚀 [Repo] Loading vocabulary…")
        do {
            let remote = try await api.fetchVocabulary()
            try cache.save(remote)
            print("✅ [Repo] Remote load OK — cached \(remote.count) packs to disk")
            return VocabLoadResult(levels: remote, source: .remote)
        } catch {
            if ConnectivityClassifier.isConnectivityFailure(error) {
                print("⚠️ [Repo] Connectivity failure — trying offline fallback")
                let fallback = try loadOfflineFallback()
                print("✅ [Repo] Offline fallback OK (\(fallback.source.rawValue)) — \(fallback.levels.count) packs")
                return fallback
            }
            print("❌ [Repo] Load failed (not treated as offline): \(error.localizedDescription)")
            throw mapThrown(error)
        }
    }

    private func loadOfflineFallback() throws -> VocabLoadResult {
        if cache.hasCache {
            print("📦 [Repo] Reading disk cache…")
            let cached = try cache.load()
            return VocabLoadResult(levels: cached, source: .diskCache)
        }
        print("📦 [Repo] No disk cache — loading bundled fallback…")
        let bundledLevels = try bundled.load()
        return VocabLoadResult(levels: bundledLevels, source: .bundledFallback)
    }

    private func mapThrown(_ error: Error) -> Error {
        if let vocabError = error as? VocabError { return vocabError }
        if let urlError = error as? URLError { return urlError }
        return VocabError.underlying(error.localizedDescription)
    }
}
