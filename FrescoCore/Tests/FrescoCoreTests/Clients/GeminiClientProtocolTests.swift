import Foundation
import Testing
@testable import FrescoCore

struct GeminiClientProtocolTests {
    struct MockGeminiClient: GeminiClientProtocol {
        var result: Data = Data()

        func generateImage(prompt: String) async throws -> Data {
            result
        }
    }

    @Test func protocol_requiresGenerateImageMethod() async throws {
        let expected = Data([0xFF, 0xD8, 0xFF])
        let client = MockGeminiClient(result: expected)
        let data = try await client.generateImage(prompt: "a sunset")
        #expect(data == expected)
    }

    @Test func protocol_isSendable() {
        let client: any GeminiClientProtocol & Sendable = MockGeminiClient()
        #expect(client is any GeminiClientProtocol)
    }
}
