import Foundation
import FrescoCore

struct MockCLIGeminiClient: GeminiClientProtocol {
    var result: Data = Data()
    var shouldThrow: FrescoError?

    func generateImage(prompt: String) async throws(FrescoError) -> Data {
        if let error = shouldThrow { throw error }
        return result
    }
}
