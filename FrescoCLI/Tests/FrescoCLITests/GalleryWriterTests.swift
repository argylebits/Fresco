import Testing
import Foundation
import FrescoCore
@testable import FrescoCLI

struct GalleryWriterTests {
    let writer = GalleryWriter()
    let marker = "<!-- Fresco appends new entries below this line on each generation -->"

    @Test func appendEntry_insertsRowAfterHeader() throws {
        let tmp = NSTemporaryDirectory() + "gallery-insert-\(UUID().uuidString).md"
        let content = """
            # Gallery

            \(marker)
            | Date | Image |
            |------|-------|
            | 2026-03-22 | ![](https://example.com/2026-03-22.jpg) |
            """
        try content.write(toFile: tmp, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(atPath: tmp) }

        try writer.appendEntry(to: tmp, date: "2026-03-23", imageURL: "https://example.com/2026-03-23.jpg")

        let lines = try String(contentsOfFile: tmp, encoding: .utf8).components(separatedBy: "\n")
        let separatorIndex = lines.firstIndex(where: { $0.contains("|------|") })
        #expect(separatorIndex != nil)
        #expect(lines[separatorIndex! + 1] == "| 2026-03-23 | ![](https://example.com/2026-03-23.jpg) |")
        #expect(lines[separatorIndex! + 2].contains("2026-03-22"))
    }

    @Test func appendEntry_firstEntry_createsTableHeader() throws {
        let tmp = NSTemporaryDirectory() + "gallery-first-\(UUID().uuidString).md"
        let content = """
            # Gallery

            \(marker)
            """
        try content.write(toFile: tmp, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(atPath: tmp) }

        try writer.appendEntry(to: tmp, date: "2026-03-23", imageURL: "https://example.com/2026-03-23.jpg")

        let lines = try String(contentsOfFile: tmp, encoding: .utf8).components(separatedBy: "\n")
        let markerIndex = lines.firstIndex(where: { $0.contains(marker) })
        #expect(markerIndex != nil)
        #expect(lines[markerIndex! + 1] == "| Date | Image |")
        #expect(lines[markerIndex! + 2] == "|------|-------|")
        #expect(lines[markerIndex! + 3] == "| 2026-03-23 | ![](https://example.com/2026-03-23.jpg) |")
    }

    @Test func appendEntry_newestFirst() throws {
        let tmp = NSTemporaryDirectory() + "gallery-order-\(UUID().uuidString).md"
        let content = """
            # Gallery

            \(marker)
            | Date | Image |
            |------|-------|
            | 2026-03-21 | ![](https://example.com/2026-03-21.jpg) |
            """
        try content.write(toFile: tmp, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(atPath: tmp) }

        try writer.appendEntry(to: tmp, date: "2026-03-22", imageURL: "https://example.com/2026-03-22.jpg")
        try writer.appendEntry(to: tmp, date: "2026-03-23", imageURL: "https://example.com/2026-03-23.jpg")

        let lines = try String(contentsOfFile: tmp, encoding: .utf8).components(separatedBy: "\n")
        let separatorIndex = lines.firstIndex(where: { $0.contains("|------|") })
        #expect(separatorIndex != nil)
        #expect(lines[separatorIndex! + 1].contains("2026-03-23"))
        #expect(lines[separatorIndex! + 2].contains("2026-03-22"))
        #expect(lines[separatorIndex! + 3].contains("2026-03-21"))
    }

    @Test func appendEntry_ignoresTableBeforeMarker() throws {
        let tmp = NSTemporaryDirectory() + "gallery-premarker-\(UUID().uuidString).md"
        let content = """
            # Gallery

            | Other | Table |
            |------|-------|
            | data | here |

            \(marker)
            | Date | Image |
            |------|-------|
            | 2026-03-22 | ![](https://example.com/2026-03-22.jpg) |
            """
        try content.write(toFile: tmp, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(atPath: tmp) }

        try writer.appendEntry(to: tmp, date: "2026-03-23", imageURL: "https://example.com/2026-03-23.jpg")

        let lines = try String(contentsOfFile: tmp, encoding: .utf8).components(separatedBy: "\n")
        // The pre-marker table should be untouched
        let markerIndex = lines.firstIndex(where: { $0.contains(marker) })!
        let galleryHeader = lines[(markerIndex + 1)...].firstIndex(where: { $0.contains("|------|") })!
        #expect(lines[galleryHeader + 1] == "| 2026-03-23 | ![](https://example.com/2026-03-23.jpg) |")
        #expect(lines[galleryHeader + 2].contains("2026-03-22"))
    }

    @Test func appendEntry_throwsWhenMarkerMissing() throws {
        let tmp = NSTemporaryDirectory() + "gallery-nomarker-\(UUID().uuidString).md"
        let content = "# Gallery\n\nSome content.\n"
        try content.write(toFile: tmp, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(atPath: tmp) }

        #expect(throws: FrescoError.self) {
            try writer.appendEntry(to: tmp, date: "2026-03-23", imageURL: "https://example.com/2026-03-23.jpg")
        }
    }
}
