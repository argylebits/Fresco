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

        #expect(request.value(forHTTPHeaderField: "x-amz-date") == "20260324T120000Z")
        #expect(request.value(forHTTPHeaderField: "x-amz-content-sha256") != nil)
        #expect(
            request.value(forHTTPHeaderField: "Authorization")
                == "AWS4-HMAC-SHA256 Credential=test-key-id/20260324/auto/s3/aws4_request, SignedHeaders=cache-control;content-type;host;x-amz-content-sha256;x-amz-date, Signature=b5dd220bfbc2df4a32ba652e4dfb5fed18b4710598639124ad531b87baefa8f1"
        )
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

    @Test func buildRequest_encodesSpecialCharactersInKey() throws {
        let client = makeClient()
        let request = try client.buildRequest(
            data: Data([0x01]),
            key: "images/my folder/test.jpg",
            contentType: "image/jpeg",
            cacheControl: "public, max-age=3600",
            date: fixedDate
        )

        #expect(request.url?.absoluteString == "https://test-account.r2.cloudflarestorage.com/test-bucket/images/my%20folder/test.jpg")
        #expect(
            request.value(forHTTPHeaderField: "Authorization")
                == "AWS4-HMAC-SHA256 Credential=test-key-id/20260324/auto/s3/aws4_request, SignedHeaders=cache-control;content-type;host;x-amz-content-sha256;x-amz-date, Signature=242757af9295abb407f4414af8d232e55281e3890f81c161de4eac034be49e54"
        )
    }

    @Test func buildCopyRequest_constructsCorrectURL() throws {
        let client = makeClient()
        let request = try client.buildCopyRequest(
            sourceKey: "images/source.jpg",
            destinationKey: "images/dest.jpg",
            date: fixedDate
        )

        #expect(request.url?.absoluteString == "https://test-account.r2.cloudflarestorage.com/test-bucket/images/dest.jpg")
        #expect(request.httpMethod == "PUT")
    }

    @Test func buildCopyRequest_setsCopySourceHeader() throws {
        let client = makeClient()
        let request = try client.buildCopyRequest(
            sourceKey: "images/source.jpg",
            destinationKey: "images/dest.jpg",
            date: fixedDate
        )

        #expect(request.value(forHTTPHeaderField: "x-amz-copy-source") == "/test-bucket/images/source.jpg")
    }

    @Test func buildCopyRequest_signsWithAWSV4() throws {
        let client = makeClient()
        let request = try client.buildCopyRequest(
            sourceKey: "images/source.jpg",
            destinationKey: "images/dest.jpg",
            date: fixedDate
        )

        #expect(request.value(forHTTPHeaderField: "x-amz-date") == "20260324T120000Z")
        #expect(
            request.value(forHTTPHeaderField: "x-amz-content-sha256")
                == "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
        )

        let auth = request.value(forHTTPHeaderField: "Authorization")
        #expect(auth?.contains("Credential=test-key-id/20260324/auto/s3/aws4_request") == true)
        #expect(
            auth?.contains("SignedHeaders=host;x-amz-content-sha256;x-amz-copy-source;x-amz-date") == true
        )
    }

    @Test func buildCopyRequest_signatureIsDeterministic() throws {
        let client = makeClient()
        let request1 = try client.buildCopyRequest(
            sourceKey: "images/source.jpg",
            destinationKey: "images/dest.jpg",
            date: fixedDate
        )
        let request2 = try client.buildCopyRequest(
            sourceKey: "images/source.jpg",
            destinationKey: "images/dest.jpg",
            date: fixedDate
        )

        #expect(
            request1.value(forHTTPHeaderField: "Authorization")
                == request2.value(forHTTPHeaderField: "Authorization")
        )
    }

    @Test func buildCopyRequest_encodesSpecialCharactersInSource() throws {
        let client = makeClient()
        let request = try client.buildCopyRequest(
            sourceKey: "images/my folder/source.jpg",
            destinationKey: "images/dest.jpg",
            date: fixedDate
        )

        #expect(request.value(forHTTPHeaderField: "x-amz-copy-source") == "/test-bucket/images/my%20folder/source.jpg")
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
            if case .r2Error(let message) = error {
                #expect(message.contains("403"))
                #expect(message.contains("forbidden"))
            } else {
                Issue.record("Wrong error case: \(error)")
            }
        }
    }
}
