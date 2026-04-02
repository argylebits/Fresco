import Foundation

public struct GenerateService: Sendable {
    public let gemini: any GeminiClientProtocol

    public init(gemini: any GeminiClientProtocol) {
        self.gemini = gemini
    }

    public func generate(prompt: String, slug: String, date: Date) async throws(FrescoError) -> GenerationResult {
        let imageData = try await gemini.generateImage(prompt: prompt)

        let dateString = ISO8601DateFormatter.archiveKeyString(from: date)
        let directory = "/tmp/\(slug)"
        let filePath = "\(directory)/\(dateString).jpg"

        do {
            try FileManager.default.createDirectory(
                atPath: directory,
                withIntermediateDirectories: true
            )
            try imageData.write(to: URL(fileURLWithPath: filePath))
        } catch {
            throw FrescoError.configurationError("Failed to write image to \(filePath): \(error.localizedDescription)")
        }

        return GenerationResult(
            date: date,
            prompt: prompt,
            imageData: imageData,
            filePath: filePath
        )
    }
}
