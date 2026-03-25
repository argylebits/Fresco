import Foundation
import FrescoCore

struct MockCLIGeminiClient: GeminiClientProtocol {
    var result: Data = Data()
    var shouldThrow: FrescoError?
    var onGenerateImage: (@Sendable (String) -> Void)?

    func generateImage(prompt: String) async throws(FrescoError) -> Data {
        if let error = shouldThrow { throw error }
        onGenerateImage?(prompt)
        return result
    }
}
