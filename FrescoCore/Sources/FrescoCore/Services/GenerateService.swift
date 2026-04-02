import Foundation

public struct GenerateService: Sendable {
    public let gemini: any GeminiClientProtocol

    public init(gemini: any GeminiClientProtocol) {
        self.gemini = gemini
    }

    public func generate(prompt: String, slug: String, date: Date) async throws(FrescoError) -> GenerationResult {
        let slug = slug.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !slug.isEmpty, slug.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }) else {
            throw FrescoError.configurationError("Invalid slug: \(slug)")
        }

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
            throw FrescoError.fileWriteError("Failed to write image to \(filePath): \(error.localizedDescription)")
        }

        return GenerationResult(
            date: date,
            prompt: prompt,
            imageData: imageData,
            filePath: filePath
        )
    }
}
