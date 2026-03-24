import Foundation

@testable import FrescoCore

struct MockGeminiClient: GeminiClientProtocol {
    var result: Data = Data()
    var shouldThrow: FrescoError?

    func generateImage(prompt: String) async throws(FrescoError) -> Data {
        if let error = shouldThrow { throw error }
        return result
    }
}
