import Foundation
import Testing

@testable import FrescoCore

struct MockR2ClientTests {
    @Test func upload_tracksKey() async throws {
        let mock = MockR2Client()
        try await mock.upload(
            data: Data([0x01]), key: "test/image.jpg", contentType: "image/jpeg",
            cacheControl: "public, max-age=3600")
        #expect(mock.uploadedKeys == ["test/image.jpg"])
    }

    @Test func upload_tracksData() async throws {
        let data = Data([0x01, 0x02])
        let mock = MockR2Client()
        try await mock.upload(
            data: data, key: "test/image.jpg", contentType: "image/jpeg",
            cacheControl: "public, max-age=3600")
        #expect(mock.uploadedData["test/image.jpg"] == data)
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
