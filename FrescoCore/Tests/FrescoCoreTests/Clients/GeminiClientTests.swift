import Foundation
import Testing

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

@testable import FrescoCore

private let endpointURL = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent")!

private func makeResponse(statusCode: Int) -> HTTPURLResponse {
    HTTPURLResponse(url: endpointURL, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
}

private func makeValidResponseData(base64: String = "AQID", mimeType: String = "image/png") -> Data {
    let json = """
        {"candidates": [{"content": {"parts": [{"inlineData": {"mimeType": "\(mimeType)", "data": "\(base64)"}}]}}]}
        """
    return Data(json.utf8)
}

struct GeminiClientTests {
    @Test func buildRequest_encodesPromptInBody() throws {
        let client = GeminiClient(apiKey: "test-key")
        let request = try client.buildRequest(prompt: "a sunset")

        let bodyData = request.httpBody!
        let body = try JSONDecoder().decode(GeminiRequest.self, from: bodyData)
        #expect(body.contents.count == 1)
        #expect(body.contents[0].parts[0].text == "a sunset")
        #expect(body.generationConfig.responseModalities == ["IMAGE", "TEXT"])
    }

    @Test func buildRequest_usesGenerateContentEndpoint() throws {
        let client = GeminiClient(apiKey: "test-key")
        let request = try client.buildRequest(prompt: "test")

        #expect(request.url?.absoluteString.contains("gemini-2.5-flash-image:generateContent") == true)
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

    @Test func handleResponse_noImagePart_throws() throws {
        let client = GeminiClient(apiKey: "test-key")
        let json = Data("""
            {"candidates": [{"content": {"parts": [{"text": "Here is your image"}]}}]}
            """.utf8)

        #expect(throws: FrescoError.self) {
            try client.handleResponse(data: json, response: makeResponse(statusCode: 200))
        }
    }

    @Test func handleResponse_invalidBase64_throws() throws {
        let client = GeminiClient(apiKey: "test-key")
        let responseData = makeValidResponseData(base64: "%%%not-base64%%%")

        #expect(throws: FrescoError.self) {
            try client.handleResponse(data: responseData, response: makeResponse(statusCode: 200))
        }
    }
}
