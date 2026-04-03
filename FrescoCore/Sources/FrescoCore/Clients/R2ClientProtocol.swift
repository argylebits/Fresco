import Foundation

public protocol R2ClientProtocol: Sendable {
    func upload(data: Data, key: String, contentType: String, cacheControl: String) async throws(FrescoError)
    func copy(sourceKey: String, destinationKey: String) async throws(FrescoError)
}
