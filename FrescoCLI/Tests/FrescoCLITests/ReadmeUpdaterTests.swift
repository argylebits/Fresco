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

        let result = try String(contentsOfFile: tmp, encoding: .utf8)
        #expect(result.contains("<!-- Fresco image -->"))
        #expect(result.contains("![Fresco](https://pub-xxx.r2.dev/fresco/today.jpg)"))
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

        let result = try String(contentsOfFile: tmp, encoding: .utf8)
        #expect(!result.contains("old-url.example.com"))
        #expect(result.contains("![Fresco](https://pub-xxx.r2.dev/fresco/today.jpg)"))
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

        let result = try String(contentsOfFile: tmp, encoding: .utf8)
        #expect(result.contains("<!-- Fresco image -->"))
        #expect(result.contains("![Fresco](https://pub-xxx.r2.dev/fresco/today.jpg)"))
    }
}
