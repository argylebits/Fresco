import Foundation
import Testing
@testable import FrescoCore

struct GeminiRequestTests {
    @Test func encode_producesExpectedJSON() throws {
        let request = GeminiRequest(
            contents: [.init(parts: [.init(text: "a sunset")])],
            generationConfig: .init(responseModalities: ["IMAGE", "TEXT"])
        )
        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        let contents = json["contents"] as! [[String: Any]]
        #expect(contents.count == 1)
        let parts = contents[0]["parts"] as! [[String: Any]]
        #expect(parts[0]["text"] as! String == "a sunset")

        let config = json["generationConfig"] as! [String: Any]
        let modalities = config["responseModalities"] as! [String]
        #expect(modalities == ["IMAGE", "TEXT"])
    }

    @Test func encode_roundTrips() throws {
        let request = GeminiRequest(
            contents: [.init(parts: [.init(text: "test prompt")])],
            generationConfig: .init(responseModalities: ["IMAGE", "TEXT"])
        )
        let data = try JSONEncoder().encode(request)
        let decoded = try JSONDecoder().decode(GeminiRequest.self, from: data)
        #expect(decoded.contents[0].parts[0].text == "test prompt")
        #expect(decoded.generationConfig.responseModalities == ["IMAGE", "TEXT"])
    }
}

struct GeminiResponseTests {
    @Test func decode_validJSON() throws {
        let json = """
        {"candidates": [{"content": {"parts": [{"inlineData": {"mimeType": "image/png", "data": "AQID"}}]}}]}
        """
        let response = try JSONDecoder().decode(GeminiResponse.self, from: Data(json.utf8))
        #expect(response.candidates.count == 1)
        #expect(response.candidates[0].content.parts[0].inlineData?.data == "AQID")
    }

    @Test func decode_missingCandidates_throws() {
        let json = """
        {"other": "value"}
        """
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(GeminiResponse.self, from: Data(json.utf8))
        }
    }

    @Test func decode_emptyCandidates() throws {
        let json = """
        {"candidates": []}
        """
        let response = try JSONDecoder().decode(GeminiResponse.self, from: Data(json.utf8))
        #expect(response.candidates.isEmpty)
    }

    @Test func decode_textOnlyPart_hasNoInlineData() throws {
        let json = """
        {"candidates": [{"content": {"parts": [{"text": "Here is your image"}]}}]}
        """
        let response = try JSONDecoder().decode(GeminiResponse.self, from: Data(json.utf8))
        #expect(response.candidates[0].content.parts[0].inlineData == nil)
    }
}
