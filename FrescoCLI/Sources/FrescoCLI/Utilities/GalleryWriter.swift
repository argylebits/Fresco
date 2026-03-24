import Foundation
import FrescoCore

struct GalleryWriter: Sendable {
    private let marker = "<!-- Fresco appends new entries below this line on each generation -->"
    private let tableHeader = "| Date | Image |"
    private let tableSeparator = "|------|-------|"

    func appendEntry(to galleryPath: String, date: String, imageURL: String) throws(FrescoError) {
        let content: String
        do {
            content = try String(contentsOfFile: galleryPath, encoding: .utf8)
        } catch {
            throw .configurationError("Could not read gallery file: \(galleryPath)")
        }
        let row = "| \(date) | ![](\(imageURL)) |"
        var lines = content.components(separatedBy: "\n")

        guard let markerIndex = lines.firstIndex(where: { $0.contains(marker) }) else {
            throw .configurationError("Gallery file is missing the marker comment.")
        }

        let afterMarker = lines[(markerIndex + 1)...]
        if let separatorIndex = afterMarker.firstIndex(where: { $0.contains(tableSeparator) }) {
            lines.insert(row, at: separatorIndex + 1)
        } else {
            lines.insert(tableHeader, at: markerIndex + 1)
            lines.insert(tableSeparator, at: markerIndex + 2)
            lines.insert(row, at: markerIndex + 3)
        }

        let result = lines.joined(separator: "\n")
        do {
            try result.write(toFile: galleryPath, atomically: true, encoding: .utf8)
        } catch {
            throw .configurationError("Could not write gallery file: \(galleryPath)")
        }
    }
}
