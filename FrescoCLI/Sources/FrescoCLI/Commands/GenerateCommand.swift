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

    @Option(name: .long, help: "Project slug for image naming")
    var slug: String?

    @Option(name: .long, help: "Gemini API key")
    var geminiApiKey: String?

    @Option(name: .long, help: "Cloudflare R2 account ID")
    var r2AccountId: String?

    @Option(name: .long, help: "R2 access key ID")
    var r2AccessKeyId: String?

    @Option(name: .long, help: "R2 secret access key")
    var r2SecretAccessKey: String?

    @Option(name: .long, help: "R2 bucket name")
    var r2Bucket: String?

    @Option(name: .long, help: "R2 public base URL for uploaded images")
    var r2PublicBaseUrl: String?

    @Flag(name: .long, help: "Generate image and save to _preview/ without uploading")
    var preview: Bool = false

    struct Dependencies: Sendable {
        let configReader: ConfigReader
        let gemini: any GeminiClientProtocol
        let r2: any R2ClientProtocol
    }

    var overrideDependencies: Dependencies?

    enum CodingKeys: String, CodingKey {
        case prompt
        case append
        case slug
        case geminiApiKey
        case r2AccountId
        case r2AccessKeyId
        case r2SecretAccessKey
        case r2Bucket
        case r2PublicBaseUrl
        case preview
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

        let effectiveSlug = slug ?? deps.configReader.string(forKey: "frescoSlug")
        guard let effectiveSlug else {
            throw FrescoError.configurationError("FRESCO_SLUG is required (or use --slug)")
        }

        if preview {
            let imageData = try await deps.gemini.generateImage(prompt: effectivePrompt)
            let dateString = ISO8601DateFormatter.archiveKeyString(from: Date())
            let previewDir = URL(fileURLWithPath: "_preview")
            try FileManager.default.createDirectory(at: previewDir, withIntermediateDirectories: true)
            let file = previewDir.appendingPathComponent("\(effectiveSlug)-\(dateString).jpg")
            try imageData.write(to: file)
            print(file.path)
        } else {
            let effectiveR2PublicBaseUrl = r2PublicBaseUrl ?? deps.configReader.string(forKey: "r2.publicBaseUrl")
            guard let effectiveR2PublicBaseUrl else {
                throw FrescoError.configurationError("R2_PUBLIC_BASE_URL is required (or use --r2-public-base-url)")
            }

            let service = GenerateService(gemini: deps.gemini, r2: deps.r2, publicBaseURL: effectiveR2PublicBaseUrl)
            let result = try await service.generate(prompt: effectivePrompt, slug: effectiveSlug, date: Date())

            print(result.publicURL.absoluteString)
        }
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

        let effectiveGeminiApiKey = geminiApiKey ?? config.string(forKey: "geminiApiKey")
        guard let effectiveGeminiApiKey else {
            throw FrescoError.configurationError("GEMINI_API_KEY is required (or use --gemini-api-key)")
        }

        let gemini = GeminiClient(apiKey: effectiveGeminiApiKey)

        let r2: R2Client
        if !preview {
            let effectiveR2AccountId = r2AccountId ?? config.string(forKey: "r2.accountId")
            guard let effectiveR2AccountId else {
                throw FrescoError.configurationError("R2_ACCOUNT_ID is required (or use --r2-account-id)")
            }
            let effectiveR2AccessKeyId = r2AccessKeyId ?? config.string(forKey: "r2.accessKeyId")
            guard let effectiveR2AccessKeyId else {
                throw FrescoError.configurationError("R2_ACCESS_KEY_ID is required (or use --r2-access-key-id)")
            }
            let effectiveR2SecretAccessKey = r2SecretAccessKey ?? config.string(forKey: "r2.secretAccessKey")
            guard let effectiveR2SecretAccessKey else {
                throw FrescoError.configurationError("R2_SECRET_ACCESS_KEY is required (or use --r2-secret-access-key)")
            }
            let effectiveR2Bucket = r2Bucket ?? config.string(forKey: "r2.bucket")
            guard let effectiveR2Bucket else {
                throw FrescoError.configurationError("R2_BUCKET is required (or use --r2-bucket)")
            }

            r2 = R2Client(
                accountId: effectiveR2AccountId,
                accessKeyId: effectiveR2AccessKeyId,
                secretAccessKey: effectiveR2SecretAccessKey,
                bucket: effectiveR2Bucket,
            )
        } else {
            r2 = R2Client(accountId: "", accessKeyId: "", secretAccessKey: "", bucket: "")
        }

        return Dependencies(
            configReader: config,
            gemini: gemini,
            r2: r2,
        )
    }
}
