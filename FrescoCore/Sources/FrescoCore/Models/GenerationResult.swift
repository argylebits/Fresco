import Foundation

public struct GenerationResult: Sendable, Codable {
    public let date: Date
    public let prompt: String
    public let imageData: Data
    public let filePath: String

    public init(date: Date, prompt: String, imageData: Data, filePath: String) {
        self.date = date
        self.prompt = prompt
        self.imageData = imageData
        self.filePath = filePath
    }
}
