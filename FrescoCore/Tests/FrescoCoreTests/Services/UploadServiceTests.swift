import Foundation
import Synchronization
import Testing

@testable import FrescoCore

@Suite("UploadService")
struct UploadServiceTests {
    private static let testJpegData = Data([0xFF, 0xD8, 0xFF, 0xE0])
    private static let testPngData = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
    private static let testSlug = "my-wallpaper"
    private static let testPublicBaseURL = "https://cdn.example.com"

    private func writeTempFile(
        data: Data = testJpegData,
        slug: String? = nil,
        filename: String = "2025-01-01-000000.jpg"
    ) throws -> (String, String) {
        let slug = slug ?? "test-upload-\(UUID().uuidString.prefix(8))"
        let dir = "/tmp/\(slug)"
        try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        let filePath = "\(dir)/\(filename)"
        try data.write(to: URL(fileURLWithPath: filePath))
        return (filePath, slug)
    }

    @Test("upload sends data to R2 with correct key")
    func uploadSendsCorrectKey() async throws {
        let (filePath, tmpSlug) = try writeTempFile()
        defer { try? FileManager.default.removeItem(atPath: "/tmp/\(tmpSlug)") }

        let receivedKey = Mutex<String?>(nil)
        let r2 = MockR2Client(onUpload: { _, key, _, _ in
            receivedKey.withLock { $0 = key }
        })

        let service = UploadService(r2: r2, publicBaseURL: Self.testPublicBaseURL)

        _ = try await service.upload(
            filePath: filePath,
            slug: Self.testSlug
        )

        #expect(receivedKey.withLock { $0 } == "my-wallpaper/2025-01-01-000000.jpg")
    }

    @Test("upload returns correct public URL")
    func uploadReturnsPublicURL() async throws {
        let (filePath, tmpSlug) = try writeTempFile()
        defer { try? FileManager.default.removeItem(atPath: "/tmp/\(tmpSlug)") }

        let service = UploadService(
            r2: MockR2Client(),
            publicBaseURL: Self.testPublicBaseURL
        )

        let result = try await service.upload(
            filePath: filePath,
            slug: Self.testSlug
        )

        #expect(result.publicURL == URL(string: "https://cdn.example.com/my-wallpaper/2025-01-01-000000.jpg")!)
        #expect(result.r2Key == "my-wallpaper/2025-01-01-000000.jpg")
    }

    @Test("upload sends image/jpeg content type for JPEG data")
    func uploadSendsJpegContentType() async throws {
        let (filePath, tmpSlug) = try writeTempFile(data: Self.testJpegData)
        defer { try? FileManager.default.removeItem(atPath: "/tmp/\(tmpSlug)") }

        let receivedContentType = Mutex<String?>(nil)
        let r2 = MockR2Client(onUpload: { _, _, contentType, _ in
            receivedContentType.withLock { $0 = contentType }
        })

        let service = UploadService(r2: r2, publicBaseURL: Self.testPublicBaseURL)

        _ = try await service.upload(filePath: filePath, slug: Self.testSlug)

        #expect(receivedContentType.withLock { $0 } == "image/jpeg")
    }

    @Test("upload sends image/png content type for PNG data")
    func uploadSendsPngContentType() async throws {
        let (filePath, tmpSlug) = try writeTempFile(data: Self.testPngData, filename: "2025-01-01-000000.png")
        defer { try? FileManager.default.removeItem(atPath: "/tmp/\(tmpSlug)") }

        let receivedContentType = Mutex<String?>(nil)
        let r2 = MockR2Client(onUpload: { _, _, contentType, _ in
            receivedContentType.withLock { $0 = contentType }
        })

        let service = UploadService(r2: r2, publicBaseURL: Self.testPublicBaseURL)

        _ = try await service.upload(filePath: filePath, slug: Self.testSlug)

        #expect(receivedContentType.withLock { $0 } == "image/png")
    }

    @Test("upload throws when R2 fails")
    func uploadThrowsOnR2Error() async throws {
        let (filePath, tmpSlug) = try writeTempFile()
        defer { try? FileManager.default.removeItem(atPath: "/tmp/\(tmpSlug)") }

        let service = UploadService(
            r2: MockR2Client(shouldThrow: .r2UploadError("upload failed")),
            publicBaseURL: Self.testPublicBaseURL
        )

        await #expect(throws: FrescoError.self) {
            try await service.upload(
                filePath: filePath,
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

    @Test("upload throws on invalid publicBaseURL without uploading")
    func uploadThrowsOnInvalidBaseURL() async throws {
        let (filePath, tmpSlug) = try writeTempFile()
        defer { try? FileManager.default.removeItem(atPath: "/tmp/\(tmpSlug)") }

        let uploadCalled = Mutex(false)
        let r2 = MockR2Client(onUpload: { _, _, _, _ in
            uploadCalled.withLock { $0 = true }
        })

        let service = UploadService(r2: r2, publicBaseURL: "")

        await #expect(throws: FrescoError.self) {
            try await service.upload(
                filePath: filePath,
                slug: Self.testSlug
            )
        }

        #expect(uploadCalled.withLock { $0 } == false)
    }

    @Test("upload throws on invalid slug")
    func uploadThrowsOnInvalidSlug() async throws {
        let (filePath, tmpSlug) = try writeTempFile()
        defer { try? FileManager.default.removeItem(atPath: "/tmp/\(tmpSlug)") }

        let service = UploadService(
            r2: MockR2Client(),
            publicBaseURL: Self.testPublicBaseURL
        )

        await #expect(throws: FrescoError.self) {
            try await service.upload(
                filePath: filePath,
                slug: "../etc"
            )
        }
    }
}
