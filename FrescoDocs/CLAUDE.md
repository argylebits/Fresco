# CLAUDE.md

## Project

- **Name:** Fresco
- **Repo:** github.com/argylebits/Fresco
- **Language:** Swift 6
- **Platforms:** macOS 26+, Linux

## Workflow rules

- **Strict TDD.** Tests are committed before implementation — always in separate commits within the same PR.
- **Every PR targets main.** No long-lived feature branches.
- **Branch naming:** `issue-{number}/short-description`
- **PR description must include** `Closes #XX` to auto-close the sub-issue.
- **Branch protections are enabled.** All CI checks must pass before merge.
- **CI runs on macOS and Linux.** Both must pass.

## Agent guidelines

- **Read the issue body completely before starting.** The issue body is your complete brief.
- **Do not explore the repo to discover context.** Everything you need is in the issue. If it's not, stop and ask.
- **One concern per PR.** Do not combine unrelated changes.
- **Commit order matters.** Failing tests first, then implementation.
- **Do not modify files outside the scope of your issue.** If you find something that needs fixing elsewhere, open a new issue.
- **Do not add comments, docstrings, or type annotations to code you didn't change.**
- **Do not refactor surrounding code.** Stay focused on the issue.

## Code style

- Swift 6 strict concurrency — no `@unchecked Sendable` on production types
- Actors for shared mutable state
- Value types (`struct`) everywhere else
- No force unwraps (`!`) in production code
- Errors are typed enums, not raw strings
- No third-party HTTP clients — URLSession only
- apple/swift-configuration for all configuration — no custom config/credentials loading

## Testing

- All external dependencies are behind protocols
- Tests use mock implementations and swift-configuration's `InMemoryProvider`
- No network calls, no disk I/O, no API keys required in tests
- Never import a production client in a test file

## Configuration

- All config via environment variables (swift-configuration `EnvironmentVariablesProvider`)
- `.env` locally (gitignored), GitHub Actions secrets in CI
- See `fresco.template.env` for the full variable list

## Credentials

- Never commit secrets, API keys, or credentials
- `.env` is gitignored
- In CI, secrets come from GitHub Actions secrets

## Key docs

- Product docs: `docs/`
- Agent workspace: `AGENTS/`
- Implementation brief: `AGENTS/AGENT_HANDOFF.md`
- Architecture: `docs/ARCHITECTURE.md`
- Internal toolchain: `AGENTS/TOOLCHAIN.md`
