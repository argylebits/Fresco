import Foundation
import Testing
@testable import FrescoCore

struct GeminiRequestTests {
    @Test func encode_producesExpectedJSON() throws {
        let request = GeminiRequest(
            instances: [.init(prompt: "a sunset")],
            parameters: .init(sampleCount: 1, aspectRatio: "16:9")
        )
        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        let instances = json["instances"] as! [[String: Any]]
        #expect(instances.count == 1)
        #expect(instances[0]["prompt"] as! String == "a sunset")

        let parameters = json["parameters"] as! [String: Any]
        #expect(parameters["sampleCount"] as! Int == 1)
        #expect(parameters["aspectRatio"] as! String == "16:9")
    }

    @Test func encode_roundTrips() throws {
        let request = GeminiRequest(
            instances: [.init(prompt: "test prompt")],
            parameters: .init(sampleCount: 1, aspectRatio: "16:9")
        )
        let data = try JSONEncoder().encode(request)
        let decoded = try JSONDecoder().decode(GeminiRequest.self, from: data)
        #expect(decoded.instances[0].prompt == "test prompt")
        #expect(decoded.parameters.sampleCount == 1)
        #expect(decoded.parameters.aspectRatio == "16:9")
    }
}

struct GeminiResponseTests {
    @Test func decode_validJSON() throws {
        let json = """
        {"predictions": [{"bytesBase64Encoded": "AQID"}]}
        """
        let response = try JSONDecoder().decode(GeminiResponse.self, from: Data(json.utf8))
        #expect(response.predictions.count == 1)
        #expect(response.predictions[0].bytesBase64Encoded == "AQID")
    }

    @Test func decode_missingPredictions_throws() {
        let json = """
        {"other": "value"}
        """
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(GeminiResponse.self, from: Data(json.utf8))
        }
    }

    @Test func decode_emptyPredictions() throws {
        let json = """
        {"predictions": []}
        """
        let response = try JSONDecoder().decode(GeminiResponse.self, from: Data(json.utf8))
        #expect(response.predictions.isEmpty)
    }

    @Test func decode_missingBase64Field_throws() {
        let json = """
        {"predictions": [{"wrongField": "value"}]}
        """
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(GeminiResponse.self, from: Data(json.utf8))
        }
    }
}
