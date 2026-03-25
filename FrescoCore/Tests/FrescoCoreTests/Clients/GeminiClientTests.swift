import Foundation
import Testing

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

@testable import FrescoCore

private let endpointURL = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/imagen-4.0-ultra-generate-001:predict")!

private func makeResponse(statusCode: Int) -> HTTPURLResponse {
    HTTPURLResponse(url: endpointURL, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
}

private func makeValidResponseData(base64: String = "AQID") -> Data {
    let json = """
        {"predictions": [{"bytesBase64Encoded": "\(base64)"}]}
        """
    return Data(json.utf8)
}

struct GeminiClientTests {
    @Test func buildRequest_encodesPromptInBody() throws {
        let client = GeminiClient(apiKey: "test-key")
        let request = try client.buildRequest(prompt: "a sunset")

        let bodyData = request.httpBody!
        let body = try JSONDecoder().decode(GeminiRequest.self, from: bodyData)
        #expect(body.instances.count == 1)
        #expect(body.instances[0].prompt == "a sunset")
        #expect(body.parameters.sampleCount == 1)
    }

    @Test func buildRequest_usesImagenUltraModel() throws {
        let client = GeminiClient(apiKey: "test-key")
        let request = try client.buildRequest(prompt: "test")

        #expect(request.url?.absoluteString.contains("imagen-4.0-ultra-generate-001") == true)
    }

    @Test func buildRequest_requests16x9AspectRatio() throws {
        let client = GeminiClient(apiKey: "test-key")
        let request = try client.buildRequest(prompt: "test")

        let bodyData = request.httpBody!
        let body = try JSONDecoder().decode(GeminiRequest.self, from: bodyData)
        #expect(body.parameters.aspectRatio == "16:9")
    }

    @Test func buildRequest_setsAPIKeyHeader() throws {
        let client = GeminiClient(apiKey: "test-key")
        let request = try client.buildRequest(prompt: "test")

        #expect(request.value(forHTTPHeaderField: "x-goog-api-key") == "test-key")
    }

    @Test func handleResponse_decodesImageData() throws {
        let imageBytes = Data([0x01, 0x02, 0x03])
        let base64 = imageBytes.base64EncodedString()
        let responseData = makeValidResponseData(base64: base64)

        let client = GeminiClient(apiKey: "test-key")
        let result = try client.handleResponse(data: responseData, response: makeResponse(statusCode: 200))

        #expect(result == imageBytes)
    }

    @Test func handleResponse_httpError_throwsWithBody() throws {
        let client = GeminiClient(apiKey: "test-key")

        do {
            _ = try client.handleResponse(
                data: Data("bad request details".utf8),
                response: makeResponse(statusCode: 400)
            )
            Issue.record("Expected error")
        } catch {
            if case .geminiError(let message) = error {
                #expect(message.contains("400"))
                #expect(message.contains("bad request details"))
            } else {
                Issue.record("Wrong error case: \(error)")
            }
        }
    }

    @Test func handleResponse_malformedJSON_throws() throws {
        let client = GeminiClient(apiKey: "test-key")

        #expect(throws: FrescoError.self) {
            try client.handleResponse(
                data: Data("not json".utf8),
                response: makeResponse(statusCode: 200)
            )
        }
    }

    @Test func handleResponse_emptyPredictions_throws() throws {
        let client = GeminiClient(apiKey: "test-key")
        let json = Data("""
            {"predictions": []}
            """.utf8)

        #expect(throws: FrescoError.self) {
            try client.handleResponse(data: json, response: makeResponse(statusCode: 200))
        }
    }

    @Test func handleResponse_invalidBase64_throws() throws {
        let client = GeminiClient(apiKey: "test-key")
        let json = Data("""
            {"predictions": [{"bytesBase64Encoded": "%%%not-base64%%%"}]}
            """.utf8)

        #expect(throws: FrescoError.self) {
            try client.handleResponse(data: json, response: makeResponse(statusCode: 200))
        }
    }
}
