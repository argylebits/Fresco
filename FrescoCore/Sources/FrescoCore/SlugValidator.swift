import Foundation

public enum SlugValidator {
    public static func validate(_ slug: String) throws(FrescoError) -> String {
        let trimmed = slug.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }) else {
            throw FrescoError.configurationError("Invalid slug: \(slug)")
        }
        return trimmed
    }
}
