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

    @Test func generationResult_codableRoundTrip() throws {
        let date = Date()
        let data = Data([1, 2, 3])
        let url = URL(string: "https://example.com/test/image.jpg")!

        let original = GenerationResult(
            date: date,
            prompt: "a test prompt",
            imageData: data,
            r2Key: "test/image.jpg",
            publicURL: url
        )

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(GenerationResult.self, from: encoded)

        #expect(decoded.date == date)
        #expect(decoded.prompt == "a test prompt")
        #expect(decoded.imageData == data)
        #expect(decoded.r2Key == "test/image.jpg")
        #expect(decoded.publicURL == url)
    }

    @Test func frescoError_codableRoundTrip() throws {
        let cases: [FrescoError] = [
            .geminiError("gemini fail"),
            .r2UploadError("r2 fail"),
            .configurationError("config fail"),
            .serverModeNotImplemented,
        ]

        for error in cases {
            let encoded = try JSONEncoder().encode(error)
            let decoded = try JSONDecoder().decode(FrescoError.self, from: encoded)
            #expect(String(describing: decoded) == String(describing: error))
        }
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
