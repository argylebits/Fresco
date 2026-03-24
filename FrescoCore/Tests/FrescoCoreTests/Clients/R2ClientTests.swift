import Foundation
import Testing

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

@testable import FrescoCore

private let fixedDate: Date = {
    var components = DateComponents()
    components.year = 2026
    components.month = 3
    components.day = 24
    components.hour = 12
    components.minute = 0
    components.second = 0
    components.timeZone = TimeZone(identifier: "UTC")
    return Calendar(identifier: .gregorian).date(from: components)!
}()

private func makeClient() -> R2Client {
    R2Client(
        accountId: "test-account",
        accessKeyId: "test-key-id",
        secretAccessKey: "test-secret",
        bucket: "test-bucket"
    )
}

struct R2ClientTests {
    @Test func buildRequest_constructsCorrectURL() throws {
        let client = makeClient()
        let request = try client.buildRequest(
            data: Data([0x01]),
            key: "images/test.jpg",
            contentType: "image/jpeg",
            cacheControl: "public, max-age=3600",
            date: fixedDate
        )

        #expect(request.url?.absoluteString == "https://test-account.r2.cloudflarestorage.com/test-bucket/images/test.jpg")
        #expect(request.httpMethod == "PUT")
    }

    @Test func buildRequest_setsContentHeaders() throws {
        let client = makeClient()
        let request = try client.buildRequest(
            data: Data([0x01]),
            key: "images/test.jpg",
            contentType: "image/jpeg",
            cacheControl: "public, max-age=3600",
            date: fixedDate
        )

        #expect(request.value(forHTTPHeaderField: "Content-Type") == "image/jpeg")
        #expect(request.value(forHTTPHeaderField: "Cache-Control") == "public, max-age=3600")
    }

    @Test func buildRequest_signsWithAWSV4() throws {
        let client = makeClient()
        let request = try client.buildRequest(
            data: Data([0x01]),
            key: "images/test.jpg",
            contentType: "image/jpeg",
            cacheControl: "public, max-age=3600",
            date: fixedDate
        )

        let auth = request.value(forHTTPHeaderField: "Authorization")
        #expect(auth != nil)
        #expect(auth!.hasPrefix("AWS4-HMAC-SHA256 Credential=test-key-id/20260324/auto/s3/aws4_request"))
        #expect(request.value(forHTTPHeaderField: "x-amz-date") == "20260324T120000Z")
        #expect(request.value(forHTTPHeaderField: "x-amz-content-sha256") != nil)
    }

    @Test func buildRequest_signatureIsDeterministic() throws {
        let client = makeClient()
        let data = Data([0x01, 0x02, 0x03])

        let request1 = try client.buildRequest(
            data: data, key: "test.jpg", contentType: "image/jpeg",
            cacheControl: "public, max-age=3600", date: fixedDate
        )
        let request2 = try client.buildRequest(
            data: data, key: "test.jpg", contentType: "image/jpeg",
            cacheControl: "public, max-age=3600", date: fixedDate
        )

        #expect(request1.value(forHTTPHeaderField: "Authorization") == request2.value(forHTTPHeaderField: "Authorization"))
    }

    @Test func handleResponse_successDoesNotThrow() throws {
        let client = makeClient()
        let url = URL(string: "https://example.com")!
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!

        try client.handleResponse(data: Data(), response: response)
    }

    @Test func handleResponse_httpError_throwsWithBody() throws {
        let client = makeClient()
        let url = URL(string: "https://example.com")!
        let response = HTTPURLResponse(url: url, statusCode: 403, httpVersion: nil, headerFields: nil)!

        do {
            try client.handleResponse(data: Data("forbidden".utf8), response: response)
            Issue.record("Expected error")
        } catch {
            if case .r2UploadError(let message) = error {
                #expect(message.contains("403"))
                #expect(message.contains("forbidden"))
            } else {
                Issue.record("Wrong error case: \(error)")
            }
        }
    }
}
