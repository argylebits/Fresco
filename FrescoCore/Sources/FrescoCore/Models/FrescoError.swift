import Foundation

public enum FrescoError: Error, Sendable {
    case geminiError(String)
    case r2Error(String)
    case configurationError(String)
    case fileReadError(String)
    case fileWriteError(String)
    case unsupportedImageFormat(String)
}
