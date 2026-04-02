import Configuration
import Foundation
import FrescoCore
import Synchronization
import Testing

@testable import FrescoCLI

struct GenerateCommandTests {
    private func uniqueSlug() -> String {
        "test-\(UUID().uuidString.prefix(8))"
    }

    @Test func command_hasCorrectConfiguration() {
        #expect(GenerateCommand.configuration.commandName == "generate")
    }

    @Test func command_parsesPromptFlag() throws {
        let cmd = try GenerateCommand.parse(["--prompt", "custom prompt"])
        #expect(cmd.prompt == "custom prompt")
    }

    @Test func command_parsesAppendFlag() throws {
        let cmd = try GenerateCommand.parse(["--append", "extra text"])
        #expect(cmd.append == "extra text")
    }

    @Test func command_parsesSlugFlag() throws {
        let cmd = try GenerateCommand.parse(["--slug", "my-slug", "--prompt", "p"])
        #expect(cmd.slug == "my-slug")
    }

    @Test func command_parsesGeminiApiKeyFlag() throws {
        let cmd = try GenerateCommand.parse(["--gemini-api-key", "key123", "--prompt", "p"])
        #expect(cmd.geminiApiKey == "key123")
    }

    @Test func run_promptFlagOverridesConfiguredPrompt() async throws {
        let slug = uniqueSlug()
        defer { try? FileManager.default.removeItem(atPath: "/tmp/\(slug)") }

        let receivedPrompt = Mutex<String?>(nil)
        var cmd = try makeCommand(
            args: ["--slug", slug, "--prompt", "override prompt"],
            config: ["frescoPrompt": "configured prompt"],
            onGenerateImage: { prompt in receivedPrompt.withLock { $0 = prompt } }
        )
        try await cmd.run()
        #expect(receivedPrompt.withLock { $0 } == "override prompt")
    }

    @Test func run_appendAddsToConfiguredPrompt() async throws {
        let slug = uniqueSlug()
        defer { try? FileManager.default.removeItem(atPath: "/tmp/\(slug)") }

        let receivedPrompt = Mutex<String?>(nil)
        var cmd = try makeCommand(
            args: ["--slug", slug, "--append", "extra text"],
            config: ["frescoPrompt": "base prompt"],
            onGenerateImage: { prompt in receivedPrompt.withLock { $0 = prompt } }
        )
        try await cmd.run()
        #expect(receivedPrompt.withLock { $0 } == "base prompt extra text")
    }

    @Test func run_usesConfiguredPromptWhenNoFlags() async throws {
        let slug = uniqueSlug()
        defer { try? FileManager.default.removeItem(atPath: "/tmp/\(slug)") }

        let receivedPrompt = Mutex<String?>(nil)
        var cmd = try makeCommand(
            args: ["--slug", slug],
            config: ["frescoPrompt": "configured prompt"],
            onGenerateImage: { prompt in receivedPrompt.withLock { $0 = prompt } }
        )
        try await cmd.run()
        #expect(receivedPrompt.withLock { $0 } == "configured prompt")
    }

    @Test func run_throwsWhenNoPromptAvailable() async throws {
        var cmd = try makeCommand(args: [], config: [:])
        await #expect(throws: FrescoError.self) {
            try await cmd.run()
        }
    }

    @Test func configKeys_resolveToExpectedEnvVarNames() {
        let config = ConfigReader(provider: EnvironmentVariablesProvider(
            environmentVariables: [
                "FRESCO_PROMPT": "test",
                "FRESCO_SLUG": "test",
                "GEMINI_API_KEY": "test",
            ]
        ))

        #expect(config.string(forKey: "frescoPrompt") == "test")
        #expect(config.string(forKey: "frescoSlug") == "test")
        #expect(config.string(forKey: "geminiApiKey") == "test")
    }

    @Test func run_slugFlagOverridesConfig() async throws {
        let flagSlug = "flag-\(uniqueSlug())"
        defer { try? FileManager.default.removeItem(atPath: "/tmp/\(flagSlug)") }

        var cmd = try makeCommand(
            args: ["--slug", flagSlug, "--prompt", "p"],
            config: ["frescoSlug": "config-slug"]
        )
        try await cmd.run()
        #expect(FileManager.default.fileExists(atPath: "/tmp/\(flagSlug)"))
    }

    // MARK: - Helpers

    private func makeCommand(
        args: [String],
        config: [AbsoluteConfigKey: ConfigValue],
        onGenerateImage: (@Sendable (String) -> Void)? = nil
    ) throws -> GenerateCommand {
        var fullConfig = config
        if fullConfig["frescoSlug"] == nil { fullConfig["frescoSlug"] = "test-slug" }

        var cmd = try GenerateCommand.parse(args)
        cmd.overrideDependencies = GenerateCommand.Dependencies(
            configReader: ConfigReader(provider: InMemoryProvider(values: fullConfig)),
            gemini: MockCLIGeminiClient(result: Data([0xFF, 0xD8]), onGenerateImage: onGenerateImage)
        )
        return cmd
    }
}
