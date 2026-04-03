import Configuration
import Foundation
import FrescoCore
import Synchronization
import Testing

@testable import FrescoCLI

struct RemoteCopyCommandTests {
    @Test func command_hasCorrectConfiguration() {
        #expect(RemoteCopyCommand.configuration.commandName == "copy")
    }

    @Test func command_parsesSourceAndDestination() throws {
        let cmd = try RemoteCopyCommand.parse(["2026-04-02-150000.jpg", "latest.jpg"])
        #expect(cmd.sourceFilename == "2026-04-02-150000.jpg")
        #expect(cmd.destinationFilename == "latest.jpg")
    }

    @Test func command_parsesSlugFlag() throws {
        let cmd = try RemoteCopyCommand.parse(["source.jpg", "dest.jpg", "--slug", "my-slug"])
        #expect(cmd.slug == "my-slug")
    }

    @Test func command_parsesR2Flags() throws {
        let cmd = try RemoteCopyCommand.parse([
            "source.jpg",
            "dest.jpg",
            "--r2-account-id", "account-id",
            "--r2-access-key-id", "access-key-id",
            "--r2-secret-access-key", "secret-access-key",
            "--r2-bucket", "bucket-name",
            "--r2-public-base-url", "https://cdn.example.com",
        ])
        #expect(cmd.r2AccountId == "account-id")
        #expect(cmd.r2AccessKeyId == "access-key-id")
        #expect(cmd.r2SecretAccessKey == "secret-access-key")
        #expect(cmd.r2Bucket == "bucket-name")
        #expect(cmd.r2PublicBaseUrl == "https://cdn.example.com")
    }

    @Test func run_copiesAndPrintsURL() async throws {
        let receivedSourceKey = Mutex<String?>(nil)
        let receivedDestinationKey = Mutex<String?>(nil)
        var cmd = try RemoteCopyCommand.parse(["2026-04-02-150000.jpg", "latest.jpg"])
        cmd.overrideDependencies = RemoteCopyCommand.Dependencies(
            configReader: ConfigReader(provider: InMemoryProvider(values: [
                "frescoSlug": "test-slug",
                "r2.publicBaseUrl": "https://cdn.example.com",
            ])),
            r2: MockCLIR2Client(onCopy: { source, destination in
                receivedSourceKey.withLock { $0 = source }
                receivedDestinationKey.withLock { $0 = destination }
            })
        )
        try await cmd.run()
        #expect(receivedSourceKey.withLock { $0 } == "test-slug/2026-04-02-150000.jpg")
        #expect(receivedDestinationKey.withLock { $0 } == "test-slug/latest.jpg")
    }

    @Test func run_slugFlagOverridesConfig() async throws {
        let receivedSourceKey = Mutex<String?>(nil)
        var cmd = try RemoteCopyCommand.parse(["source.jpg", "dest.jpg", "--slug", "flag-slug"])
        cmd.overrideDependencies = RemoteCopyCommand.Dependencies(
            configReader: ConfigReader(provider: InMemoryProvider(values: [
                "frescoSlug": "config-slug",
                "r2.publicBaseUrl": "https://cdn.example.com",
            ])),
            r2: MockCLIR2Client(onCopy: { source, _ in
                receivedSourceKey.withLock { $0 = source }
            })
        )
        try await cmd.run()
        #expect(receivedSourceKey.withLock { $0 }?.hasPrefix("flag-slug/") == true)
    }

    @Test func run_throwsWhenSlugMissing() async throws {
        var cmd = try RemoteCopyCommand.parse(["source.jpg", "dest.jpg"])
        cmd.overrideDependencies = RemoteCopyCommand.Dependencies(
            configReader: ConfigReader(provider: InMemoryProvider(values: [
                "r2.publicBaseUrl": "https://cdn.example.com",
            ])),
            r2: MockCLIR2Client()
        )
        await #expect(throws: FrescoError.self) {
            try await cmd.run()
        }
    }

    @Test func run_throwsWhenPublicBaseUrlMissing() async throws {
        var cmd = try RemoteCopyCommand.parse(["source.jpg", "dest.jpg"])
        cmd.overrideDependencies = RemoteCopyCommand.Dependencies(
            configReader: ConfigReader(provider: InMemoryProvider(values: [
                "frescoSlug": "test-slug",
            ])),
            r2: MockCLIR2Client()
        )
        await #expect(throws: FrescoError.self) {
            try await cmd.run()
        }
    }
}
