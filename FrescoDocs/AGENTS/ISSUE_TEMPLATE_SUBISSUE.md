---
name: Sub-Issue
about: A single unit of work — one concern, one branch, one PR
labels: sub-issue
---

## Parent

Grouping: #XX

## What to implement

[Exact description. Include type names, method signatures, file paths. Everything the agent needs without reading the repo.]

## Files to create or modify

- `FrescoCore/Sources/FrescoCore/SomeFile.swift` — [what goes here]

## Types and signatures

```swift
// Exact protocol or struct definition
protocol SomeProtocol: Sendable {
    func doThing(input: String) async throws -> Output
}
```

## Test expectations

```swift
// Exact test cases to write
func test_doThing_success() async throws { ... }
func test_doThing_invalidInput_throws() async throws { ... }
```

## Definition of done

- [ ] Failing tests committed first
- [ ] Implementation committed second
- [ ] `swift build` succeeds
- [ ] `swift test` passes (macOS + Linux)
- [ ] PR opened with `Closes #XX`
