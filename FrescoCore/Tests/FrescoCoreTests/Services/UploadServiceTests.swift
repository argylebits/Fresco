import Foundation
import Synchronization
import Testing

@testable import FrescoCore

@Suite("UploadService")
struct UploadServiceTests {
    private static let testImageData = Data([0xFF, 0xD8, 0xFF, 0xE0])
    private static let testSlug = "my-wallpaper"
    private static let testPublicBaseURL = "https://cdn.example.com"

    @Test("upload sends data to R2 with correct key")
    func uploadSendsCorrectKey() async throws {
        let receivedKey = Mutex<String?>(nil)
        let r2 = MockR2Client(onUpload: { _, key in
            receivedKey.withLock { $0 = key }
        })

        let service = UploadService(r2: r2, publicBaseURL: Self.testPublicBaseURL)

        _ = try await service.upload(
            filePath: "/tmp/my-wallpaper/2025-01-01-000000.jpg",
            slug: Self.testSlug
        )

        #expect(receivedKey.withLock { $0 } == "my-wallpaper/2025-01-01-000000.jpg")
    }

    @Test("upload returns correct public URL")
    func uploadReturnsPublicURL() async throws {
        let service = UploadService(
            r2: MockR2Client(),
            publicBaseURL: Self.testPublicBaseURL
        )

        let result = try await service.upload(
            filePath: "/tmp/my-wallpaper/2025-01-01-000000.jpg",
            slug: Self.testSlug
        )

        #expect(result.publicURL == URL(string: "https://cdn.example.com/my-wallpaper/2025-01-01-000000.jpg")!)
        #expect(result.r2Key == "my-wallpaper/2025-01-01-000000.jpg")
    }

    @Test("upload throws when R2 fails")
    func uploadThrowsOnR2Error() async {
        let service = UploadService(
            r2: MockR2Client(shouldThrow: .r2UploadError("upload failed")),
            publicBaseURL: Self.testPublicBaseURL
        )

        await #expect(throws: FrescoError.self) {
            try await service.upload(
                filePath: "/tmp/my-wallpaper/2025-01-01-000000.jpg",
                slug: Self.testSlug
            )
        }
    }

    @Test("upload throws when file does not exist")
    func uploadThrowsOnMissingFile() async {
        let service = UploadService(
            r2: MockR2Client(),
            publicBaseURL: Self.testPublicBaseURL
        )

        await #expect(throws: FrescoError.self) {
            try await service.upload(
                filePath: "/tmp/nonexistent-\(UUID().uuidString)/image.jpg",
                slug: Self.testSlug
            )
        }
    }

    @Test("upload throws on invalid publicBaseURL")
    func uploadThrowsOnInvalidBaseURL() async {
        let service = UploadService(
            r2: MockR2Client(),
            publicBaseURL: ""
        )

        await #expect(throws: FrescoError.self) {
            try await service.upload(
                filePath: "/tmp/my-wallpaper/2025-01-01-000000.jpg",
                slug: Self.testSlug
            )
        }
    }
}
