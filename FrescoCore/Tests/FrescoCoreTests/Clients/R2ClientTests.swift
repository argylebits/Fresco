import Foundation
import Testing

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

@testable import FrescoCore

private func makeSession() -> URLSession {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [MockURLProtocol.self]
    return URLSession(configuration: config)
}

private func makeClient(session: URLSession) -> R2Client {
    R2Client(
        accountId: "test-account",
        accessKeyId: "test-key-id",
        secretAccessKey: "test-secret",
        bucket: "test-bucket",
        session: session
    )
}

private func makeResponse(url: URL, statusCode: Int) -> HTTPURLResponse {
    HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
}

@Suite(.serialized)
struct R2ClientTests {
    @Test func upload_sendsCorrectURL() async throws {
        MockURLProtocol.handler = { request in
            #expect(request.url?.absoluteString == "https://test-account.r2.cloudflarestorage.com/test-bucket/images/test.jpg")
            #expect(request.httpMethod == "PUT")
            return (Data(), makeResponse(url: request.url!, statusCode: 200))
        }

        let client = makeClient(session: makeSession())
        try await client.upload(
            data: Data([0x01]),
            key: "images/test.jpg",
            contentType: "image/jpeg",
            cacheControl: "public, max-age=3600"
        )
    }

    @Test func upload_setsContentHeaders() async throws {
        MockURLProtocol.handler = { request in
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "image/jpeg")
            #expect(request.value(forHTTPHeaderField: "Cache-Control") == "public, max-age=3600")
            return (Data(), makeResponse(url: request.url!, statusCode: 200))
        }

        let client = makeClient(session: makeSession())
        try await client.upload(
            data: Data([0x01]),
            key: "images/test.jpg",
            contentType: "image/jpeg",
            cacheControl: "public, max-age=3600"
        )
    }

    @Test func upload_signsRequest() async throws {
        MockURLProtocol.handler = { request in
            let auth = request.value(forHTTPHeaderField: "Authorization")
            #expect(auth != nil)
            #expect(auth!.hasPrefix("AWS4-HMAC-SHA256"))
            #expect(request.value(forHTTPHeaderField: "x-amz-date") != nil)
            #expect(request.value(forHTTPHeaderField: "x-amz-content-sha256") != nil)
            return (Data(), makeResponse(url: request.url!, statusCode: 200))
        }

        let client = makeClient(session: makeSession())
        try await client.upload(
            data: Data([0x01]),
            key: "images/test.jpg",
            contentType: "image/jpeg",
            cacheControl: "public, max-age=3600"
        )
    }

    @Test func upload_sendsBodyData() async throws {
        let uploadData = Data([0x01, 0x02, 0x03])

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
                return (Data(), makeResponse(url: request.url!, statusCode: 200))
            }
            #expect(bodyData == uploadData)
            return (Data(), makeResponse(url: request.url!, statusCode: 200))
        }

        let client = makeClient(session: makeSession())
        try await client.upload(
            data: uploadData,
            key: "images/test.jpg",
            contentType: "image/jpeg",
            cacheControl: "public, max-age=3600"
        )
    }

    @Test func upload_httpError_throwsR2UploadError() async {
        MockURLProtocol.handler = { request in
            (Data("forbidden".utf8), makeResponse(url: request.url!, statusCode: 403))
        }

        let client = makeClient(session: makeSession())
        do {
            try await client.upload(
                data: Data([0x01]),
                key: "images/test.jpg",
                contentType: "image/jpeg",
                cacheControl: "public, max-age=3600"
            )
            Issue.record("Expected error")
        } catch {
            if case .r2UploadError(let message) = error {
                #expect(message.contains("forbidden"))
            } else {
                Issue.record("Wrong error case: \(error)")
            }
        }
    }

    @Test func upload_networkError_throwsR2UploadError() async {
        MockURLProtocol.handler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        let client = makeClient(session: makeSession())
        await #expect(throws: FrescoError.self) {
            try await client.upload(
                data: Data([0x01]),
                key: "images/test.jpg",
                contentType: "image/jpeg",
                cacheControl: "public, max-age=3600"
            )
        }
    }
}
