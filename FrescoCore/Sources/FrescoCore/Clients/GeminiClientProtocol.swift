import Foundation

public protocol GeminiClientProtocol: Sendable {
    func generateImage(prompt: String) async throws(FrescoError) -> Data
}
