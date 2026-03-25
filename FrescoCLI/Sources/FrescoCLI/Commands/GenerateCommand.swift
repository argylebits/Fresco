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

    struct Dependencies: Sendable {
        let configReader: ConfigReader
        let gemini: any GeminiClientProtocol
        let r2: any R2ClientProtocol
        let galleryWriter: any GalleryWriterProtocol
    }

    var overrideDependencies: Dependencies?

    enum CodingKeys: String, CodingKey {
        case prompt
        case append
    }

    mutating func run() async throws {
        let deps: Dependencies
        if let overrideDependencies {
            deps = overrideDependencies
        } else {
            deps = try await makeDependencies()
        }

        let configuredPrompt = deps.configReader.string(forKey: "frescoPrompt")

        let effectivePrompt: String
        if let prompt {
            effectivePrompt = prompt
        } else if let configuredPrompt {
            effectivePrompt = append.map { "\(configuredPrompt) \($0)" } ?? configuredPrompt
        } else {
            throw FrescoError.configurationError("FRESCO_PROMPT is required (or use --prompt)")
        }

        guard let slug = deps.configReader.string(forKey: "frescoSlug") else {
            throw FrescoError.configurationError("FRESCO_SLUG is required")
        }
        guard let r2PublicBaseUrl = deps.configReader.string(forKey: "r2.publicBaseUrl") else {
            throw FrescoError.configurationError("R2_PUBLIC_BASE_URL is required")
        }

        let service = GenerateService(gemini: deps.gemini, r2: deps.r2, publicBaseURL: r2PublicBaseUrl)
        let result = try await service.generate(prompt: effectivePrompt, slug: slug, date: Date())

        let dateString = ISO8601DateFormatter.dateOnlyString(from: result.date)
        try deps.galleryWriter.appendEntry(
            to: "gallery.md",
            date: dateString,
            imageURL: result.publicURL.absoluteString
        )

        if FileManager.default.fileExists(atPath: "README.md") {
            try ReadmeUpdater().insertImageURL(in: "README.md", imageURL: result.publicURL.absoluteString)
        }

        print(result.publicURL.absoluteString)
    }

    private func makeDependencies() async throws -> Dependencies {
        let envProvider: EnvironmentVariablesProvider
        if FileManager.default.fileExists(atPath: ".env") {
            do {
                envProvider = try await EnvironmentVariablesProvider(environmentFilePath: ".env")
            } catch {
                throw FrescoError.configurationError("Failed to load .env: \(error.localizedDescription)")
            }
        } else {
            envProvider = EnvironmentVariablesProvider()
        }
        let config = ConfigReader(provider: envProvider)

        guard let geminiApiKey = config.string(forKey: "geminiApiKey") else {
            throw FrescoError.configurationError("GEMINI_API_KEY is required")
        }
        guard let r2AccountId = config.string(forKey: "r2.accountId") else {
            throw FrescoError.configurationError("R2_ACCOUNT_ID is required")
        }
        guard let r2AccessKeyId = config.string(forKey: "r2.accessKeyId") else {
            throw FrescoError.configurationError("R2_ACCESS_KEY_ID is required")
        }
        guard let r2SecretAccessKey = config.string(forKey: "r2.secretAccessKey") else {
            throw FrescoError.configurationError("R2_SECRET_ACCESS_KEY is required")
        }
        guard let r2Bucket = config.string(forKey: "r2.bucket") else {
            throw FrescoError.configurationError("R2_BUCKET is required")
        }

        return Dependencies(
            configReader: config,
            gemini: GeminiClient(apiKey: geminiApiKey),
            r2: R2Client(
                accountId: r2AccountId,
                accessKeyId: r2AccessKeyId,
                secretAccessKey: r2SecretAccessKey,
                bucket: r2Bucket
            ),
            galleryWriter: GalleryWriter()
        )
    }
}
