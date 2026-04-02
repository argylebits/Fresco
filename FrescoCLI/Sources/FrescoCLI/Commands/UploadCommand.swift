import ArgumentParser
import Configuration
import Foundation
import FrescoCore

struct UploadCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "upload",
        abstract: "Upload an image to R2"
    )

    @Argument(help: "Path to the image file to upload")
    var filePath: String

    @Option(name: .long, help: "Project slug for R2 key prefix")
    var slug: String?

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

    struct Dependencies: Sendable {
        let configReader: ConfigReader
        let r2: any R2ClientProtocol
    }

    var overrideDependencies: Dependencies?

    enum CodingKeys: String, CodingKey {
        case filePath
        case slug
        case r2AccountId
        case r2AccessKeyId
        case r2SecretAccessKey
        case r2Bucket
        case r2PublicBaseUrl
    }

    mutating func run() async throws {
        let deps: Dependencies
        if let overrideDependencies {
            deps = overrideDependencies
        } else {
            deps = try await makeDependencies()
        }

        let effectiveSlug = slug ?? deps.configReader.string(forKey: "frescoSlug")
        guard let effectiveSlug else {
            throw FrescoError.configurationError("FRESCO_SLUG is required (or use --slug)")
        }

        let effectiveR2PublicBaseUrl = r2PublicBaseUrl ?? deps.configReader.string(forKey: "r2.publicBaseUrl")
        guard let effectiveR2PublicBaseUrl else {
            throw FrescoError.configurationError("R2_PUBLIC_BASE_URL is required (or use --r2-public-base-url)")
        }

        let service = UploadService(r2: deps.r2, publicBaseURL: effectiveR2PublicBaseUrl)
        let result = try await service.upload(filePath: filePath, slug: effectiveSlug)

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

        let r2 = R2Client(
            accountId: effectiveR2AccountId,
            accessKeyId: effectiveR2AccessKeyId,
            secretAccessKey: effectiveR2SecretAccessKey,
            bucket: effectiveR2Bucket
        )

        return Dependencies(
            configReader: config,
            r2: r2
        )
    }
}
