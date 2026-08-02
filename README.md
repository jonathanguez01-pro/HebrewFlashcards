# Hebrew Flashcards

A native **SwiftUI** iOS app for studying Hebrew ↔ English vocabulary from [Citizen Café](https://citizencafetlv.com)’s public Citizen Hub API.

Cards follow the curriculum structure **Tier → Level → Type** (content packs). Learners pick a path, study with a real **3D flip**, and optionally hear Hebrew pronunciation.

---

## Demo video

**Demo Video URL:** _Add Loom / unlisted YouTube / file link before submission._

Suggested recording flow (~60–90s): launch → select tier/level → flip a card → toggle speech → Next through to **Finish** → confetti completion.

---

## Requirements

| | |
| --- | --- |
| **Xcode** | 26.4 (Build 17E192) |
| **Swift** | 5.9+ (project language mode: Swift 5) |
| **Minimum iOS** | 17.0 |
| **Suggested simulator** | iPhone 16 (any iOS 17+ iPhone simulator) |
| **Project** | `HebrewFlashcards.xcodeproj` — SwiftUI app lifecycle (no Storyboards) |

### Run

```bash
open HebrewFlashcards.xcodeproj
```

1. Select an iOS 17+ simulator.
2. Run the **HebrewFlashcards** scheme (`⌘R`).
3. Run unit tests (`⌘U`), or:

```bash
xcodebuild test \
  -scheme HebrewFlashcards \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

> **DEBUG tip:** In `DebugAPIMock.swift`, set `mode` to `.offline` or `.http500` to exercise failure paths without disabling Wi‑Fi. Use `.live` for the real API.

---

## Features

### Core (assignment)

- Launch-time vocabulary load: **remote → disk cache → bundled fallback**
- Clear loading and error states; connectivity failures fall back, HTTP/decode errors surface
- Tier / Level pickers; conditional **Type** (content pack) for Dark Green, Turquoise, Indigo
- Flashcards: Hebrew prompt → tap for **3D flip** → English; **Next**, **Shuffle**, swipe-left for next, progress `n / N`

### Polish / delight

- Branded **splash screen** on launch (covers initial vocabulary fetch + short minimum display)
- Design Bible colours via asset catalog (charcoal, yellow, warm off-white)
- Glass-style panels with **level-adaptive** accent colours
- **Light & Dark Mode** via asset catalog + adaptive materials (follows system appearance)
- Haptic + soft sound on flip
- Optional **Hebrew speech** (`AVSpeechSynthesizer`, `he-IL`) — toolbar on/off, preference persisted
- **Pack complete** confetti overlay when finishing the last card
- Swipe left on the card to go Next / Finish

---

## Architecture

**MVVM** with networking and persistence outside the UI layer.

```
HebrewFlashcardsApp
        │
        ▼
   ContentView / HomeView / FlashcardView
        │
        ▼
 HomeViewModel / FlashcardViewModel   ← ObservableObject
        │
        ▼
 VocabRepository  (VocabRepositoryProtocol)
        ├── VocabAPIClient      (HTTPClient / URLSession)
        ├── VocabCacheStore     (Application Support JSON)
        └── BundledVocabLoader  (app bundle JSON)
```

| Layer | Responsibility |
| --- | --- |
| **Views** | SwiftUI only — layout, gestures, presentation |
| **ViewModels** | UI state and user intents; depend on protocols |
| **Repository** | Load policy (remote / cache / bundle) |
| **API client** | HTTP, status validation, JSON decode |
| **Cache / bundle** | Read/write vocabulary JSON |

### Design choices

- **`ObservableObject`** — Accepted by the brief alongside `@Observable`. Chosen for straightforward `@Published` / `@StateObject` binding.
- **Repository pattern** — Single place for the offline strategy so views never call `URLSession` or `FileManager`.
- **Dependency injection** — `HTTPClient`, `VocabCacheStoring`, `BundledVocabLoading`, and `VocabRepositoryProtocol` are injected via initialisers. The app wires the live graph; tests swap mocks.
- **Swift 6–friendly storage** — Cache types store `Sendable` values (e.g. `URL`) and create `FileManager` / encoders per call to avoid non-Sendable stored properties.

---

## Data loading (every launch)

1. **Remote** — `GET https://hub.citizencafetlv.com/api/public/vocab` (no auth)
2. **Success** — Decode → **overwrite** disk cache → display
3. **Connectivity failure** — Load disk cache if present
4. **No disk cache** — Load bundled `vocab_fallback.json`

**HTTP 4xx/5xx and invalid JSON do not fall back to cache** — they surface as errors.

### First launch & loaders

| Situation | Behaviour |
| --- | --- |
| App start (any launch) | Splash shows; vocabulary `load()` runs underneath; splash spinner while still fetching |
| Slow network | Splash stays until load finishes (at least ~1.35s) then Home |
| First launch + **offline** (no disk cache yet) | Connectivity failure → **bundled** `vocab_fallback.json` → Home with offline footer |
| First launch + **HTTP/decode error** | Splash ends → Home **error** screen with Try Again (no silent cache — there isn’t one yet) |
| Later launch + offline | Disk cache if present; else bundled fallback |

---

### Offline `URLError` classification

Treated as connectivity failures (eligible for cache / bundle fallback):

| Code | Meaning |
| --- | --- |
| `.notConnectedToInternet` | Device offline |
| `.networkConnectionLost` | Connection dropped mid-request |
| `.timedOut` | Request timed out |
| `.cannotFindHost` / `.dnsLookupFailed` | DNS / host resolution |
| `.cannotConnectToHost` | Host unreachable |
| `.internationalRoamingOff` | Roaming blocked |
| `.callIsActive` | Cellular call blocking data |
| `.dataNotAllowed` | Data restricted |

---

## Storage

| Choice | Detail |
| --- | --- |
| **Location** | Application Support → `HebrewFlashcards/vocab_cache.json` |
| **Mechanism** | `FileManager` + `Codable` JSON |
| **Not Caches** | Vocabulary must survive OS cache eviction for offline study |
| **Not UserDefaults** | Full dataset is too large / structured for defaults |

Bundled fallback: `HebrewFlashcards/Resources/vocab_fallback.json` (same schema as the API). After a successful online launch, Application Support holds the live payload.

---

## UI & design

Native SwiftUI (`NavigationStack`, `Picker` / `Menu`, SF Symbols) — not a pixel clone of the web.

| Token | Light | Dark | Asset |
| --- | --- | --- | --- |
| Charcoal (text) | `#1C1C1C` | warm off-white | `Charcoal` |
| Yellow (accent) | `#F5C518` | `#F5C518` | `AccentColor` |
| Canvas | `#F7F3E8` | deep charcoal | `WarmOffWhite` |

System fonts only. Level names (Red, Blue, Indigo, …) drive adaptive accents. Appearance follows **Settings → Display & Brightness** (Light / Dark).

---

## Tests

Focused **XCTest** coverage with mocked `HTTPClient` and temp-file caches — **no live network**.

| Scenario | Test |
| --- | --- |
| Remote success decoded and written to disk | `testSuccessfulRemoteResponseIsDecodedAndCached` |
| Offline error loads disk cache | `testOfflineRequestLoadsDiskCache` |
| HTTP 500 does not use stale cache | `testHTTP500DoesNotLoadStaleCache` |
| Invalid JSON → decoding error | `testInvalidJSONSurfacesDecodingError` |
| Changing tier resets level / type | `testChangingTierResetsLevelAndTypeSelection` |

Offline first-launch → bundled JSON uses the same offline branch as disk-cache fallback; `BundledVocabLoading` is injectable for tests.

---

## Intentionally skipped

Deferred so the core repository behaviour and flashcard loop stay clear for review:

- Full VoiceOver audit (basic labels exist on the flip card)
- Custom fonts (and licensing)
- Background App Refresh / timed stale polling (launch-time fetch covers the brief)

---

## AI usage disclosure

This project was built with assistance from **Cursor** (AI coding agent).

| AI-assisted | Human-directed |
| --- | --- |
| Xcode scaffolding, networking/cache/repository, SwiftUI UI, tests, README drafts | Requirements intake, architecture priorities, feature choices, submission review |
| App icon generation | Demo recording and GitHub publication |

Networking fallback rules, DI boundaries, and tests follow the written assignment specification.

---

## Project structure

```
HebrewFlashcards/
├── HebrewFlashcardsApp.swift      # Composition root
├── ContentView.swift
├── Brand.swift                    # Colours, glass, level themes
├── FlipFeedback.swift             # Haptics / sounds
├── HebrewSpeech.swift             # Optional TTS
├── Models/
├── Networking/                    # API client + DEBUG mock
├── Storage/                       # Cache + bundled loader
├── Repositories/
├── ViewModels/
├── Views/
└── Resources/vocab_fallback.json
HebrewFlashcardsTests/
└── VocabRepositoryTests.swift
```

**Repository:** https://github.com/jonathanguez01-pro/HebrewFlashcards
