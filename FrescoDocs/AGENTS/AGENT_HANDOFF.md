# Fresco — Agent Handoff: Phase 1 CLI

Read this document fully before touching any file. It is the complete implementation brief.

Follow `CLAUDE.md` at the repo root for all workflow rules, code style, and agent guidelines.

Review `AGENTS/TOOLCHAIN.md` for the list of internal tools that should be integrated into every project.

---

## Before you write any code

The first milestone is **Project Setup**. Before any implementation begins, the repository must be fully scaffolded and all workflow infrastructure must be in place.

### Project setup milestone

Create a GitHub milestone called "Project Setup" with a tracking issue that covers:

1. **Repository scaffolding** — All files from this handoff document and the `AGENTS/` directory must be created in their correct locations in the repo. This includes:
   - `CLAUDE.md` at the repo root (already written)
   - `.github/workflows/ci.yml` and `.github/workflows/fresco.yml`
   - `.github/ISSUE_TEMPLATE/grouping.md` (from `AGENTS/ISSUE_TEMPLATE_GROUPING.md`)
   - `.github/ISSUE_TEMPLATE/sub-issue.md` (from `AGENTS/ISSUE_TEMPLATE_SUBISSUE.md`)
   - `.github/PULL_REQUEST_TEMPLATE.md` (from `AGENTS/PULL_REQUEST_TEMPLATE.md`)
   - All product docs in `FrescoDocs/`
   - `.gitignore`, `README.md`, `gallery.md`, `fresco.template.env` at the repo root

2. **Branch protections** — Enable branch protections on main requiring all CI status checks to pass before merge.

3. **Implementation milestones** — Create the milestones, grouping issues, and sub-issues for Phase 1 CLI implementation as described in `AGENTS/DEVELOPMENT.md`. Every sub-issue must have a complete brief with exact types, method signatures, and test expectations before any agent begins coding.

**Do not skip this step.** Do not start implementing features until the project setup milestone is complete and all issues are created. The issue structure IS the plan.

---

## What you are building

The `fresco` CLI tool — Phase 1 of the Fresco project. A composable Swift 6 command-line tool that generates images using the Google Gemini Imagen API and publishes them to Cloudflare R2.

The full product vision and architecture are in `FrescoDocs/VISION.md` and `FrescoDocs/ARCHITECTURE.md`. Read those too.

---

## Repo

`github.com/argylebits/Fresco` — public, multi-package monorepo, MIT licensed. Each package (`FrescoCore`, `FrescoCLI`) has its own `Package.swift`. FrescoCLI depends on FrescoCore via a path dependency.

---

## What already exists

```
Fresco/
├── CLAUDE.md                        ✓ written
├── .gitignore                       ✓ written
├── fresco.template.env               ✓ written
├── README.md                        ✓ written
├── gallery.md                       ✓ written (empty table, ready for entries)
├── FrescoCore/
│   ├── Package.swift                ✓ written
│   ├── Sources/FrescoCore/          ← implement this
│   └── Tests/FrescoCoreTests/       ← implement this
├── FrescoCLI/
│   ├── Package.swift                ✓ written (depends on FrescoCore via path)
│   ├── Sources/FrescoCLI/           ← implement this
│   └── Tests/FrescoCLITests/        ← implement this
├── FrescoDocs/
│   ├── AGENTS/
│   │   ├── DEVELOPMENT.md           ✓ written (workflow rules, TDD, agent guidelines)
│   │   ├── AGENT_HANDOFF.md         ✓ written (this file)
│   │   ├── ISSUE_TEMPLATE_GROUPING.md   ✓ written → install to .github/ISSUE_TEMPLATE/
│   │   ├── ISSUE_TEMPLATE_SUBISSUE.md   ✓ written → install to .github/ISSUE_TEMPLATE/
│   │   └── PULL_REQUEST_TEMPLATE.md     ✓ written → install to .github/
│   ├── template.github/
│   │   └── workflows/
│   │       ├── fresco.yml           ✓ written (daily generation) → install to .github/workflows/
│   │       └── ci.yml               ✓ written (build + test on all PRs) → install to .github/workflows/
│   └── FrescoDocs/
│       ├── VISION.md                ✓ written
│       ├── CLI.md                   ✓ written
│       ├── ARCHITECTURE.md          ✓ written
│       ├── PROMPT_CONFIG.md         ✓ written
│       └── DEPLOYMENT.md            ✓ written
└── (root config files)
```

---

## Configuration

