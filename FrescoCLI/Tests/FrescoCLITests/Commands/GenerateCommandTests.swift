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

    // MARK: - Flag parsing

    @Test func command_parsesSlugFlag() throws {
        let cmd = try GenerateCommand.parse(["--slug", "my-slug", "--prompt", "p"])
        #expect(cmd.slug == "my-slug")
    }

    @Test func command_parsesGeminiApiKeyFlag() throws {
        let cmd = try GenerateCommand.parse(["--gemini-api-key", "key123", "--prompt", "p"])
        #expect(cmd.geminiApiKey == "key123")
    }

    @Test func command_parsesR2AccountIdFlag() throws {
        let cmd = try GenerateCommand.parse(["--r2-account-id", "acct", "--prompt", "p"])
        #expect(cmd.r2AccountId == "acct")
    }

    @Test func command_parsesR2AccessKeyIdFlag() throws {
        let cmd = try GenerateCommand.parse(["--r2-access-key-id", "akid", "--prompt", "p"])
        #expect(cmd.r2AccessKeyId == "akid")
    }

    @Test func command_parsesR2SecretAccessKeyFlag() throws {
        let cmd = try GenerateCommand.parse(["--r2-secret-access-key", "sak", "--prompt", "p"])
        #expect(cmd.r2SecretAccessKey == "sak")
    }

    @Test func command_parsesR2BucketFlag() throws {
        let cmd = try GenerateCommand.parse(["--r2-bucket", "mybucket", "--prompt", "p"])
        #expect(cmd.r2Bucket == "mybucket")
    }

    @Test func command_parsesR2PublicBaseUrlFlag() throws {
        let cmd = try GenerateCommand.parse(["--r2-public-base-url", "https://cdn.example.com", "--prompt", "p"])
        #expect(cmd.r2PublicBaseUrl == "https://cdn.example.com")
    }

    @Test func command_parsesDryRunFlag() throws {
        let cmd = try GenerateCommand.parse(["--dry-run", "--prompt", "p"])
        #expect(cmd.dryRun == true)
    }

    @Test func command_dryRunDefaultsToFalse() throws {
        let cmd = try GenerateCommand.parse(["--prompt", "p"])
        #expect(cmd.dryRun == false)
    }

    // MARK: - Flag precedence

    @Test func run_slugFlagOverridesConfig() async throws {
        let receivedKey = Mutex<String?>(nil)
        var cmd = try makeCommand(
            args: ["--slug", "flag-slug", "--prompt", "p"],
            config: ["frescoSlug": "config-slug"],
            onUpload: { _, key in receivedKey.withLock { $0 = key } }
        )
        try await cmd.run()
        let key = receivedKey.withLock { $0 }
        #expect(key?.hasPrefix("flag-slug/") == true)
    }

    @Test func run_r2PublicBaseUrlFlagOverridesConfig() async throws {
        var cmd = try makeCommand(
            args: ["--r2-public-base-url", "https://cdn.flag.com", "--prompt", "p"],
            config: ["r2.publicBaseUrl": "https://cdn.config.com"]
        )
        try await cmd.run()
    }

    // MARK: - Dry run

    @Test func run_dryRunGeneratesButDoesNotUpload() async throws {
        let geminiCalled = Mutex(false)
        let r2Called = Mutex(false)
        var cmd = try makeCommand(
            args: ["--dry-run", "--prompt", "p"],
            config: [:],
            onGenerateImage: { _ in geminiCalled.withLock { $0 = true } },
            onUpload: { _, _ in r2Called.withLock { $0 = true } }
        )
        try await cmd.run()
        #expect(geminiCalled.withLock { $0 } == true)
        #expect(r2Called.withLock { $0 } == false)
    }

    @Test func run_dryRunDoesNotRequireR2Config() async throws {
        var cmd = try makeCommand(
            args: ["--dry-run", "--prompt", "p"],
            config: ["frescoSlug": "test-slug"],
            omitR2PublicBaseUrl: true
        )
        try await cmd.run()
    }

    // MARK: - Helpers

    private func makeCommand(
        args: [String],
        config: [AbsoluteConfigKey: ConfigValue],
        omitR2PublicBaseUrl: Bool = false,
        onGenerateImage: (@Sendable (String) -> Void)? = nil,
        onUpload: (@Sendable (Data, String) -> Void)? = nil
    ) throws -> GenerateCommand {
        var fullConfig = config
        if fullConfig["frescoSlug"] == nil { fullConfig["frescoSlug"] = "test-slug" }
        if !omitR2PublicBaseUrl && fullConfig["r2.publicBaseUrl"] == nil {
            fullConfig["r2.publicBaseUrl"] = "https://example.com"
        }

        var cmd = try GenerateCommand.parse(args)
        cmd.overrideDependencies = GenerateCommand.Dependencies(
            configReader: ConfigReader(provider: InMemoryProvider(values: fullConfig)),
            gemini: MockCLIGeminiClient(result: Data([0xFF, 0xD8]), onGenerateImage: onGenerateImage),
            r2: MockCLIR2Client(onUpload: onUpload)
        )
        return cmd
    }
}
