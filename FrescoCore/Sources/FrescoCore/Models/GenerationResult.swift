import Foundation

public struct GenerationResult: Sendable, Codable {
    public let date: Date
    public let prompt: String
    public let imageData: Data
    public let r2Key: String
    public let publicURL: URL

    public init(date: Date, prompt: String, imageData: Data, r2Key: String, publicURL: URL) {
        self.date = date
        self.prompt = prompt
        self.imageData = imageData
        self.r2Key = r2Key
        self.publicURL = publicURL
    }
}
