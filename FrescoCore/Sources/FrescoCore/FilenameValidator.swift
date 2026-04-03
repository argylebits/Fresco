import Foundation

public enum FilenameValidator {
    public static func validate(_ filename: String) throws(FrescoError) -> String {
        let trimmed = filename.trimmingCharacters(in: .whitespacesAndNewlines)
        guard
            !trimmed.isEmpty,
            trimmed != ".",
            trimmed != "..",
            !trimmed.contains("/"),
            !trimmed.contains("..")
        else {
            throw FrescoError.configurationError("Invalid filename: \(filename)")
        }
        return trimmed
    }
}
