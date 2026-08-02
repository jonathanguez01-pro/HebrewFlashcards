//
//  DebugAPIMock.swift
//  HebrewFlashcards
//
//  Created by Jonathan Guez on 02/08/2026.
//
//  DEBUG-only HTTPClient mock for live / offline / HTTP 500 API failure modes.
//

import Foundation

#if DEBUG
/// Flip `mode` to mock API failures without touching production networking.
enum DebugAPIMock {
    enum Mode {
        /// Real network (default for shipping; use this after you're done testing).
        case live
        /// Throws `URLError.notConnectedToInternet` → offline cache / bundled fallback.
        case offline
        /// Returns HTTP 500 → error UI (no silent cache fallback).
        case http500
    }

    /// 👉 Set to `.live` when you want the real Citizen Hub API again.
    static var mode: Mode = .live
}

struct MockFailingHTTPClient: HTTPClient {
    let mode: DebugAPIMock.Mode

    func data(from url: URL) async throws -> (Data, URLResponse) {
        switch mode {
        case .live:
            return try await URLSession.shared.data(from: url)
        case .offline:
            print("🧪 [API] Mocked FAILED call — offline (notConnectedToInternet)")
            throw URLError(.notConnectedToInternet)
        case .http500:
            print("🧪 [API] Mocked FAILED call — HTTP 500")
            let response = HTTPURLResponse(
                url: url,
                statusCode: 500,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )
            guard let response else {
                throw VocabError.underlying("Could not build mock HTTP 500 response.")
            }
            return (Data(#"{"error":"mock server failure"}"#.utf8), response)
        }
    }
}
#endif
