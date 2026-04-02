import ArgumentParser
import Configuration
import Foundation
import FrescoCore

struct GenerateCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "generate",
        abstract: "Generate a new image"
    )

    @Option(name: .long, help: "Override the generation prompt entirely")
    var prompt: String?

    @Option(name: .long, help: "Append text to the configured prompt")
    var append: String?

    @Option(name: .long, help: "Project slug for image naming")
    var slug: String?

    @Option(name: .long, help: "Gemini API key")
    var geminiApiKey: String?

    struct Dependencies: Sendable {
        let configReader: ConfigReader
        let gemini: any GeminiClientProtocol
    }

    var overrideDependencies: Dependencies?

    enum CodingKeys: String, CodingKey {
        case prompt
        case append
        case slug
        case geminiApiKey
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

        let service = GenerateService(gemini: deps.gemini)
        let result = try await service.generate(prompt: effectivePrompt, slug: effectiveSlug, date: Date())

        print(result.filePath)
    }

    private func makeDependencies() async throws -> Dependencies {
        let config = try await loadConfigReader()

        let effectiveGeminiApiKey = geminiApiKey ?? config.string(forKey: "geminiApiKey")
        guard let effectiveGeminiApiKey else {
            throw FrescoError.configurationError("GEMINI_API_KEY is required (or use --gemini-api-key)")
        }

        let gemini = GeminiClient(apiKey: effectiveGeminiApiKey)

        return Dependencies(
            configReader: config,
            gemini: gemini
        )
    }
}
