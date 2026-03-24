import Testing
import Foundation
@testable import FrescoCore

struct GenerationResultTests {
    @Test func generationResult_storesAllProperties() {
        let date = Date()
        let data = Data([1, 2, 3])
        let url = URL(string: "https://example.com/test/image.jpg")!

        let result = GenerationResult(
            date: date,
            prompt: "a test prompt",
            imageData: data,
            r2Key: "test/image.jpg",
            publicURL: url
        )

        #expect(result.date == date)
        #expect(result.prompt == "a test prompt")
        #expect(result.imageData == data)
        #expect(result.r2Key == "test/image.jpg")
        #expect(result.publicURL == url)
    }

    @Test func frescoError_casesAreDistinct() {
        let gemini = FrescoError.geminiError("fail")
        let r2 = FrescoError.r2UploadError("fail")
        let config = FrescoError.configurationError("fail")
        let server = FrescoError.serverModeNotImplemented

        if case .geminiError = gemini {} else {
            Issue.record("Expected geminiError")
        }
        if case .r2UploadError = r2 {} else {
            Issue.record("Expected r2UploadError")
        }
        if case .configurationError = config {} else {
            Issue.record("Expected configurationError")
        }
        if case .serverModeNotImplemented = server {} else {
            Issue.record("Expected serverModeNotImplemented")
        }
    }
}
