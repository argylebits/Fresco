import Foundation

enum FrescoError: Error, Sendable, Codable {
    case geminiError(String)
    case r2UploadError(String)
    case configurationError(String)
    case serverModeNotImplemented
}
