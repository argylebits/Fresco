import Foundation
import Testing
@testable import FrescoCore

struct R2ClientProtocolTests {
    struct MockR2Client: R2ClientProtocol {
        func upload(data: Data, key: String, contentType: String, cacheControl: String) async throws(FrescoError) {
        }

        func copy(sourceKey: String, destinationKey: String) async throws(FrescoError) {
        }
    }

    @Test func protocol_requiresUploadMethod() async throws {
        let client: any R2ClientProtocol = MockR2Client()
        try await client.upload(
            data: Data([0xFF, 0xD8, 0xFF]),
            key: "images/test.jpg",
            contentType: "image/jpeg",
            cacheControl: "public, max-age=31536000"
        )
    }

    private func requireSendable<T: Sendable>(_: T) {}

    @Test func protocol_isSendable() {
        let client: any R2ClientProtocol = MockR2Client()
        requireSendable(client)
    }
}
