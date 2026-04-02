import Foundation

public enum ImageFormat: Sendable {
    case png
    case jpeg

    public var fileExtension: String {
        switch self {
        case .png: "png"
        case .jpeg: "jpg"
        }
    }

    public var contentType: String {
        switch self {
        case .png: "image/png"
        case .jpeg: "image/jpeg"
        }
    }

    public static func detect(from data: Data) throws(FrescoError) -> ImageFormat {
        if data.prefix(4) == Data([0x89, 0x50, 0x4E, 0x47]) {
            return .png
        }
        if data.prefix(3) == Data([0xFF, 0xD8, 0xFF]) {
            return .jpeg
        }
        throw FrescoError.configurationError("Unrecognized image format")
    }
}
