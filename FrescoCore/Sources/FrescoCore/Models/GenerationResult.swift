import Foundation

struct GenerationResult: Sendable, Codable {
    let date: Date
    let prompt: String
    let imageData: Data
    let r2Key: String
    let publicURL: URL
}
