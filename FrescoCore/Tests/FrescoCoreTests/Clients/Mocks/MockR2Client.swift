import Foundation

@testable import FrescoCore

struct MockR2Client: R2ClientProtocol {
    var shouldThrow: FrescoError?
    var onUpload: (@Sendable (Data, String, String, String) -> Void)?
    var onCopy: (@Sendable (String, String) -> Void)?

    func upload(data: Data, key: String, contentType: String, cacheControl: String) async throws(FrescoError) {
        if let error = shouldThrow {
            throw error
        }
        onUpload?(data, key, contentType, cacheControl)
    }

    func copy(sourceKey: String, destinationKey: String) async throws(FrescoError) {
        if let error = shouldThrow {
            throw error
        }
        onCopy?(sourceKey, destinationKey)
    }
}
