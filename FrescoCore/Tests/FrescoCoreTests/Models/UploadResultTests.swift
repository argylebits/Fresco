import Testing
import Foundation
@testable import FrescoCore

struct UploadResultTests {
    @Test func uploadResult_storesAllProperties() {
        let url = URL(string: "https://cdn.example.com/fresco/2025-01-01-000000.jpg")!

        let result = UploadResult(
            r2Key: "fresco/2025-01-01-000000.jpg",
            publicURL: url
        )

        #expect(result.r2Key == "fresco/2025-01-01-000000.jpg")
        #expect(result.publicURL == url)
    }

    @Test func uploadResult_codableRoundTrip() throws {
        let url = URL(string: "https://cdn.example.com/fresco/2025-01-01-000000.jpg")!

        let original = UploadResult(
            r2Key: "fresco/2025-01-01-000000.jpg",
            publicURL: url
        )

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(UploadResult.self, from: encoded)

        #expect(decoded.r2Key == original.r2Key)
        #expect(decoded.publicURL == original.publicURL)
    }
}
