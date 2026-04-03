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
├── Examples/                    GitHub Actions workflow examples
├── fresco.template.env          example configuration
├── .github/
│   └── workflows/
│       ├── ci.yml               build and test on push
│       └── release.yml          release automation
└── gallery.md
```

---

## Configuration

All configuration is handled by [apple/swift-configuration](https://github.com/apple/swift-configuration) using environment variables. No YAML, no custom config loader, no credentials store.

A single `.env` file (or environment variables in CI) provides everything:

```
FRESCO_PROMPT=A fresco like the ones you'd see in central Texas, tagged with graffiti art that says Fresco. 4:1.
FRESCO_SLUG=fresco
GEMINI_API_KEY=xxx
R2_ACCOUNT_ID=xxx
R2_ACCESS_KEY_ID=xxx
R2_SECRET_ACCESS_KEY=xxx
R2_BUCKET=fresco-images
R2_PUBLIC_BASE_URL=https://pub-xxxx.r2.dev
```

The CLI loads config via a single `EnvironmentVariablesProvider` from swift-configuration, which reads both shell environment variables and a `.env` file if present:

```swift
let envProvider: EnvironmentVariablesProvider
if FileManager.default.fileExists(atPath: ".env") {
    envProvider = try await EnvironmentVariablesProvider(environmentFilePath: ".env")
} else {
    envProvider = EnvironmentVariablesProvider()
}
let config = ConfigReader(provider: envProvider)
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
│    └─▶ FrescoCore.GenerateService            │
│          calls GeminiClient (Imagen API)    │
│          writes image to /tmp/{slug}/       │
│                                             │
│  fresco upload <file> [destination]         │
│    │                                        │
│    └─▶ FrescoCore.UploadService             │
│          calls R2Client                     │
│          prints public URL                  │
│                                             │
│  fresco remote copy <source> <destination>  │
│    │                                        │
│    └─▶ FrescoCore.CopyService               │
│          S3 CopyObject via R2Client         │
│          prints public URL                  │
└─────────────────────────────────────────────┘
                      │
                      │ public URL
                      ▼
        https://pub-xxxx.r2.dev/{slug}/{filename}
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
        https://pub-xxxx.r2.dev/{slug}/{filename}
```

---

## FrescoCore — shared library

Everything that both the CLI and the server need lives in `FrescoCore`. Neither `FrescoCLI` nor `FrescoServer` duplicates this logic.

### Key types

**`GeminiClientProtocol`** + **`GeminiClient`**
URLSession-based Gemini Imagen API client. Returns image data. No third-party HTTP library.

**`R2ClientProtocol`** + **`R2Client`**
S3-compatible client for Cloudflare R2. Uses AWS Signature V4. Supports upload and server-side copy. No third-party SDK.

**`GenerateService`**
Generates an image using `GeminiClient`, writes it to `/tmp/{slug}/`, and returns the local file path.

**`UploadService`**
Uploads a local file to R2 as `{slug}/{filename}` and returns the public URL.

**`CopyService`**
Issues an S3 CopyObject request to copy an object within the bucket.

### Validators

**`SlugValidator`** — validates project slugs (alphanumeric, hyphens, underscores).

**`FilenameValidator`** — validates destination filenames (rejects path traversal, slashes).

---

## R2 storage layout

```
{bucket}/
└── {slug}/
    ├── latest.jpg                ← stable alias (via fresco remote copy)
    ├── 2026-03-23-141039.jpg     ← permanent archive
    ├── 2026-03-22-030000.jpg
    └── ...
```

The public URL pattern is always:
```
{publicBaseURL}/{slug}/{filename}
```

---

## Repository/protocol/mock pattern

All external dependencies (Gemini, R2) are behind protocols. Tests use mock implementations that live in test targets (not in FrescoCore). No network calls in the test suite.

```
GeminiClientProtocol
    ├── GeminiClient          (production — URLSession)
    └── MockGeminiClient      (tests — configurable result or error)

R2ClientProtocol
    ├── R2Client              (production — S3-compatible)
    └── MockR2Client          (tests — configurable error, optional callbacks)
```

For configuration in CLI tests, use swift-configuration's `InMemoryProvider` to supply test values without touching the environment or files.
