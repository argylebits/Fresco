# Fresco — Development Guide

## Requirements

- Swift 6.0+
- Xcode 16+ (macOS) or Swift toolchain on Linux
- Homebrew (for local testing of the formula)
- GitHub CLI (`gh`) for issue/PR management and secrets

---

## Setup

```bash
git clone https://github.com/argylebits/Fresco
cd Fresco
swift build --package-path FrescoCore
swift build --package-path FrescoCLI
swift test --package-path FrescoCore
swift test --package-path FrescoCLI
```

---

## Running locally

```bash
# Build and run
swift run --package-path FrescoCLI fresco --help
swift run --package-path FrescoCLI fresco init --defaults
swift run --package-path FrescoCLI fresco generate
```

To test a real generation locally you need a `.env` file with valid credentials. Either run `swift run fresco init` interactively or copy `fresco.template.env` to `.env` and fill in your values.

---

## Development workflow

### Overview

Fresco uses strict TDD with a milestone-driven workflow. No code is written without a plan, no implementation is committed without a failing test first.

Every PR targets main. Main is always green.

### 1. Create a milestone

Before any code is written, create a GitHub milestone that defines the scope of work. The milestone gets a tracking issue that outlines the full scope.

### 2. Break the milestone into grouping issues

Each logical grouping (e.g. "Gemini Client", "R2 Client", "Generate Command") becomes its own GitHub issue linked to the milestone. Grouping issues contain:
- A description of what the grouping covers
- An ordered checklist of sub-issues
- Dependencies on other groupings (if any)

### 3. Break groupings into sub-issues

Each sub-issue should be small enough for an agent to complete without losing context. Guidelines:

- **One concern per issue.** A protocol, an implementation, or a mock — not all three.
- **Limit to 2-3 files.** If an issue touches more files, split it further.
- **The issue body is the complete brief.** Include the exact types, method signatures, protocols being implemented, and test expectations. Don't rely on the agent discovering context by reading the repo.
- **Reference specifics, not concepts.** "Implement `GeminiClientProtocol` with one method: `func generateImage(prompt: String) async throws -> Data`" — not "implement the Gemini client."
- **Include a definition of done checklist.** Agents work well from checklists. They work poorly from vague descriptions.

Example breakdown:

```
Milestone: Phase 1 MVP
  └── Tracking issue: Full scope outline
        └── Grouping: GeminiClient (#12)
              ├── #13: GeminiClientProtocol + tests (failing)
              ├── #14: GeminiClient implementation
              └── #15: MockGeminiClient + tests
        └── Grouping: R2Client (#16)
              ├── #17: R2ClientProtocol + tests (failing)
              ├── #18: R2Client implementation
              └── #19: MockR2Client + tests
        └── Grouping: Generate command (#20)
              └── ...
```

### 4. Branch per sub-issue

Each sub-issue gets its own branch. Naming convention:

```
issue-42/gemini-client-protocol
issue-43/gemini-client-implementation
```

### 5. Strict TDD commit order

Within each PR, commits follow this order:

1. **Failing tests first.** Commit the tests that define the expected behavior. These tests must fail (or not compile) because the implementation doesn't exist yet.
2. **Implementation.** Commit the code that makes the tests pass.

Both commits are visible in the PR history. This is enforced by convention, not tooling — reviewers (human or Copilot) should verify the commit order.

### 6. PR to main

Every PR targets main directly. No long-lived feature branches, no cascading rebases.

Sub-issues within a grouping are ordered — each one builds on what's already merged. The grouping issue checklist defines the sequence. A sub-issue is blocked until its predecessor merges.

```
main ← PR #13: GeminiClientProtocol + tests
main ← PR #14: GeminiClient implementation (after #13 merges)
main ← PR #15: MockGeminiClient (after #14 merges)
```

Main may have partially-complete features at any point, but it is always green — all tests pass, all checks pass.

### 7. Branch protections

Main has branch protections enabled. Nothing merges until:
- All CI status checks pass (macOS + Linux)
- Copilot review completes (configured, may still be in progress)

### 8. Merge and close

When a PR merges, its sub-issue closes automatically (use `Closes #42` in the PR description). When all sub-issues in a grouping are closed, close the grouping issue. When all groupings are done, close the milestone.

---

## CI

CI runs on every push to main and on all pull requests. Tests run on both macOS and Linux. Both jobs must pass before a PR can merge.

