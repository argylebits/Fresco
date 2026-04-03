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
