# Fresco — Architecture

## Monorepo structure

Each package has its own `Package.swift`. FrescoCLI depends on FrescoCore via a path dependency.

```
Fresco/
├── FrescoCore/
│   ├── Package.swift            shared library — both CLI and server import this
│   ├── Sources/FrescoCore/
│   └── Tests/FrescoCoreTests/
├── FrescoCLI/
│   ├── Package.swift            the `fresco` command line tool
│   ├── Sources/FrescoCLI/
│   └── Tests/FrescoCLITests/
├── FrescoDocs/                  design docs and templates
├── fresco.template.env           example configuration
├── .github/
│   └── workflows/
│       ├── fresco.yml           daily image generation
│       └── ci.yml               build and test on push
├── docs/
├── gallery.md
└── homebrew/
    └── fresco.rb                Homebrew formula
```

---

## Configuration

All configuration is handled by [apple/swift-configuration](https://github.com/apple/swift-configuration) using environment variables. No YAML, no custom config loader, no credentials store.

A single `.env` file (or environment variables in CI) provides everything:

```
FRESCO_PROMPT="A fresco like the ones you'd see in central Texas, tagged with graffiti art that says Fresco. 4:1."
FRESCO_SLUG=fresco
FRESCO_NAME=Fresco
FRESCO_SCHEDULE=daily
FRESCO_SCHEDULE_HOUR=3
GEMINI_API_KEY=xxx
R2_ACCOUNT_ID=xxx
R2_ACCESS_KEY_ID=xxx
R2_SECRET_ACCESS_KEY=xxx
R2_BUCKET=fresco-images
R2_PUBLIC_BASE_URL=https://pub-xxxx.r2.dev
```

The provider hierarchy in code:

```swift
let config = ConfigReader(providers: [
    EnvironmentVariablesProvider(),   // env vars (CI, shell)
    // .env file provider if needed
])
```

In GitHub Actions, these values come from repository secrets. Locally, they live in `.env` (gitignored).

---

## Phase 1 architecture

```
┌─────────────────────────────────────────────┐
│  Developer machine or GitHub Actions runner  │
│                                             │
│  fresco generate                            │
│    │                                        │
│    ├─▶ swift-configuration                  │
│    │     reads env vars / .env              │
│    │                                        │
│    ├─▶ FrescoCore.GeminiClient              │
│    │     POST Gemini Imagen API             │
│    │     returns JPEG bytes                 │
│    │                                        │
│    ├─▶ FrescoCore.R2Client                  │
│    │     uploads YYYY-MM-DD.jpg             │
│    │     uploads today.jpg (overwrite)      │
│    │                                        │
│    └─▶ FrescoCLI.GalleryWriter              │
│          appends entry to gallery.md        │
│          git add + commit + push            │
└─────────────────────────────────────────────┘
                      │
                      │ stable public URL
                      ▼
        https://pub-xxxx.r2.dev/{slug}/today.jpg
                      │
              ┌───────┴────────┐
              │  README.md     │
              │  Website       │
              │  Anywhere      │
              └────────────────┘
```

---

## Phase 2 architecture

```
┌──────────────────────────────────────────────┐
│  Developer machine                            │
│                                              │
│  fresco generate                             │
│    └─▶ ServerGenerationProvider              │
│          POST /feeds/{slug}/generate         │
│          ← 202 Accepted                      │
└──────────────────────┬───────────────────────┘
                       │ HTTPS
┌──────────────────────▼───────────────────────┐
│  Hetzner VPS                                  │
│                                              │
│  FrescoServer (Hummingbird)                  │
│    ├─▶ SchedulerService                      │
│    │     one Task per feed                   │
│    │     sleeps until schedule_hour UTC      │
│    │                                         │
│    ├─▶ FrescoCore.GeminiClient               │
│    ├─▶ FrescoCore.R2Client                   │
│    └─▶ PostgreSQL                            │
│          feeds table                         │
│          generation_records table            │
└──────────────────────┬───────────────────────┘
                       │ uploads
                       ▼
        https://pub-xxxx.r2.dev/{slug}/today.jpg
```

---

## FrescoCore — shared library

Everything that both the CLI and the server need lives in `FrescoCore`. Neither `FrescoCLI` nor `FrescoServer` duplicates this logic.

### Key types

**`GenerationProviderProtocol`**
The central abstraction. The CLI and server both work through this protocol — they never call Gemini or R2 directly.

```swift
protocol GenerationProviderProtocol: Sendable {
    func generate(prompt: String, slug: String, date: Date) async throws -> GenerationResult
}
```

**`DirectGenerationProvider`** — Phase 1
Implements the protocol by calling `GeminiClient` and `R2Client` directly. Used by the CLI in standalone mode.

**`ServerGenerationProvider`** — Phase 2
Implements the protocol by calling the Fresco server API. Used by the CLI in server mode.

**`GeminiClient`**
URLSession-based Gemini Imagen API client. No third-party HTTP library.

**`R2Client`**
S3-compatible client for Cloudflare R2. Uses AWS Signature V4. No third-party SDK.

---

## The GenerationProviderProtocol pattern

The CLI determines which provider to use at startup based on whether a server URL is configured:

```swift
let provider: any GenerationProviderProtocol

if let serverURL = config.string(forKey: "FRESCO_SERVER_URL") {
    provider = ServerGenerationProvider(serverURL: serverURL, apiKey: apiKey)
} else {
    provider = DirectGenerationProvider(gemini: geminiClient, r2: r2Client)
}
```

From that point on, all generation logic is identical regardless of phase. Adding server support in Phase 2 requires no changes to any command implementation.

---

## R2 storage layout

```
{bucket}/
└── {slug}/
    ├── today.jpg          ← overwritten daily (not a symlink — R2 is object storage)
    ├── 2026-03-23.jpg     ← permanent archive
    ├── 2026-03-22.jpg
    └── ...
```

The public URL pattern is always:
```
{publicBaseURL}/{slug}/today.jpg
{publicBaseURL}/{slug}/2026-03-23.jpg
```

---

## Repository/protocol/mock pattern

All external dependencies (Gemini, R2, the Fresco server) are behind protocols. Tests use in-memory mocks. No network calls in the test suite.

```
GeminiClientProtocol
    ├── GeminiClient          (production — URLSession)
    └── MockGeminiClient      (tests — returns fixed data or throws)

R2ClientProtocol
    ├── R2Client              (production — S3-compatible)
    └── MockR2Client          (tests — in-memory store)

GenerationProviderProtocol
    ├── DirectGenerationProvider   (Phase 1 — direct API calls)
    ├── ServerGenerationProvider   (Phase 2 — calls Fresco server)
    └── MockGenerationProvider     (tests)
```

For configuration in tests, use swift-configuration's `InMemoryProvider` to supply test values without touching the environment or files.
