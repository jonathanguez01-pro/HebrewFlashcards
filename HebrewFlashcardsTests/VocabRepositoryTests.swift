import XCTest
@testable import HebrewFlashcards

final class VocabRepositoryTests: XCTestCase {

    /// Successful remote response is decoded and cached to disk.
    func testSuccessfulRemoteResponseIsDecodedAndCached() async throws {
        let levels = sampleLevels(tier: "Foundation", level: "Red", hebrew: "שלום", english: "hello")
        let client = MockHTTPClient.ok(levels)
        let cache = try makeTempCache()
        let repository = VocabRepository(
            api: VocabAPIClient(client: client),
            cache: cache,
            bundled: MockBundledLoader(result: .failure(VocabError.bundledFallbackMissing))
        )

        let result = try await repository.load()

        XCTAssertEqual(result.source, .remote)
        XCTAssertEqual(result.levels, levels)
        XCTAssertTrue(cache.hasCache)
        XCTAssertEqual(try cache.load(), levels)
    }

    /// Offline request (connectivity error) loads the disk cache.
    func testOfflineRequestLoadsDiskCache() async throws {
        let cachedLevels = sampleLevels(tier: "Flow", level: "Blue", hebrew: "מים", english: "water")
        let cache = try makeTempCache()
        try cache.save(cachedLevels)

        let repository = VocabRepository(
            api: VocabAPIClient(client: MockHTTPClient.offline),
            cache: cache,
            bundled: MockBundledLoader(result: .failure(VocabError.bundledFallbackMissing))
        )

        let result = try await repository.load()

        XCTAssertEqual(result.source, .diskCache)
        XCTAssertEqual(result.levels, cachedLevels)
    }

    /// An HTTP 500 response does not silently load a stale cache.
    func testHTTP500DoesNotLoadStaleCache() async throws {
        let stale = sampleLevels(tier: "Foundation", level: "Pink", hebrew: "כן", english: "yes")
        let cache = try makeTempCache()
        try cache.save(stale)

        let repository = VocabRepository(
            api: VocabAPIClient(client: MockHTTPClient.status(500)),
            cache: cache,
            bundled: MockBundledLoader(result: .success(stale))
        )

        do {
            _ = try await repository.load()
            XCTFail("Expected HTTP 500 to surface as an error")
        } catch let error as VocabError {
            XCTAssertEqual(error, .invalidHTTPStatus(500))
            // Stale cache must remain unused for this failure path.
            XCTAssertEqual(try cache.load(), stale)
        }
    }

    /// Invalid JSON surfaces a decoding error rather than falling back.
    func testInvalidJSONSurfacesDecodingError() async throws {
        let stale = sampleLevels(tier: "Freedom", level: "Purple", hebrew: "ספר", english: "book")
        let cache = try makeTempCache()
        try cache.save(stale)

        let client = MockHTTPClient { _ in
            guard let response = HTTPURLResponse(
                url: VocabAPIClient.defaultEndpoint,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            ) else {
                throw VocabError.underlying("Could not build HTTPURLResponse for tests.")
            }
            return (Data("{\"not\":\"an array\"}".utf8), response)
        }

        let repository = VocabRepository(
            api: VocabAPIClient(client: client),
            cache: cache,
            bundled: MockBundledLoader(result: .success(stale))
        )

        do {
            _ = try await repository.load()
            XCTFail("Expected decoding failure")
        } catch let error as VocabError {
            guard case .decodingFailed = error else {
                return XCTFail("Expected decodingFailed, got \(error)")
            }
        }
    }

    // MARK: - Helpers

    private func makeTempCache() throws -> VocabCacheStore {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("vocab-test-\(UUID().uuidString).json")
        return VocabCacheStore(fileURL: url)
    }

    private func sampleLevels(
        tier: String,
        level: String,
        hebrew: String,
        english: String
    ) -> [VocabLevel] {
        [
            VocabLevel(
                tier: tier,
                level: level,
                type: nil,
                pairs: [WordPair(hebrew: hebrew, english: english)]
            )
        ]
    }
}

final class HomeViewModelTests: XCTestCase {

    /// Changing the tier resets an invalid level or type selection.
    @MainActor
    func testChangingTierResetsLevelAndTypeSelection() async {
        let levels = [
            VocabLevel(
                tier: "Foundation",
                level: "Red",
                type: nil,
                pairs: [WordPair(hebrew: "א", english: "a")]
            ),
            VocabLevel(
                tier: "Freedom",
                level: "Dark Green",
                type: 1,
                pairs: [WordPair(hebrew: "ב", english: "b")]
            ),
            VocabLevel(
                tier: "Freedom",
                level: "Dark Green",
                type: 2,
                pairs: [WordPair(hebrew: "ג", english: "c")]
            )
        ]
        let repository = StubRepository(result: .success(
            VocabLoadResult(levels: levels, source: .remote)
        ))
        let viewModel = HomeViewModel(repository: repository)
        await viewModel.load()

        viewModel.selectTier("Freedom")
        viewModel.selectLevel("Dark Green")
        viewModel.selectType(2)
        XCTAssertEqual(viewModel.selectedLevelName, "Dark Green")
        XCTAssertEqual(viewModel.selectedType, 2)

        viewModel.selectTier("Foundation")

        XCTAssertEqual(viewModel.selectedTier, "Foundation")
        XCTAssertEqual(viewModel.selectedLevelName, "Red")
        XCTAssertNil(viewModel.selectedType)
        XCTAssertEqual(viewModel.selectedVocabLevel?.level, "Red")
    }
}

// MARK: - Test doubles

private struct MockHTTPClient: HTTPClient {
    let handler: @Sendable (URL) async throws -> (Data, URLResponse)

    func data(from url: URL) async throws -> (Data, URLResponse) {
        try await handler(url)
    }

    static func ok(_ levels: [VocabLevel]) -> MockHTTPClient {
        MockHTTPClient { _ in
            let data = try JSONEncoder().encode(levels)
            return (data, try makeResponse(status: 200))
        }
    }

    static var offline: MockHTTPClient {
        MockHTTPClient { _ in throw URLError(.notConnectedToInternet) }
    }

    static func status(_ code: Int) -> MockHTTPClient {
        MockHTTPClient { _ in
            (Data("{}".utf8), try makeResponse(status: code))
        }
    }

    private static func makeResponse(status: Int) throws -> HTTPURLResponse {
        guard let response = HTTPURLResponse(
            url: VocabAPIClient.defaultEndpoint,
            statusCode: status,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        ) else {
            throw VocabError.underlying("Could not build HTTPURLResponse for tests.")
        }
        return response
    }
}

private struct MockBundledLoader: BundledVocabLoading {
    let result: Result<[VocabLevel], Error>

    func load() throws -> [VocabLevel] {
        try result.get()
    }
}

private struct StubRepository: VocabRepositoryProtocol {
    let result: Result<VocabLoadResult, Error>

    func load() async throws -> VocabLoadResult {
        try result.get()
    }
}
