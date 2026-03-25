import ArgumentParser
import Configuration
import Foundation
import FrescoCore

struct GenerateCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "generate",
        abstract: "Generate a new image and upload to R2"
    )

    @Option(name: .long, help: "Override the generation prompt entirely")
    var prompt: String?

    @Option(name: .long, help: "Append text to the configured prompt")
    var append: String?

    mutating func run() async throws {
        let config = ConfigReader(provider: EnvironmentVariablesProvider())

        guard let basePrompt = prompt ?? config.string(forKey: "frescoPrompt") else {
            throw FrescoError.configurationError("FRESCO_PROMPT is required (or use --prompt)")
        }

        let effectivePrompt: String
        if prompt != nil {
            effectivePrompt = basePrompt
        } else if let append {
            effectivePrompt = "\(basePrompt) \(append)"
        } else {
            effectivePrompt = basePrompt
        }

        guard let slug = config.string(forKey: "frescoSlug") else {
            throw FrescoError.configurationError("FRESCO_SLUG is required")
        }
        guard let geminiApiKey = config.string(forKey: "geminiApiKey") else {
            throw FrescoError.configurationError("GEMINI_API_KEY is required")
        }
        guard let r2AccountId = config.string(forKey: "r2AccountId") else {
            throw FrescoError.configurationError("R2_ACCOUNT_ID is required")
        }
        guard let r2AccessKeyId = config.string(forKey: "r2AccessKeyId") else {
            throw FrescoError.configurationError("R2_ACCESS_KEY_ID is required")
        }
        guard let r2SecretAccessKey = config.string(forKey: "r2SecretAccessKey") else {
            throw FrescoError.configurationError("R2_SECRET_ACCESS_KEY is required")
        }
        guard let r2Bucket = config.string(forKey: "r2Bucket") else {
            throw FrescoError.configurationError("R2_BUCKET is required")
        }
        guard let r2PublicBaseUrl = config.string(forKey: "r2PublicBaseUrl") else {
            throw FrescoError.configurationError("R2_PUBLIC_BASE_URL is required")
        }

        let gemini = GeminiClient(apiKey: geminiApiKey)
        let r2 = R2Client(
            accountId: r2AccountId,
            accessKeyId: r2AccessKeyId,
            secretAccessKey: r2SecretAccessKey,
            bucket: r2Bucket
        )

        let service = GenerateService(gemini: gemini, r2: r2, publicBaseURL: r2PublicBaseUrl)
        let result = try await service.generate(prompt: effectivePrompt, slug: slug, date: Date())

        let dateString = ISO8601DateFormatter.dateOnlyString(from: result.date)
        let galleryWriter = GalleryWriter()
        try galleryWriter.appendEntry(
            to: "gallery.md",
            date: dateString,
            imageURL: result.publicURL.absoluteString
        )

        print(result.publicURL.absoluteString)
    }
}
