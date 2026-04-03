import Foundation

public enum FrescoError: Error, Sendable {
    case geminiError(String)
    case r2UploadError(String)
    case configurationError(String)
    case fileReadError(String)
    case fileWriteError(String)
    case r2CopyError(String)
    case unsupportedImageFormat(String)
}
