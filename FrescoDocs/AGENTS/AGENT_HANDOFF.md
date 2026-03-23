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
   - All product docs in `docs/`
   - `.gitignore`, `README.md`, `gallery.md`, `fresco.template.env` at the repo root

2. **Branch protections** — Enable branch protections on main requiring all CI status checks to pass before merge.

3. **Implementation milestones** — Create the milestones, grouping issues, and sub-issues for Phase 1 CLI implementation as described in `AGENTS/DEVELOPMENT.md`. Every sub-issue must have a complete brief with exact types, method signatures, and test expectations before any agent begins coding.

**Do not skip this step.** Do not start implementing features until the project setup milestone is complete and all issues are created. The issue structure IS the plan.

---

## What you are building

The `fresco` CLI tool — Phase 1 of the Fresco project. A Swift 6 command-line tool that generates a daily AI image using the Google Gemini Imagen API, uploads it to Cloudflare R2, and maintains a `gallery.md` file in the project repo.

The full product vision and architecture are in `docs/VISION.md` and `docs/ARCHITECTURE.md`. Read those too.

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
│   └── docs/
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

| Variable | Description |
|---|---|
| `FRESCO_PROMPT` | The image generation prompt (single string) |
| `FRESCO_SLUG` | Project slug — used in R2 paths and URLs |
| `FRESCO_NAME` | Display name |
| `FRESCO_SCHEDULE` | Generation frequency: `daily`, `weekly`, `monthly`, `quarterly`, or `annual` |
| `FRESCO_SCHEDULE_HOUR` | UTC hour for generation (0-23) |
| `GEMINI_API_KEY` | Google Gemini API key |
| `R2_ACCOUNT_ID` | Cloudflare account ID |
| `R2_ACCESS_KEY_ID` | R2 access key |
| `R2_SECRET_ACCESS_KEY` | R2 secret key |
| `R2_BUCKET` | R2 bucket name |
| `R2_PUBLIC_BASE_URL` | R2 public URL (e.g. `https://pub-xxxx.r2.dev`) |

Locally these live in `.env` (gitignored). In CI they come from GitHub Actions secrets.

---

## What you need to implement

### FrescoCore

All shared logic. No UI, no argument parsing, no file system assumptions.

**Models:**

`GenerationResult` — result of one generation attempt
```swift
struct GenerationResult: Sendable {
    let date: Date
    let prompt: String
    let imageData: Data
    let r2Key: String       // e.g. "fresco/2026-03-23.jpg"
    let publicURL: URL      // e.g. https://pub-xxx.r2.dev/fresco/2026-03-23.jpg
}
```

**Protocols and implementations:**

`GeminiClientProtocol` + `GeminiClient` — calls Gemini Imagen API, returns JPEG `Data`. URLSession only, no third-party HTTP client.

`R2ClientProtocol` + `R2Client` — S3-compatible uploads to Cloudflare R2. Use AWS Signature V4. Upload both `{slug}/YYYY-MM-DD.jpg` (archive) and `{slug}/today.jpg` (overwrite). No third-party SDK.

`GenerationProviderProtocol` + `DirectGenerationProvider` — orchestrates Gemini + R2 for standalone mode. This is what the CLI calls.

`ServerGenerationProvider` — stub only for Phase 1. Throws `FrescoError.serverModeNotImplemented`. Will be implemented in Phase 2.

**Mock implementations** (in `FrescoCore`, used by tests):
- `MockGeminiClient` — configurable behaviour (success with data, or throws)
- `MockR2Client` — in-memory store, tracks uploaded keys
- `MockGenerationProvider` — returns fixed `GenerationResult` or throws

---

### FrescoCLI

All commands. Import `FrescoCore` and `ArgumentParser`. No business logic here — delegate everything to `FrescoCore`.

**Commands to implement:**

`fresco init`
- Interactive by default: project name, prompt, schedule hour, credentials
- All values can be provided via flags for non-interactive use (agents, scripts)
- `--defaults` flag: use default/placeholder values for anything not provided
- Without `--defaults`, missing values are prompted for interactively
- Write `.env` with all configuration
- Write `.github/workflows/fresco.yml` with the cron expression matching `FRESCO_SCHEDULE` (daily=`0 H * * *`, weekly=`0 H * * 1`, monthly=`0 H 1 * *`, quarterly=`0 H 1 1,4,7,10 *`, annual=`0 H 1 1 *` where H is `FRESCO_SCHEDULE_HOUR`)
- Insert image URL into README.md
- Create `gallery.md` if it doesn't exist
- Set GitHub Actions secrets via `gh secret set`
- Offer to run `fresco generate` immediately

Flags: `--name`, `--slug`, `--prompt`, `--schedule`, `--schedule-hour`, `--gemini-key`, `--r2-account-id`, `--r2-access-key-id`, `--r2-secret-access-key`, `--r2-bucket`, `--r2-public-base-url`, `--defaults`, `--force`

`fresco generate`
- Read config from environment via swift-configuration
- `--prompt` flag: override `FRESCO_PROMPT` entirely for this run
- `--append` flag: append text to `FRESCO_PROMPT` for this run
- Call `DirectGenerationProvider.generate(prompt:slug:date:)`
- Append entry to `gallery.md`
- Print success with the public URL
- Always generates when called — schedule frequency is handled entirely by the cron expression in the GitHub Actions workflow

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

Two uploads per generation:
1. `PUT /{bucket}/{slug}/2026-03-23.jpg` — permanent archive, `Cache-Control: public, max-age=31536000`
2. `PUT /{bucket}/{slug}/today.jpg` — overwritten daily, `Cache-Control: public, max-age=3600`

The public URL uses the R2 public bucket URL, not the S3-compatible endpoint:
```
{publicBaseURL}/{slug}/today.jpg
{publicBaseURL}/{slug}/2026-03-23.jpg
```

---

## Tests to write

**FrescoCoreTests:**

`DirectGenerationProviderTests`
- Success: Gemini returns data, R2 receives two uploads, result has correct URL
- Gemini failure: error propagated, R2 not called
- R2 failure: error propagated after Gemini succeeds

Use swift-configuration's `InMemoryProvider` for test configuration.

---

## Definition of done

- [ ] `swift build` succeeds with no errors
- [ ] `swift test` passes — all tests green
- [ ] `fresco --help` lists all commands
- [ ] `fresco init` creates .env, workflow, updates README, sets GitHub secrets (interactive and non-interactive modes)
- [ ] `fresco generate` calls Gemini, uploads two objects to R2, appends to gallery.md
- [ ] Gallery.md has correct format after generation
- [ ] Credentials never appear in any committed file

---

## What NOT to change

- Any file in `docs/` — these are the spec, not the implementation
- `gallery.md` — only append to this, never rewrite the header
- `README.md` — only modify via `fresco init`, not manually
- `FrescoCore/Package.swift` and `FrescoCLI/Package.swift` — only add new targets or dependencies if genuinely needed
