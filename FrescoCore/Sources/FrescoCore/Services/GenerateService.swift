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

        let dateString = formatDate(date)
        let archiveKey = "\(slug)/\(dateString).jpg"
        let todayKey = "\(slug)/today.jpg"

        try await r2.upload(
            data: imageData,
            key: archiveKey,
            contentType: "image/jpeg",
            cacheControl: "public, max-age=31536000"
        )

        try await r2.upload(
            data: imageData,
            key: todayKey,
            contentType: "image/jpeg",
            cacheControl: "public, max-age=3600"
        )

        let publicURL = URL(string: "\(publicBaseURL)/\(archiveKey)")!

        return GenerationResult(
            date: date,
            prompt: prompt,
            imageData: imageData,
            r2Key: archiveKey,
            publicURL: publicURL
        )
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: date)
    }
}
