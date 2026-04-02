import Foundation

public enum FrescoError: Error, Sendable {
    case geminiError(String)
    case r2UploadError(String)
    case configurationError(String)
    case fileWriteError(String)
}
