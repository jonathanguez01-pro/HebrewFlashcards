//
//  APIClient.swift
//  HebrewFlashcards
//
//  Created by Jonathan Guez on 02/08/2026.
//
//  URLSession-backed vocab API client, HTTP validation, and offline URLError classification.
//

import Foundation

protocol HTTPClient: Sendable {
    func data(from url: URL) async throws -> (Data, URLResponse)
}

extension URLSession: HTTPClient {}

struct VocabAPIClient: Sendable {
    static let defaultEndpoint = URL(string: "https://hub.citizencafetlv.com/api/public/vocab")!

    private let client: any HTTPClient
    private let endpoint: URL
    private let decoder: JSONDecoder

    init(
        client: any HTTPClient = URLSession.shared,
        endpoint: URL = VocabAPIClient.defaultEndpoint,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.client = client
        self.endpoint = endpoint
        self.decoder = decoder
    }

    func fetchVocabulary() async throws -> [VocabLevel] {
        print("🌐 [API] Fetching vocabulary from \(endpoint.absoluteString)")

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await client.data(from: endpoint)
        } catch let urlError as URLError {
            print("❌ [API] Request failed (URLError \(urlError.code.rawValue)): \(urlError.localizedDescription)")
            throw urlError
        } catch {
            print("❌ [API] Request failed: \(error.localizedDescription)")
            throw VocabError.underlying(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            print("❌ [API] Unexpected non-HTTP response")
            throw VocabError.underlying("Unexpected non-HTTP response.")
        }

        print("📡 [API] HTTP \(http.statusCode) — \(data.count) bytes")

        guard (200...299).contains(http.statusCode) else {
            print("❌ [API] Non-success status \(http.statusCode)")
            throw VocabError.invalidHTTPStatus(http.statusCode)
        }

        do {
            let levels = try decoder.decode([VocabLevel].self, from: data)
            guard !levels.isEmpty else {
                print("❌ [API] Decoded empty vocabulary")
                throw VocabError.emptyVocabulary
            }
            print("✅ [API] Success — decoded \(levels.count) level packs")
            return levels
        } catch let error as VocabError {
            print("❌ [API] \(error.localizedDescription)")
            throw error
        } catch {
            print("❌ [API] Decoding failed: \(error.localizedDescription)")
            throw VocabError.decodingFailed(error.localizedDescription)
        }
    }
}

enum ConnectivityClassifier {
    /// URLError codes treated as "device offline / unreachable" for cache fallback.
    static let offlineCodes: Set<URLError.Code> = [
        .notConnectedToInternet,
        .networkConnectionLost,
        .timedOut,
        .cannotFindHost,
        .cannotConnectToHost,
        .dnsLookupFailed,
        .internationalRoamingOff,
        .callIsActive,
        .dataNotAllowed
    ]

    static func isConnectivityFailure(_ error: Error) -> Bool {
        guard let urlError = error as? URLError else { return false }
        return offlineCodes.contains(urlError.code)
    }
}
