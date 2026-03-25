import ArgumentParser
import Configuration
import Foundation
import Testing
@testable import FrescoCLI

@Suite(.serialized)
struct InitCommandTests {
    @Test func command_hasCorrectConfiguration() {
        #expect(InitCommand.configuration.commandName == "init")
    }

    @Test func command_parsesAllFlags() throws {
        let cmd = try InitCommand.parse([
            "--name", "Test",
            "--slug", "test",
            "--prompt", "a test prompt",
            "--schedule", "daily",
            "--schedule-hour", "8",
            "--gemini-key", "key123",
            "--r2-account-id", "acc123",
            "--r2-access-key-id", "ak123",
            "--r2-secret-access-key", "sk123",
            "--r2-bucket", "mybucket",
            "--r2-public-base-url", "https://pub.r2.dev",
            "--defaults",
            "--force"
        ])
        #expect(cmd.name == "Test")
        #expect(cmd.slug == "test")
        #expect(cmd.prompt == "a test prompt")
        #expect(cmd.schedule == "daily")
        #expect(cmd.scheduleHour == 8)
        #expect(cmd.geminiKey == "key123")
        #expect(cmd.r2AccountId == "acc123")
        #expect(cmd.r2AccessKeyId == "ak123")
        #expect(cmd.r2SecretAccessKey == "sk123")
        #expect(cmd.r2Bucket == "mybucket")
        #expect(cmd.r2PublicBaseUrl == "https://pub.r2.dev")
        #expect(cmd.defaults == true)
        #expect(cmd.force == true)
    }

    @Test func command_parsesWithNoFlags() throws {
        let cmd = try InitCommand.parse([])
        #expect(cmd.name == nil)
        #expect(cmd.slug == nil)
        #expect(cmd.prompt == nil)
        #expect(cmd.schedule == nil)
        #expect(cmd.scheduleHour == nil)
        #expect(cmd.defaults == false)
        #expect(cmd.force == false)
    }

    @Test func run_writesEnvFile() async throws {
        try await inTmpDir { dir in
            var cmd = try makeCommand()
            try await cmd.run()

            let env = try String(contentsOfFile: dir + "/.env", encoding: .utf8)
            #expect(env.contains("FRESCO_PROMPT=test prompt"))
            #expect(env.contains("FRESCO_SLUG=test-slug"))
            #expect(env.contains("GEMINI_API_KEY=gkey"))
            #expect(env.contains("R2_BUCKET=bucket"))

            let attrs = try FileManager.default.attributesOfItem(atPath: dir + "/.env")
            let permissions = attrs[.posixPermissions] as? Int
            #expect(permissions == 0o600)
        }
    }

    @Test func run_writesWorkflowFile() async throws {
        try await inTmpDir { dir in
            var cmd = try makeCommand()
            try await cmd.run()

            let workflow = try String(contentsOfFile: dir + "/.github/workflows/fresco.yml", encoding: .utf8)
            #expect(workflow.contains("cron:"))
            #expect(workflow.contains("0 8 * * *"))
        }
    }

    @Test func run_createsGalleryFile() async throws {
        try await inTmpDir { dir in
            var cmd = try makeCommand()
            try await cmd.run()

            let gallery = try String(contentsOfFile: dir + "/gallery.md", encoding: .utf8)
            #expect(gallery.contains("# Test Project Gallery"))
            #expect(gallery.contains("<!-- Fresco appends new entries below this line on each generation -->"))
        }
    }

    @Test func run_updatesReadmeIfExists() async throws {
        try await inTmpDir { dir in
            try "# Test Project\n".write(toFile: dir + "/README.md", atomically: true, encoding: .utf8)

            var cmd = try makeCommand()
            try await cmd.run()

            let readme = try String(contentsOfFile: dir + "/README.md", encoding: .utf8)
            #expect(readme.contains("<!-- Fresco image -->"))
            #expect(readme.contains("![Fresco](https://pub.r2.dev/test-slug/today.jpg)"))
        }
    }

