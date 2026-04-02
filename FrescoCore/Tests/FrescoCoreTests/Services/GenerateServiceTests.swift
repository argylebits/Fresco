import Foundation
import Testing

@testable import FrescoCore

@Suite("GenerateService")
struct GenerateServiceTests {
    private static let testDate = Date(timeIntervalSince1970: 1_735_689_600) // 2025-01-01
    private static let testImageData = Data([0xFF, 0xD8, 0xFF, 0xE0])
    private static let testPrompt = "A sunrise over mountains"

    private func uniqueSlug() -> String {
        "test-\(UUID().uuidString.prefix(8))"
    }

    @Test("generate calls gemini and returns image data")
    func generateReturnsImageData() async throws {
        let slug = uniqueSlug()
        defer { try? FileManager.default.removeItem(atPath: "/tmp/\(slug)") }

        let service = GenerateService(
            gemini: MockGeminiClient(result: Self.testImageData)
        )

        let result = try await service.generate(
            prompt: Self.testPrompt,
            slug: slug,
            date: Self.testDate
        )

        #expect(result.imageData == Self.testImageData)
        #expect(result.prompt == Self.testPrompt)
        #expect(result.date == Self.testDate)
    }

    @Test("generate writes image to /tmp/{slug}/{date}.jpg")
    func generateWritesToTmp() async throws {
        let slug = uniqueSlug()
        defer { try? FileManager.default.removeItem(atPath: "/tmp/\(slug)") }

        let service = GenerateService(
            gemini: MockGeminiClient(result: Self.testImageData)
        )

        let result = try await service.generate(
            prompt: Self.testPrompt,
            slug: slug,
            date: Self.testDate
        )

        #expect(result.filePath == "/tmp/\(slug)/2025-01-01-000000.jpg")
        let written = try Data(contentsOf: URL(fileURLWithPath: result.filePath))
        #expect(written == Self.testImageData)
    }

    @Test("generate returns filePath without r2Key or publicURL")
    func generateResultHasNoUploadFields() async throws {
        let slug = uniqueSlug()
        defer { try? FileManager.default.removeItem(atPath: "/tmp/\(slug)") }

        let service = GenerateService(
            gemini: MockGeminiClient(result: Self.testImageData)
        )

        let result = try await service.generate(
            prompt: Self.testPrompt,
            slug: slug,
            date: Self.testDate
        )

        #expect(result.filePath.hasSuffix(".jpg"))
    }

    @Test("generate throws when gemini fails")
    func generateThrowsOnGeminiError() async {
        let service = GenerateService(
            gemini: MockGeminiClient(shouldThrow: .geminiError("generation failed"))
        )

        await #expect(throws: FrescoError.self) {
            try await service.generate(
                prompt: Self.testPrompt,
                slug: "test",
                date: Self.testDate
            )
        }
    }

    @Test("generate creates slug directory in /tmp if it doesn't exist")
    func generateCreatesDirectory() async throws {
        let slug = uniqueSlug()
        defer { try? FileManager.default.removeItem(atPath: "/tmp/\(slug)") }

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
    }

    @Test("generate throws configurationError for invalid slug")
    func generateThrowsOnInvalidSlug() async {
        let service = GenerateService(
            gemini: MockGeminiClient(result: Self.testImageData)
        )

        await #expect(throws: FrescoError.self) {
            try await service.generate(
                prompt: Self.testPrompt,
                slug: "../etc",
                date: Self.testDate
            )
        }
    }

    @Test("generate throws configurationError for empty slug")
    func generateThrowsOnEmptySlug() async {
        let service = GenerateService(
            gemini: MockGeminiClient(result: Self.testImageData)
        )

        await #expect(throws: FrescoError.self) {
            try await service.generate(
                prompt: Self.testPrompt,
                slug: "",
                date: Self.testDate
            )
        }
    }

    @Test("generate throws configurationError for whitespace-only slug")
    func generateThrowsOnWhitespaceSlug() async {
        let service = GenerateService(
            gemini: MockGeminiClient(result: Self.testImageData)
        )

        await #expect(throws: FrescoError.self) {
            try await service.generate(
                prompt: Self.testPrompt,
                slug: "  ",
                date: Self.testDate
            )
        }
    }
}
