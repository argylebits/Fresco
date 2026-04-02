import Foundation

public struct UploadResult: Sendable, Codable {
    public let r2Key: String
    public let publicURL: URL

    public init(r2Key: String, publicURL: URL) {
        self.r2Key = r2Key
        self.publicURL = publicURL
    }
}
