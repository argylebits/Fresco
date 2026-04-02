import Foundation
import Testing

@testable import FrescoCore

@Suite("GenerateService")
struct GenerateServiceTests {
    private static let testDate = Date(timeIntervalSince1970: 1_735_689_600) // 2025-01-01
    private static let testImageData = Data([0xFF, 0xD8, 0xFF, 0xE0])
    private static let testPrompt = "A sunrise over mountains"
    private static let testSlug = "my-wallpaper"

    @Test("generate calls gemini and returns image data")
    func generateReturnsImageData() async throws {
        let service = GenerateService(
            gemini: MockGeminiClient(result: Self.testImageData)
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

    @Test("generate writes image to /tmp/{slug}/{date}.jpg")
    func generateWritesToTmp() async throws {
        let service = GenerateService(
            gemini: MockGeminiClient(result: Self.testImageData)
        )

        let result = try await service.generate(
            prompt: Self.testPrompt,
            slug: Self.testSlug,
            date: Self.testDate
        )

        let expectedPath = "/tmp/my-wallpaper/2025-01-01-000000.jpg"
        #expect(result.filePath == expectedPath)
        let written = try Data(contentsOf: URL(fileURLWithPath: expectedPath))
        #expect(written == Self.testImageData)
    }

    @Test("generate returns filePath without r2Key or publicURL")
    func generateResultHasNoUploadFields() async throws {
        let service = GenerateService(
            gemini: MockGeminiClient(result: Self.testImageData)
        )

        let result = try await service.generate(
            prompt: Self.testPrompt,
            slug: Self.testSlug,
            date: Self.testDate
        )

        #expect(result.filePath.hasSuffix(".jpg"))
        // GenerationResult should not have r2Key or publicURL properties
    }

    @Test("generate throws when gemini fails")
    func generateThrowsOnGeminiError() async {
        let service = GenerateService(
            gemini: MockGeminiClient(shouldThrow: .geminiError("generation failed"))
        )

        await #expect(throws: FrescoError.self) {
            try await service.generate(
                prompt: Self.testPrompt,
                slug: Self.testSlug,
                date: Self.testDate
            )
        }
    }

    @Test("generate creates slug directory in /tmp if it doesn't exist")
    func generateCreatesDirectory() async throws {
        let slug = "test-dir-create-\(UUID().uuidString.prefix(8))"
        let service = GenerateService(
            gemini: MockGeminiClient(result: Self.testImageData)
        )

        let result = try await service.generate(
            prompt: Self.testPrompt,
            slug: slug,
            date: Self.testDate
        )

        #expect(result.filePath.hasPrefix("/tmp/\(slug)/"))
        #expect(FileManager.default.fileExists(atPath: result.filePath))

        // cleanup
        try? FileManager.default.removeItem(atPath: "/tmp/\(slug)")
    }
}