See [`template.github/workflows/ci.yml`](../template.github/workflows/ci.yml) for the template.

---

## Project structure

```
Fresco/
├── FrescoCore/
│   ├── Package.swift
│   ├── Sources/FrescoCore/
│   │   ├── Models/
│   │   │   └── GenerationResult.swift     result of a generation attempt
│   │   ├── Providers/
│   │   │   ├── GenerationProviderProtocol.swift
│   │   │   ├── DirectGenerationProvider.swift
│   │   │   ├── ServerGenerationProvider.swift
│   │   │   └── MockGenerationProvider.swift
│   │   ├── Clients/
│   │   │   ├── GeminiClient.swift         + GeminiClientProtocol
│   │   │   ├── R2Client.swift             + R2ClientProtocol
│   │   │   └── Mocks/
│   │   │       ├── MockGeminiClient.swift
│   │   │       └── MockR2Client.swift
│   │   └── Utilities/
│   └── Tests/FrescoCoreTests/
│
├── FrescoCLI/
│   ├── Package.swift                      depends on FrescoCore via path
│   ├── Sources/FrescoCLI/
│   │   ├── main.swift
│   │   ├── Commands/
│   │   │   ├── InitCommand.swift
│   │   │   └── GenerateCommand.swift
│   │   └── Utilities/
│   │       ├── GalleryWriter.swift        updates gallery.md
│   │       ├── ReadmeUpdater.swift        inserts image URL into README
│   │       └── WorkflowWriter.swift       writes .github/workflows/fresco.yml
│   └── Tests/FrescoCLITests/
│
├── FrescoDocs/                            design docs and templates
└── (root config files)
```

---

## Configuration

All configuration is via environment variables using [apple/swift-configuration](https://github.com/apple/swift-configuration). See the [CLI Reference](../docs/CLI.md) for the full list of environment variables.

Locally, copy `fresco.template.env` to `.env` and fill in your values, or run `fresco init` to generate `.env`. `.env` is gitignored.

---

## Testing

```bash
swift test --package-path FrescoCore
swift test --package-path FrescoCLI
swift test --package-path FrescoCore --filter FrescoCoreTests
swift test --package-path FrescoCore --filter DirectGenerationProviderTests
swift test --package-path FrescoCore --verbose
```

Tests use mock implementations and swift-configuration's `InMemoryProvider` — no network calls, no disk I/O, no API keys required.

### What is tested

| Suite | Covers |
|---|---|
| `DirectGenerationProviderTests` | Success path, Gemini error, R2 error |

### Adding a test

All tests use the mock pattern. Never import a production client in a test file.

```swift
func test_generate_success() async throws {
    let gemini = MockGeminiClient(behaviour: .success(Data(repeating: 0xFF, count: 64)))
    let r2     = MockR2Client()
    let provider = DirectGenerationProvider(gemini: gemini, r2: r2)

    let result = try await provider.generate(
        prompt: "test prompt",
        slug: "test",
        date: .now
    )

    XCTAssertTrue(result.succeeded)
    XCTAssertEqual(r2.uploadedKeys.count, 2)   // dated + today
}
```

---

## Adding a new command

1. Create `FrescoCLI/Sources/FrescoCLI/Commands/MyCommand.swift`
2. Implement `AsyncParsableCommand`
3. Add to the subcommands list in `main.swift`
4. Document in `docs/CLI.md`

---

## Cutting a release

1. Update the version string in `FrescoCLI/Sources/FrescoCLI/main.swift`
2. Tag the release: `git tag v1.0.0 && git push --tags`
3. Create a GitHub release from the tag
4. Update the Homebrew formula in `homebrew/fresco.rb` with the new version and SHA256
5. Push the formula to `github.com/argylebits/homebrew-fresco`

The SHA256 for the formula:
```bash
curl -L https://github.com/argylebits/Fresco/archive/refs/tags/v1.0.0.tar.gz | shasum -a 256
```

---

## Code style

- Swift 6 strict concurrency throughout — no `@unchecked Sendable` on production types
- Actors for shared mutable state
- Value types (`struct`) everywhere else
- No force unwraps (`!`) in production code paths
- Errors are typed enums, not raw strings
- No third-party HTTP clients — URLSession only
- apple/swift-configuration for all configuration — no custom config/credentials loading

---

## Contributing

Fresco is MIT licensed and welcomes contributions. Open an issue before starting significant work so we can discuss approach. The architecture doc is the right place to start for understanding how pieces fit together.
