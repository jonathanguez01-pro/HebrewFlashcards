# Hebrew Flashcards

Native SwiftUI iOS app for studying Hebrew ↔ English vocabulary from [Citizen Café](https://citizencafetlv.com)’s public vocab API.

## Demo video

> **TODO:** Record a short Simulator/device run (pick a path → flip a card → Next / Shuffle) and paste the Loom / unlisted YouTube / file URL here.

**Demo Video URL:** _add link before submission_

## Build instructions

| Item | Value |
| --- | --- |
| Xcode | **26.4** (Build 17E192) |
| Swift | 5.9+ |
| Minimum iOS | **17.0** |
| Suggested simulator | **iPhone 16** (any iOS 17+ iPhone simulator is fine) |
| Project | `HebrewFlashcards.xcodeproj` (SwiftUI app lifecycle) |

```bash
open HebrewFlashcards.xcodeproj
```

1. Select an iOS 17+ simulator (e.g. iPhone 16).
2. Run the **HebrewFlashcards** scheme (`⌘R`).
3. Optional — run tests:

```bash
xcodebuild test \
  -scheme HebrewFlashcards \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Architecture decisions

MVVM with networking and persistence kept outside views and view models.

| Layer | Responsibility |
| --- | --- |
| **Views** | SwiftUI only — bind to view models, no networking/disk I/O |
| **ViewModels** (`ObservableObject`) | UI state, pickers, flip / next / shuffle; depend on `VocabRepositoryProtocol` |
| **VocabRepository** | Launch-time load strategy (remote → cache → bundled) |
| **VocabAPIClient** + `HTTPClient` | `URLSession` + async/await, HTTP status validation |
| **VocabCacheStore** + `VocabCacheStoring` | FileManager JSON persistence |
| **BundledVocabLoader** | App-bundle fallback JSON |

**Why `ObservableObject` instead of `@Observable`?** Both are accepted by the brief. `ObservableObject` + `@Published` keeps state binding straightforward and avoids Observation macro tooling issues in some CLI environments.

### Separation / DI / testability

- **Separation** — `VocabAPIClient`, `VocabCacheStore`, and `BundledVocabLoader` own I/O. Views never call `URLSession` or `FileManager`.
- **Dependency injection** — Protocol-typed dependencies via initialisers. The app entry point wires the live graph; tests inject mocks / temp-file caches.
- **Testability** — Repository load paths and selection / flashcard state are covered with XCTest and no live network.

### Repository load strategy (every launch)

1. **Remote fetch** — `GET https://hub.citizencafetlv.com/api/public/vocab`
2. **Success** — decode, overwrite disk cache, display
3. **Connectivity failure** — load disk cache if present
4. **No disk cache** — load bundled `vocab_fallback.json`

Non-connectivity failures (HTTP 4xx/5xx, invalid JSON) are **surfaced as errors** — they do not fall back to cache.

## Storage choice and rationale

Cache path: **Application Support** → `…/Application Support/HebrewFlashcards/vocab_cache.json` (FileManager + JSON).

**Why not `Library/Caches`?** Vocabulary is required for offline study. Caches may be purged under storage pressure, which would drop a previously successful sync back to the bundled fallback. Application Support is meant for app-managed data that should survive restores and normal cache eviction.

**Why not UserDefaults?** The full vocabulary dataset is too large and structured for defaults; a JSON file is the right fit.

## Offline `URLError` cases

`ConnectivityClassifier` treats these as offline / unreachable (disk cache or bundled fallback):

- `.notConnectedToInternet`
- `.networkConnectionLost`
- `.timedOut`
- `.cannotFindHost`
- `.cannotConnectToHost`
- `.dnsLookupFailed`
- `.internationalRoamingOff`
- `.callIsActive`
- `.dataNotAllowed`

## UI

Native SwiftUI (`Form`, `Picker`, `NavigationStack`, SF Symbols) with Design Bible colours from the asset catalog:

- **Charcoal** `#1C1C1C` — primary text / emphasis (`Charcoal`)
- **Yellow** `#F5C518` — accent / CTA (`AccentColor`)
- **Warm off-white** `#F7F3E8` — canvas (`WarmOffWhite`)

System fonts only. Two focused screens: study-path pickers, then flashcards (3D flip, Next, Shuffle, progress).

## Tests

Focused XCTest coverage (no live network):

| Scenario from the brief | Test |
| --- | --- |
| Successful remote response is decoded and cached | `testSuccessfulRemoteResponseIsDecodedAndCached` |
| Offline connectivity error loads disk cache | `testOfflineRequestLoadsDiskCache` |
| HTTP 500 does not silently load a stale cache | `testHTTP500DoesNotLoadStaleCache` |
| Invalid JSON surfaces a decoding error | `testInvalidJSONSurfacesDecodingError` |
| Changing tier resets invalid level/type | `testChangingTierResetsLevelAndTypeSelection` |

Not separately asserted: offline first launch → bundled JSON (same offline branch as disk-cache fallback; `BundledVocabLoading` is injectable).

## Intentionally skipped

Prioritised repository behaviour, state management, and core flashcard interaction within the ~4 hour window:

- Dark mode polish beyond asset dark variants / system defaults
- Haptic feedback on flip
- Swipe-to-next gesture
- Full VoiceOver audit (basic card labels are present)
- Completion screen
- Custom fonts (and licensing)

Reduce Motion is partially respected (non-animated flip path).

## Bundled fallback note

`HebrewFlashcards/Resources/vocab_fallback.json` matches the API shape. After a successful online launch, Application Support holds the live Citizen Hub payload. Replace the bundled file with a real API snapshot if you want first-launch offline content to match production exactly.

## AI usage disclosure

This assignment was built with assistance from **Cursor** (AI coding agent). The agent scaffolded the Xcode project, implemented the repository / networking / caching layers, SwiftUI UI, unit tests, and this README from the written brief. Human direction covered requirements intake, architecture priorities (networking + core flip over polish), and submission checklist review. All networking fallback rules, DI boundaries, and tests were written to match the assignment spec rather than generic templates.
