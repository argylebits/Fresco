import Foundation

struct ReadmeUpdater: Sendable {
    private let marker = "<!-- Fresco image -->"

    func insertImageURL(in readmePath: String, imageURL: String) throws {
        let content = try String(contentsOfFile: readmePath, encoding: .utf8)
        let imageLine = "![Fresco](\(imageURL))"
        var lines = content.components(separatedBy: "\n")

        if let markerIndex = lines.firstIndex(where: { $0.contains(marker) }) {
            let nextIndex = markerIndex + 1
            if nextIndex < lines.count && lines[nextIndex].hasPrefix("![Fresco](") {
                lines[nextIndex] = imageLine
            } else {
                lines.insert(imageLine, at: nextIndex)
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
