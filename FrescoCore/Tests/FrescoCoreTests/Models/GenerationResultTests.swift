import Testing
import Foundation
@testable import FrescoCore

struct GenerationResultTests {
    @Test func generationResult_storesAllProperties() {
        let date = Date()
        let data = Data([1, 2, 3])

        let result = GenerationResult(
            date: date,
            prompt: "a test prompt",
            imageData: data,
            filePath: "/tmp/test/2025-01-01-000000.jpg"
        )

        #expect(result.date == date)
        #expect(result.prompt == "a test prompt")
        #expect(result.imageData == data)
        #expect(result.filePath == "/tmp/test/2025-01-01-000000.jpg")
    }

    @Test func generationResult_codableRoundTrip() throws {
        let date = Date()
        let data = Data([1, 2, 3])

        let original = GenerationResult(
            date: date,
            prompt: "a test prompt",
            imageData: data,
            filePath: "/tmp/test/2025-01-01-000000.jpg"
        )

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(GenerationResult.self, from: encoded)

        #expect(decoded.date == date)
        #expect(decoded.prompt == "a test prompt")
        #expect(decoded.imageData == data)
        #expect(decoded.filePath == "/tmp/test/2025-01-01-000000.jpg")
    }

    @Test func frescoError_casesAreDistinct() {
        let gemini = FrescoError.geminiError("fail")
        let r2 = FrescoError.r2UploadError("fail")
        let config = FrescoError.configurationError("fail")
        if case .geminiError = gemini {} else {
            Issue.record("Expected geminiError")
        }
        if case .r2UploadError = r2 {} else {
            Issue.record("Expected r2UploadError")
        }
        if case .configurationError = config {} else {
            Issue.record("Expected configurationError")
        }
        let fileRead = FrescoError.fileReadError("fail")
        if case .fileReadError = fileRead {} else {
            Issue.record("Expected fileReadError")
        }
        let fileWrite = FrescoError.fileWriteError("fail")
        if case .fileWriteError = fileWrite {} else {
            Issue.record("Expected fileWriteError")
        }
        let unsupported = FrescoError.unsupportedImageFormat("fail")
        if case .unsupportedImageFormat = unsupported {} else {
            Issue.record("Expected unsupportedImageFormat")
        }
    }
}
