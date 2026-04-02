import Foundation

public struct GenerateService: Sendable {
    public let gemini: any GeminiClientProtocol

    public init(gemini: any GeminiClientProtocol) {
        self.gemini = gemini
    }

    public func generate(prompt: String, slug: String, date: Date) async throws(FrescoError) -> GenerationResult {
        let slug = try SlugValidator.validate(slug)

        let imageData = try await gemini.generateImage(prompt: prompt)

        let format = try ImageFormat.detect(from: imageData)
        let dateString = ISO8601DateFormatter.archiveKeyString(from: date)
        let directory = "/tmp/\(slug)"
        let filePath = "\(directory)/\(dateString).\(format.fileExtension)"

        do {
            try FileManager.default.createDirectory(
                atPath: directory,
                withIntermediateDirectories: true
            )
            try imageData.write(to: URL(fileURLWithPath: filePath), options: .atomic)
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
