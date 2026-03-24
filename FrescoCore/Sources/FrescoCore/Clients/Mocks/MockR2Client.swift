import Foundation

public final class MockR2Client: R2ClientProtocol, @unchecked Sendable {
    public private(set) var uploadedKeys: [String] = []
    public private(set) var uploadedData: [String: Data] = [:]
    public var shouldThrow: FrescoError?

    public init(shouldThrow: FrescoError? = nil) {
        self.shouldThrow = shouldThrow
    }

    public func upload(data: Data, key: String, contentType: String, cacheControl: String) async throws(FrescoError) {
        if let error = shouldThrow {
            throw error
        }
        uploadedKeys.append(key)
        uploadedData[key] = data
    }
}
