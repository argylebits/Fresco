import Configuration
import Foundation
import FrescoCore

func loadConfigReader() async throws -> ConfigReader {
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
    return ConfigReader(provider: envProvider)
}