    @Test func run_failsWhenEnvExistsWithoutForce() async throws {
        try await inTmpDir { dir in
            try "existing".write(toFile: dir + "/.env", atomically: true, encoding: .utf8)

            var cmd = try makeCommand()
            await #expect(throws: ExitCode.self) {
                try await cmd.run()
            }
        }
    }

    @Test func run_overwritesEnvWithForce() async throws {
        try await inTmpDir { dir in
            try "old content".write(toFile: dir + "/.env", atomically: true, encoding: .utf8)

            var cmd = try makeCommand(extraFlags: ["--force"])
            try await cmd.run()

            let env = try String(contentsOfFile: dir + "/.env", encoding: .utf8)
            #expect(env.contains("FRESCO_SLUG=test-slug"))
        }
    }

    @Test func run_skipsWorkflowWithoutForce() async throws {
        try await inTmpDir { dir in
            let workflowDir = dir + "/.github/workflows"
            try FileManager.default.createDirectory(atPath: workflowDir, withIntermediateDirectories: true)
            try "existing workflow".write(toFile: workflowDir + "/fresco.yml", atomically: true, encoding: .utf8)

            var cmd = try makeCommand()
            try await cmd.run()

            let workflow = try String(contentsOfFile: workflowDir + "/fresco.yml", encoding: .utf8)
            #expect(workflow == "existing workflow")
        }
    }

    @Test func run_envFileRoundTrips_throughConfigReader() async throws {
        try await inTmpDir { dir in
            var cmd = try makeCommand(extraFlags: [
                "--prompt", "Generate a hero banner image in 4:1 aspect ratio. It should be of a fresco like you'd see around the central Texas area. Make sure it looks authentically and unapologetically central Texan.",
                "--gemini-key", "AIzaSyB-test-key_123",
            ])
            try await cmd.run()

            let provider = try await EnvironmentVariablesProvider(environmentFilePath: ".env")
            let config = ConfigReader(provider: provider)

            #expect(config.string(forKey: "geminiApiKey") == "AIzaSyB-test-key_123")
            #expect(config.string(forKey: "frescoSlug") == "test-slug")
            #expect(config.string(forKey: "frescoPrompt")?.hasPrefix("Generate a hero banner") == true)
            #expect(config.string(forKey: "r2.bucket") == "bucket")
            #expect(config.string(forKey: "r2.publicBaseUrl") == "https://pub.r2.dev")
        }
    }

    @Test func run_envValues_noLiteralQuotes() async throws {
        try await inTmpDir { dir in
            var cmd = try makeCommand()
            try await cmd.run()

            let env = try String(contentsOfFile: dir + "/.env", encoding: .utf8)
            #expect(!env.contains("=\""))
            #expect(!env.contains("\"\n"))
        }
    }

    @Test func run_promptWithSpecialCharacters_survivesRoundTrip() async throws {
        let prompt = "A fresco like you'd see in central Texas, tagged with graffiti art that says \"Fresco\". Include elements & themes from the current month."
        try await inTmpDir { dir in
            var cmd = try makeCommand(extraFlags: ["--prompt", prompt])
            try await cmd.run()

            let provider = try await EnvironmentVariablesProvider(environmentFilePath: ".env")
            let config = ConfigReader(provider: provider)

            #expect(config.string(forKey: "frescoPrompt") == prompt)
        }
    }

    // MARK: - Helpers

    private func makeCommand(extraFlags: [String] = []) throws -> InitCommand {
        var flags = [
            "--name", "Test Project",
            "--slug", "test-slug",
            "--prompt", "test prompt",
            "--schedule", "daily",
            "--schedule-hour", "8",
            "--gemini-key", "gkey",
            "--r2-account-id", "acc",
            "--r2-access-key-id", "ak",
            "--r2-secret-access-key", "sk",
            "--r2-bucket", "bucket",
            "--r2-public-base-url", "https://pub.r2.dev",
            "--defaults",
        ]
        flags.append(contentsOf: extraFlags)
        return try InitCommand.parse(flags)
    }

    private func inTmpDir(_ body: (String) async throws -> Void) async throws {
        let dir = NSTemporaryDirectory() + "fresco-init-\(UUID().uuidString)"
        try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        let originalDir = FileManager.default.currentDirectoryPath
        FileManager.default.changeCurrentDirectoryPath(dir)
        defer {
            FileManager.default.changeCurrentDirectoryPath(originalDir)
            try? FileManager.default.removeItem(atPath: dir)
        }
        try await body(dir)
    }
}
