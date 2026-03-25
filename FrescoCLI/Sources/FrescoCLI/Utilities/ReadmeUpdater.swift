import Foundation

struct ReadmeUpdater: Sendable {
    private let marker = "<!-- Fresco image -->"

    func insertImageURL(in readmePath: String, imageURL: String, name: String = "Fresco") throws {
        let content = try String(contentsOfFile: readmePath, encoding: .utf8)
        let imageLine = "![\(name)](\(imageURL))"
        var lines = content.components(separatedBy: "\n")

        if let markerIndex = lines.firstIndex(where: { $0.contains(marker) }) {
            // Find existing image line after marker, skipping blank lines
            var imageIndex: Int?
            for i in (markerIndex + 1)..<lines.count {
                let trimmed = lines[i].trimmingCharacters(in: .whitespaces)
                if trimmed.isEmpty { continue }
                if trimmed.hasPrefix("![") && trimmed.contains("](") { imageIndex = i }
                break
            }

            if let imageIndex {
                lines[imageIndex] = imageLine
            } else {
                lines.insert(imageLine, at: markerIndex + 1)
            }
        } else {
            // Insert after the first line (title)
            lines.insert("", at: 1)
            lines.insert(marker, at: 2)
            lines.insert(imageLine, at: 3)
        }

        let result = lines.joined(separator: "\n")
        try result.write(toFile: readmePath, atomically: true, encoding: .utf8)
    }
}
