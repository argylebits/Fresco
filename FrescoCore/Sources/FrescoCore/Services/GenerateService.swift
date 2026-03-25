import Foundation

public struct GenerateService: Sendable {
    public let gemini: any GeminiClientProtocol
    public let r2: any R2ClientProtocol
    public let publicBaseURL: String

    public init(gemini: any GeminiClientProtocol, r2: any R2ClientProtocol, publicBaseURL: String) {
        self.gemini = gemini
        self.r2 = r2
        self.publicBaseURL = publicBaseURL
    }

    public func generate(prompt: String, slug: String, date: Date) async throws(FrescoError) -> GenerationResult {
        let imageData = try await gemini.generateImage(prompt: prompt)

        let archiveDateString = ISO8601DateFormatter.archiveKeyString(from: date)
        let archiveKey = "\(slug)/\(archiveDateString).jpg"
        try await r2.upload(
            data: imageData,
            key: archiveKey,
            contentType: "image/jpeg",
            cacheControl: "public, max-age=31536000"
        )

        guard let baseURL = URL(string: publicBaseURL) else {
            throw FrescoError.configurationError("Invalid publicBaseURL: \(publicBaseURL)")
        }

        let publicURL = baseURL
            .appendingPathComponent(slug)
            .appendingPathComponent("\(archiveDateString).jpg")

        return GenerationResult(
            date: date,
            prompt: prompt,
            imageData: imageData,
            r2Key: archiveKey,
            publicURL: publicURL
        )
    }
}
