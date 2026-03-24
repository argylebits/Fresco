import Foundation
import Testing

@testable import FrescoCore

struct MockR2ClientTests {
    @Test func upload_succeeds() async throws {
        let mock = MockR2Client()
        try await mock.upload(
            data: Data([0x01]), key: "test/image.jpg", contentType: "image/jpeg",
            cacheControl: "public, max-age=3600")
    }

    @Test func upload_throwsWhenConfigured() async {
        let mock = MockR2Client(shouldThrow: .r2UploadError("upload failed"))
        await #expect(throws: FrescoError.self) {
            try await mock.upload(
                data: Data([0x01]), key: "test/image.jpg", contentType: "image/jpeg",
                cacheControl: "public, max-age=3600")
        }
    }
}
