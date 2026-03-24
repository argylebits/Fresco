import Testing
@testable import FrescoCLI

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
}
