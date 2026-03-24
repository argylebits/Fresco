import Foundation
import Testing
@testable import FrescoCore

struct R2ClientProtocolTests {
    final class MockR2Client: R2ClientProtocol, @unchecked Sendable {
        var receivedData: Data?
        var receivedKey: String?
        var receivedContentType: String?
        var receivedCacheControl: String?

        func upload(data: Data, key: String, contentType: String, cacheControl: String) async throws(FrescoError) {
            receivedData = data
            receivedKey = key
            receivedContentType = contentType
            receivedCacheControl = cacheControl
        }
    }

    @Test func protocol_requiresUploadMethod() async throws {
        let client = MockR2Client()
        let expectedData = Data([0xFF, 0xD8, 0xFF])

        try await client.upload(
            data: expectedData,
            key: "images/test.jpg",
            contentType: "image/jpeg",
            cacheControl: "public, max-age=31536000"
        )

        #expect(client.receivedData == expectedData)
        #expect(client.receivedKey == "images/test.jpg")
        #expect(client.receivedContentType == "image/jpeg")
        #expect(client.receivedCacheControl == "public, max-age=31536000")
    }

    private func requireSendable<T: Sendable>(_: T) {}

    @Test func protocol_isSendable() {
        let client: any R2ClientProtocol = MockR2Client()
        requireSendable(client)
    }
}
