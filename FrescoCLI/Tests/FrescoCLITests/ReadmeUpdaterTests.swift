import Testing
import Foundation
@testable import FrescoCLI

struct ReadmeUpdaterTests {
    let updater = ReadmeUpdater()
    let imageURL = "https://pub-xxx.r2.dev/fresco/today.jpg"

    @Test func insertImageURL_addsImageToReadme() throws {
        let tmp = NSTemporaryDirectory() + "readme-marker-\(UUID().uuidString).md"
        let content = """
            # My Project

            <!-- Fresco image -->

            Some other content.
            """
        try content.write(toFile: tmp, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(atPath: tmp) }

        try updater.insertImageURL(in: tmp, imageURL: imageURL)

        let lines = try String(contentsOfFile: tmp, encoding: .utf8).components(separatedBy: "\n")
        let markerIndex = lines.firstIndex(where: { $0.contains("<!-- Fresco image -->") })
        #expect(markerIndex != nil)
        #expect(lines[markerIndex! + 1] == "![Fresco](https://pub-xxx.r2.dev/fresco/today.jpg)")
    }

    @Test func insertImageURL_replacesExistingImage() throws {
        let tmp = NSTemporaryDirectory() + "readme-replace-\(UUID().uuidString).md"
        let content = """
            # My Project

            <!-- Fresco image -->
            ![Fresco](https://old-url.example.com/old.jpg)

            Some other content.
            """
        try content.write(toFile: tmp, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(atPath: tmp) }

        try updater.insertImageURL(in: tmp, imageURL: imageURL)

        let lines = try String(contentsOfFile: tmp, encoding: .utf8).components(separatedBy: "\n")
        #expect(!lines.contains(where: { $0.contains("old-url.example.com") }))
        let markerIndex = lines.firstIndex(where: { $0.contains("<!-- Fresco image -->") })
        #expect(markerIndex != nil)
        #expect(lines[markerIndex! + 1] == "![Fresco](https://pub-xxx.r2.dev/fresco/today.jpg)")
    }

    @Test func insertImageURL_replacesExistingImage_withBlankLineAfterMarker() throws {
        let tmp = NSTemporaryDirectory() + "readme-blankline-\(UUID().uuidString).md"
        let content = """
            # My Project

            <!-- Fresco image -->

            ![Fresco](https://old-url.example.com/old.jpg)

            Some other content.
            """
        try content.write(toFile: tmp, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(atPath: tmp) }

        try updater.insertImageURL(in: tmp, imageURL: imageURL)

        let lines = try String(contentsOfFile: tmp, encoding: .utf8).components(separatedBy: "\n")
        #expect(!lines.contains(where: { $0.contains("old-url.example.com") }))
        #expect(lines.contains(where: { $0 == "![Fresco](https://pub-xxx.r2.dev/fresco/today.jpg)" }))
    }

    @Test func insertMarker_addsMarkerOnly() throws {
        let tmp = NSTemporaryDirectory() + "readme-markeronly-\(UUID().uuidString).md"
        let content = """
            # My Project

            Some other content.
            """
        try content.write(toFile: tmp, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(atPath: tmp) }

        try updater.insertMarker(in: tmp)

        let result = try String(contentsOfFile: tmp, encoding: .utf8)
        #expect(result.contains("<!-- Fresco image -->"))
        #expect(!result.contains("!["))
    }

    @Test func insertMarker_skipsIfMarkerAlreadyExists() throws {
        let tmp = NSTemporaryDirectory() + "readme-markerexists-\(UUID().uuidString).md"
        let content = """
            # My Project

            <!-- Fresco image -->

            Some other content.
            """
        try content.write(toFile: tmp, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(atPath: tmp) }

        try updater.insertMarker(in: tmp)

        let result = try String(contentsOfFile: tmp, encoding: .utf8)
        let markerCount = result.components(separatedBy: "<!-- Fresco image -->").count - 1
        #expect(markerCount == 1)
    }

    @Test func insertImageURL_noMarker_addsMarkerAndImage() throws {
        let tmp = NSTemporaryDirectory() + "readme-nomarker-\(UUID().uuidString).md"
        let content = """
            # My Project

            Some other content.
            """
        try content.write(toFile: tmp, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(atPath: tmp) }

        try updater.insertImageURL(in: tmp, imageURL: imageURL)

        let lines = try String(contentsOfFile: tmp, encoding: .utf8).components(separatedBy: "\n")
        let markerIndex = lines.firstIndex(where: { $0.contains("<!-- Fresco image -->") })
        #expect(markerIndex != nil)
        #expect(lines[markerIndex! + 1] == "![Fresco](https://pub-xxx.r2.dev/fresco/today.jpg)")
    }
}
