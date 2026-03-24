import Foundation
import Testing
@testable import FrescoCore

struct MockGeminiClientTests {
    @Test func success_returnsConfiguredData() async throws {
        let data = Data(repeating: 0xFF, count: 64)
        let mock = MockGeminiClient(behaviour: .success(data))
        let result = try await mock.generateImage(prompt: "test")
        #expect(result == data)
    }

    @Test func failure_throwsConfiguredError() async {
        let mock = MockGeminiClient(behaviour: .failure(.geminiError("test error")))
        await #expect(throws: FrescoError.self) {
            try await mock.generateImage(prompt: "test")
        }
    }
}
