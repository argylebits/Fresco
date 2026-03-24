import Foundation
import Testing

@testable import FrescoCore

@Suite("GenerateService")
struct GenerateServiceTests {
    private static let testDate = Date(timeIntervalSince1970: 1_735_689_600) // 2025-01-01
    private static let testImageData = Data([0xFF, 0xD8, 0xFF, 0xE0])
    private static let testPrompt = "A sunrise over mountains"
    private static let testSlug = "my-wallpaper"
    private static let testPublicBaseURL = "https://cdn.example.com"

    @Test("generate returns result with correct r2Key and publicURL")
    func generateReturnsCorrectResult() async throws {
        let service = GenerateService(
            gemini: MockGeminiClient(result: Self.testImageData),
            r2: MockR2Client(),
            publicBaseURL: Self.testPublicBaseURL
        )

        let result = try await service.generate(
            prompt: Self.testPrompt,
            slug: Self.testSlug,
            date: Self.testDate
        )

        #expect(result.r2Key == "my-wallpaper/2025-01-01.jpg")
        #expect(result.publicURL == URL(string: "https://cdn.example.com/my-wallpaper/2025-01-01.jpg")!)
    }

    @Test("generate returns result with imageData and prompt")
    func generateReturnsImageDataAndPrompt() async throws {
        let service = GenerateService(
            gemini: MockGeminiClient(result: Self.testImageData),
            r2: MockR2Client(),
            publicBaseURL: Self.testPublicBaseURL
        )

        let result = try await service.generate(
            prompt: Self.testPrompt,
            slug: Self.testSlug,
            date: Self.testDate
        )

        #expect(result.imageData == Self.testImageData)
        #expect(result.prompt == Self.testPrompt)
        #expect(result.date == Self.testDate)
    }

    @Test("generate throws when gemini fails")
    func generateThrowsOnGeminiError() async {
        let service = GenerateService(
            gemini: MockGeminiClient(shouldThrow: .geminiError("generation failed")),
            r2: MockR2Client(),
            publicBaseURL: Self.testPublicBaseURL
        )

        await #expect(throws: FrescoError.self) {
            try await service.generate(
                prompt: Self.testPrompt,
                slug: Self.testSlug,
                date: Self.testDate
            )
        }
    }

    @Test("generate throws when r2 upload fails")
    func generateThrowsOnR2Error() async {
        let service = GenerateService(
            gemini: MockGeminiClient(result: Self.testImageData),
            r2: MockR2Client(shouldThrow: .r2UploadError("upload failed")),
            publicBaseURL: Self.testPublicBaseURL
        )

        await #expect(throws: FrescoError.self) {
            try await service.generate(
                prompt: Self.testPrompt,
                slug: Self.testSlug,
                date: Self.testDate
            )
        }
    }
}
