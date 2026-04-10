import Configuration
import Foundation
import FrescoCore
import Synchronization
import Testing

@testable import FrescoCLI

struct UploadCommandTests {
    private static let testImageData = Data([0xFF, 0xD8, 0xFF, 0xE0])

    private func writeTempFile() throws -> (String, String) {
        let slug = "test-upload-\(UUID().uuidString.prefix(8))"
        let dir = "/tmp/\(slug)"
        try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        let filePath = "\(dir)/2025-01-01-000000.jpg"
        try Self.testImageData.write(to: URL(fileURLWithPath: filePath))
        return (filePath, slug)
    }

    @Test func command_hasCorrectConfiguration() {
        #expect(UploadCommand.configuration.commandName == "upload")
    }

    @Test func command_parsesFilePathArgument() throws {
        let cmd = try UploadCommand.parse(["/tmp/test/image.jpg"])
        #expect(cmd.filePath == "/tmp/test/image.jpg")
    }

    @Test func command_parsesSlugFlag() throws {
        let cmd = try UploadCommand.parse(["/tmp/test/image.jpg", "--slug", "my-slug"])
        #expect(cmd.slug == "my-slug")
    }

    @Test func command_parsesR2Flags() throws {
        let cmd = try UploadCommand.parse([
            "/tmp/test/image.jpg",
            "--r2-account-id", "acct",
            "--r2-access-key-id", "akid",
            "--r2-secret-access-key", "sak",
            "--r2-bucket", "mybucket",
            "--r2-public-base-url", "https://cdn.example.com",
        ])
        #expect(cmd.r2AccountId == "acct")
        #expect(cmd.r2AccessKeyId == "akid")
        #expect(cmd.r2SecretAccessKey == "sak")
        #expect(cmd.r2Bucket == "mybucket")
        #expect(cmd.r2PublicBaseUrl == "https://cdn.example.com")
    }

    @Test func run_uploadsFileAndPrintsURL() async throws {
        let (filePath, tmpSlug) = try writeTempFile()
        defer { try? FileManager.default.removeItem(atPath: "/tmp/\(tmpSlug)") }

        var cmd = try UploadCommand.parse([filePath])
        cmd.overrideDependencies = UploadCommand.Dependencies(
            configReader: ConfigReader(provider: InMemoryProvider(values: [
                "frescoSlug": "test-slug",
                "r2.publicBaseUrl": "https://cdn.example.com",
            ])),
            r2: MockCLIR2Client()
        )
        try await cmd.run()
    }

    @Test func run_slugFlagOverridesConfig() async throws {
        let (filePath, tmpSlug) = try writeTempFile()
        defer { try? FileManager.default.removeItem(atPath: "/tmp/\(tmpSlug)") }

        let receivedKey = Mutex<String?>(nil)
        var cmd = try UploadCommand.parse([filePath, "--slug", "flag-slug"])
        cmd.overrideDependencies = UploadCommand.Dependencies(
            configReader: ConfigReader(provider: InMemoryProvider(values: [
                "frescoSlug": "config-slug",
                "r2.publicBaseUrl": "https://cdn.example.com",
            ])),
            r2: MockCLIR2Client(onUpload: { _, key, _, _ in
                receivedKey.withLock { $0 = key }
            })
        )
        try await cmd.run()
        #expect(receivedKey.withLock { $0 }?.hasPrefix("flag-slug/") == true)
    }

    @Test func command_parsesDestinationFilename() throws {
        let cmd = try UploadCommand.parse(["/tmp/test/image.jpg", "latest.jpg"])
        #expect(cmd.filePath == "/tmp/test/image.jpg")
        #expect(cmd.destinationFilename == "latest.jpg")
    }

    @Test func command_destinationFilenameDefaultsToNil() throws {
        let cmd = try UploadCommand.parse(["/tmp/test/image.jpg"])
        #expect(cmd.destinationFilename == nil)
    }

    @Test func run_usesDestinationFilenameInR2Key() async throws {
        let (filePath, tmpSlug) = try writeTempFile()
        defer { try? FileManager.default.removeItem(atPath: "/tmp/\(tmpSlug)") }

        let receivedKey = Mutex<String?>(nil)
        var cmd = try UploadCommand.parse([filePath, "latest.jpg"])
        cmd.overrideDependencies = UploadCommand.Dependencies(
            configReader: ConfigReader(provider: InMemoryProvider(values: [
                "frescoSlug": "test-slug",
                "r2.publicBaseUrl": "https://cdn.example.com",
            ])),
            r2: MockCLIR2Client(onUpload: { _, key, _, _ in
                receivedKey.withLock { $0 = key }
            })
        )
        try await cmd.run()
        #expect(receivedKey.withLock { $0 } == "test-slug/latest.jpg")
    }

    @Test func command_parsesCacheControlFlag() throws {
        let cmd = try UploadCommand.parse([
            "/tmp/test/image.jpg", "--cache-control", "public, max-age=300",
        ])
        #expect(cmd.cacheControl == "public, max-age=300")
    }

    @Test func command_cacheControlDefaultsToNil() throws {
        let cmd = try UploadCommand.parse(["/tmp/test/image.jpg"])
        #expect(cmd.cacheControl == nil)
    }

    @Test func run_passesCacheControlToService() async throws {
        let (filePath, tmpSlug) = try writeTempFile()
        defer { try? FileManager.default.removeItem(atPath: "/tmp/\(tmpSlug)") }

        let receivedCacheControl = Mutex<String?>(nil)
        var cmd = try UploadCommand.parse([
            filePath, "--cache-control", "public, max-age=300",
        ])
        cmd.overrideDependencies = UploadCommand.Dependencies(
            configReader: ConfigReader(provider: InMemoryProvider(values: [
                "frescoSlug": "test-slug",
                "r2.publicBaseUrl": "https://cdn.example.com",
            ])),
            r2: MockCLIR2Client(onUpload: { _, _, _, cacheControl in
                receivedCacheControl.withLock { $0 = cacheControl }
            })
        )
        try await cmd.run()
        #expect(receivedCacheControl.withLock { $0 } == "public, max-age=300")
    }

    @Test func run_throwsWhenSlugMissing() async throws {
        let (filePath, tmpSlug) = try writeTempFile()
        defer { try? FileManager.default.removeItem(atPath: "/tmp/\(tmpSlug)") }

        var cmd = try UploadCommand.parse([filePath])
        cmd.overrideDependencies = UploadCommand.Dependencies(
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
        let (filePath, tmpSlug) = try writeTempFile()
        defer { try? FileManager.default.removeItem(atPath: "/tmp/\(tmpSlug)") }

        var cmd = try UploadCommand.parse([filePath])
        cmd.overrideDependencies = UploadCommand.Dependencies(
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
