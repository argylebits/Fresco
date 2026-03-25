import Configuration
import Foundation
import FrescoCore
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

    @Test func run_usesPromptFlag() async throws {
        var cmd = try makeCommand(args: ["--prompt", "override prompt"], config: [
            "frescoPrompt": "configured prompt",
        ])
        try await cmd.run()
    }

    @Test func run_appendsToConfiguredPrompt() async throws {
        var cmd = try makeCommand(args: ["--append", "extra text"], config: [
            "frescoPrompt": "base prompt",
        ])
        try await cmd.run()
    }

    @Test func run_usesConfiguredPromptWhenNoFlags() async throws {
        var cmd = try makeCommand(args: [], config: [
            "frescoPrompt": "configured prompt",
        ])
        try await cmd.run()
    }

    @Test func run_throwsWhenNoPromptAvailable() async throws {
        var cmd = try makeCommand(args: [], config: [:])
        await #expect(throws: FrescoError.self) {
            try await cmd.run()
        }
    }

    @Test func run_printsPublicURL() async throws {
        var cmd = try makeCommand(args: ["--prompt", "test"], config: [:])
        try await cmd.run()
    }

    // MARK: - Helpers

    private func makeCommand(
        args: [String],
        config: [AbsoluteConfigKey: ConfigValue]
    ) throws -> GenerateCommand {
        var fullConfig = config
        if fullConfig["frescoSlug"] == nil { fullConfig["frescoSlug"] = "test-slug" }
        if fullConfig["r2PublicBaseUrl"] == nil { fullConfig["r2PublicBaseUrl"] = "https://example.com" }

        var cmd = try GenerateCommand.parse(args)
        cmd.overrideConfigReader = ConfigReader(provider: InMemoryProvider(values: fullConfig))
        cmd.overrideGemini = MockCLIGeminiClient(result: Data([0xFF, 0xD8]))
        cmd.overrideR2 = MockCLIR2Client()
        cmd.overrideGalleryWriter = MockCLIGalleryWriter()
        return cmd
    }
}
