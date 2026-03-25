import Configuration
import Foundation
import FrescoCore
import Synchronization
import Testing

@testable import FrescoCLI

struct GenerateCommandTests {
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

    @Test func run_promptFlagOverridesConfiguredPrompt() async throws {
        let receivedPrompt = Mutex<String?>(nil)
        var cmd = try makeCommand(
            args: ["--prompt", "override prompt"],
            config: ["frescoPrompt": "configured prompt"],
            onGenerateImage: { prompt in receivedPrompt.withLock { $0 = prompt } }
        )
        try await cmd.run()
        #expect(receivedPrompt.withLock { $0 } == "override prompt")
    }

    @Test func run_appendAddsToConfiguredPrompt() async throws {
        let receivedPrompt = Mutex<String?>(nil)
        var cmd = try makeCommand(
            args: ["--append", "extra text"],
            config: ["frescoPrompt": "base prompt"],
            onGenerateImage: { prompt in receivedPrompt.withLock { $0 = prompt } }
        )
        try await cmd.run()
        #expect(receivedPrompt.withLock { $0 } == "base prompt extra text")
    }

    @Test func run_usesConfiguredPromptWhenNoFlags() async throws {
        let receivedPrompt = Mutex<String?>(nil)
        var cmd = try makeCommand(
            args: [],
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

    @Test func run_appendsGalleryEntry() async throws {
        let receivedURL = Mutex<String?>(nil)
        var cmd = try makeCommand(
            args: ["--prompt", "test"],
            config: [:],
            onAppendEntry: { _, _, url in receivedURL.withLock { $0 = url } }
        )
        try await cmd.run()
        let url = receivedURL.withLock { $0 }
        #expect(url?.contains("https://example.com/test-slug/") == true)
    }

    @Test func configKeys_resolveToExpectedEnvVarNames() {
        let config = ConfigReader(provider: EnvironmentVariablesProvider(
            environmentVariables: [
                "FRESCO_PROMPT": "test",
                "FRESCO_SLUG": "test",
                "GEMINI_API_KEY": "test",
                "R2_ACCOUNT_ID": "test-account",
                "R2_ACCESS_KEY_ID": "test-access",
                "R2_SECRET_ACCESS_KEY": "test-secret",
                "R2_BUCKET": "test-bucket",
                "R2_PUBLIC_BASE_URL": "https://example.com",
            ]
        ))

        #expect(config.string(forKey: "frescoPrompt") == "test")
        #expect(config.string(forKey: "frescoSlug") == "test")
        #expect(config.string(forKey: "geminiApiKey") == "test")
        #expect(config.string(forKey: "r2.accountId") == "test-account")
        #expect(config.string(forKey: "r2.accessKeyId") == "test-access")
        #expect(config.string(forKey: "r2.secretAccessKey") == "test-secret")
        #expect(config.string(forKey: "r2.bucket") == "test-bucket")
        #expect(config.string(forKey: "r2.publicBaseUrl") == "https://example.com")
    }

    // MARK: - Helpers

    private func makeCommand(
        args: [String],
        config: [AbsoluteConfigKey: ConfigValue],
        onGenerateImage: (@Sendable (String) -> Void)? = nil,
        onAppendEntry: (@Sendable (String, String, String) -> Void)? = nil
    ) throws -> GenerateCommand {
        var fullConfig = config
        if fullConfig["frescoSlug"] == nil { fullConfig["frescoSlug"] = "test-slug" }
        if fullConfig["r2.publicBaseUrl"] == nil { fullConfig["r2.publicBaseUrl"] = "https://example.com" }

        var cmd = try GenerateCommand.parse(args)
        cmd.overrideDependencies = GenerateCommand.Dependencies(
            configReader: ConfigReader(provider: InMemoryProvider(values: fullConfig)),
            gemini: MockCLIGeminiClient(result: Data([0xFF, 0xD8]), onGenerateImage: onGenerateImage),
            r2: MockCLIR2Client(),
            galleryWriter: MockCLIGalleryWriter(onAppendEntry: onAppendEntry)
        )
        return cmd
    }
}