All configuration uses [apple/swift-configuration](https://github.com/apple/swift-configuration) with `EnvironmentVariablesProvider`. No YAML, no custom config loaders, no credentials store.

**Environment variables:**

| Variable | Used by | Description |
|---|---|---|
| `FRESCO_PROMPT` | generate | The image generation prompt (single string) |
| `FRESCO_SLUG` | all | Project slug — used in filenames and R2 paths |
| `GEMINI_API_KEY` | generate | Google Gemini API key |
| `R2_ACCOUNT_ID` | upload, remote copy | Cloudflare account ID |
| `R2_ACCESS_KEY_ID` | upload, remote copy | R2 access key |
| `R2_SECRET_ACCESS_KEY` | upload, remote copy | R2 secret key |
| `R2_BUCKET` | upload, remote copy | R2 bucket name |
| `R2_PUBLIC_BASE_URL` | upload, remote copy | R2 public URL (e.g. `https://pub-xxxx.r2.dev`) |

Locally these live in `.env` (gitignored). In CI they come from GitHub Actions secrets.

---

## What you need to implement

### FrescoCore

All shared logic. No UI, no argument parsing.

**Models:**

`GenerationResult` — result of image generation
```swift
struct GenerationResult: Sendable, Codable {
    let date: Date
    let prompt: String
    let imageData: Data
    let filePath: String    // e.g. "/tmp/my-slug/2026-03-23-141039.jpg"
}
```

`UploadResult` — result of upload or copy
```swift
struct UploadResult: Sendable, Codable {
    let r2Key: String       // e.g. "fresco/2026-03-23-141039.jpg"
    let publicURL: URL      // e.g. https://pub-xxx.r2.dev/fresco/2026-03-23-141039.jpg
}
```

**Protocols and implementations:**

`GeminiClientProtocol` + `GeminiClient` — calls Gemini Imagen API, returns image `Data`. URLSession only, no third-party HTTP client.

`R2ClientProtocol` + `R2Client` — S3-compatible client for Cloudflare R2. Uses AWS Signature V4. Supports upload and server-side copy. No third-party SDK.

**Services:**

`GenerateService` — calls `GeminiClient`, detects image format, writes to `/tmp/{slug}/{timestamp}.{ext}`, returns `GenerationResult`.

`UploadService` — reads a local file, validates the filename, uploads via `R2Client`, returns `UploadResult`.

`CopyService` — issues S3 CopyObject via `R2Client`, returns `UploadResult`.

**Validators:**

`SlugValidator` — validates project slugs (alphanumeric, hyphens, underscores).

`FilenameValidator` — validates filenames (rejects path traversal and slashes).

**Mock implementations** (in test targets, not FrescoCore):
- `MockGeminiClient` — configurable result or error
- `MockR2Client` — configurable error, optional callbacks for upload/copy

---

### FrescoCLI

All commands. Import `FrescoCore` and `ArgumentParser`. No business logic here — delegate everything to `FrescoCore`.

**Commands implemented:**

`fresco generate`
- Read config from environment via swift-configuration
- `--prompt` flag: override `FRESCO_PROMPT` entirely for this run
- `--append` flag: append text to `FRESCO_PROMPT` for this run
- Call `GenerateService.generate(prompt:slug:date:)`
- Write image to `/tmp/{slug}/{timestamp}.{ext}`
- Print the local file path to stdout

`fresco upload <file> [destination]`
- Upload a local image to R2 as `{slug}/{filename}` (or `{slug}/{destination}` if provided)
- Print the public URL to stdout

`fresco remote copy <source> <destination>`
- Issue an S3 CopyObject request to copy `{slug}/{source}` to `{slug}/{destination}` within the bucket
- Print the public URL of the destination object

---

### gallery.md format

Entries are prepended (newest first) below the header comment line:

```markdown
# Fresco Gallery

Daily images generated by [Fresco](README.md)...

<!-- Fresco appends new entries below this line on each generation -->

| Date | Image |
|------|-------|
| 2026-03-23 | ![](https://pub-xxx.r2.dev/fresco/2026-03-23.jpg) |
| 2026-03-22 | ![](https://pub-xxx.r2.dev/fresco/2026-03-22.jpg) |
```

---

## R2 upload details

Cloudflare R2 is S3-compatible. Use the S3 API with AWS Signature V4.

Endpoint: `https://{accountId}.r2.cloudflarestorage.com`

Upload via `fresco upload`:
- `PUT /{bucket}/{slug}/{filename}` — one upload per invocation

Copy via `fresco remote copy`:
- S3 CopyObject within the bucket — `{slug}/{source}` to `{slug}/{destination}`

The public URL uses the R2 public bucket URL, not the S3-compatible endpoint:
```
{publicBaseURL}/{slug}/{filename}
```

---

## Tests

**FrescoCoreTests:**

- `GenerateServiceTests` — Gemini returns data, image written to `/tmp/{slug}/`, result has correct path; Gemini failure propagated
- `UploadServiceTests` — file read, upload via R2Client, correct public URL; destination filename override; invalid filename rejected
- `CopyServiceTests` — copy via R2Client, correct public URL; invalid filenames rejected
- `R2ClientTests` — request building for upload and copy operations
- `GeminiClientTests` — request/response handling

Use swift-configuration's `InMemoryProvider` for test configuration in CLI tests.

---

## Definition of done

- [ ] `swift build` succeeds with no errors
- [ ] `swift test` passes — all tests green
- [ ] `fresco --help` lists all commands
- [ ] `fresco generate` calls Gemini, writes image to `/tmp/{slug}/`, prints file path
- [ ] `fresco upload` uploads to R2, prints public URL
- [ ] `fresco remote copy` copies within R2, prints public URL
- [ ] Credentials never appear in any committed file

---

## What NOT to change

- Any file in `FrescoDocs/` — these are the spec, not the implementation
- `gallery.md` — only append to this, never rewrite the header
- `README.md` — only modify the Fresco image line, not the overall structure
- `FrescoCore/Package.swift` and `FrescoCLI/Package.swift` — only add new targets or dependencies if genuinely needed
