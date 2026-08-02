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
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await client.data(from: endpoint)
        } catch let urlError as URLError {
            throw urlError
        } catch {
            throw VocabError.underlying(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw VocabError.underlying("Unexpected non-HTTP response.")
        }

        guard (200...299).contains(http.statusCode) else {
            throw VocabError.invalidHTTPStatus(http.statusCode)
        }

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
