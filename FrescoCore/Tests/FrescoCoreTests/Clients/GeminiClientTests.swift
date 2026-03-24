import Foundation
import Testing
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import FrescoCore

final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var handler: ((URLRequest) throws -> (Data, HTTPURLResponse))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.handler else {
            client?.urlProtocolDidFinishLoading(self)
            return
        }
        do {
            let (data, response) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

private func makeSession() -> URLSession {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [MockURLProtocol.self]
    return URLSession(configuration: config)
}

private let endpointURL = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/imagen-3.0-generate-002:predict")!

private func makeResponse(statusCode: Int) -> HTTPURLResponse {
    HTTPURLResponse(url: endpointURL, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
}

private func makeValidResponseData(base64: String = "AQID") -> Data {
    let json = """
    {"predictions": [{"bytesBase64Encoded": "\(base64)"}]}
    """
    return Data(json.utf8)
}

@Suite(.serialized)
struct GeminiClientTests {
    @Test func happyPath_returnsDecodedImageData() async throws {
        let imageBytes = Data([0x01, 0x02, 0x03])
        let base64 = imageBytes.base64EncodedString()

        MockURLProtocol.handler = { request in
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "x-goog-api-key") == "test-key")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
            return (makeValidResponseData(base64: base64), makeResponse(statusCode: 200))
        }

        let client = GeminiClient(apiKey: "test-key", session: makeSession())
        let result = try await client.generateImage(prompt: "a sunset")
        #expect(result == imageBytes)
    }

    @Test func requestBody_matchesExpectedStructure() async throws {
        MockURLProtocol.handler = { request in
            let bodyData: Data
            if let httpBody = request.httpBody {
                bodyData = httpBody
            } else if let stream = request.httpBodyStream {
                stream.open()
                defer { stream.close() }
                var data = Data()
                let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 1024)
                defer { buffer.deallocate() }
                while stream.hasBytesAvailable {
                    let read = stream.read(buffer, maxLength: 1024)
                    if read > 0 { data.append(buffer, count: read) }
                    else { break }
                }
                bodyData = data
            } else {
                Issue.record("No body on request")
                return (makeValidResponseData(), makeResponse(statusCode: 200))
            }
            let body = try JSONDecoder().decode(GeminiRequest.self, from: bodyData)
            #expect(body.instances.count == 1)
            #expect(body.instances[0].prompt == "a sunset")
            #expect(body.parameters.sampleCount == 1)
            return (makeValidResponseData(), makeResponse(statusCode: 200))
        }

        let client = GeminiClient(apiKey: "test-key", session: makeSession())
        _ = try await client.generateImage(prompt: "a sunset")
    }

    @Test func httpError_throwsGeminiError() async {
        MockURLProtocol.handler = { _ in
            (Data("server error".utf8), makeResponse(statusCode: 500))
        }

        let client = GeminiClient(apiKey: "test-key", session: makeSession())
        await #expect(throws: FrescoError.self) {
            try await client.generateImage(prompt: "test")
        }
    }

    @Test func httpError_includesResponseBody() async {
        MockURLProtocol.handler = { _ in
            (Data("bad request details".utf8), makeResponse(statusCode: 400))
        }

        let client = GeminiClient(apiKey: "test-key", session: makeSession())
        do {
            _ = try await client.generateImage(prompt: "test")
            Issue.record("Expected error")
        } catch {
            if case .geminiError(let message) = error {
                #expect(message.contains("bad request details"))
            } else {
                Issue.record("Wrong error case: \(error)")
            }
        }
    }

    @Test func networkError_throwsGeminiError() async {
        MockURLProtocol.handler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        let client = GeminiClient(apiKey: "test-key", session: makeSession())
        await #expect(throws: FrescoError.self) {
            try await client.generateImage(prompt: "test")
        }
    }

    @Test func malformedJSON_throwsGeminiError() async {
        MockURLProtocol.handler = { _ in
            (Data("not json".utf8), makeResponse(statusCode: 200))
        }

        let client = GeminiClient(apiKey: "test-key", session: makeSession())
        await #expect(throws: FrescoError.self) {
            try await client.generateImage(prompt: "test")
        }
    }

    @Test func emptyPredictions_throwsGeminiError() async {
        let json = Data("""
        {"predictions": []}
        """.utf8)

        MockURLProtocol.handler = { _ in
            (json, makeResponse(statusCode: 200))
        }

        let client = GeminiClient(apiKey: "test-key", session: makeSession())
        await #expect(throws: FrescoError.self) {
            try await client.generateImage(prompt: "test")
        }
    }

    @Test func invalidBase64_throwsGeminiError() async {
        let json = Data("""
        {"predictions": [{"bytesBase64Encoded": "%%%not-base64%%%"}]}
        """.utf8)

        MockURLProtocol.handler = { _ in
            (json, makeResponse(statusCode: 200))
        }

        let client = GeminiClient(apiKey: "test-key", session: makeSession())
        await #expect(throws: FrescoError.self) {
            try await client.generateImage(prompt: "test")
        }
    }
}
