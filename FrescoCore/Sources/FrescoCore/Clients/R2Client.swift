import Crypto
import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct R2Client: R2ClientProtocol, Sendable {
    let accountId: String
    let accessKeyId: String
    let secretAccessKey: String
    let bucket: String
    let session: URLSession

    public init(
        accountId: String,
        accessKeyId: String,
        secretAccessKey: String,
        bucket: String,
        session: URLSession = .shared
    ) {
        self.accountId = accountId
        self.accessKeyId = accessKeyId
        self.secretAccessKey = secretAccessKey
        self.bucket = bucket
        self.session = session
    }

    public func upload(
        data: Data,
        key: String,
        contentType: String,
        cacheControl: String
    ) async throws(FrescoError) {
        let request = try buildRequest(
            data: data, key: key, contentType: contentType,
            cacheControl: cacheControl, date: Date()
        )

        let responseData: Data
        let response: URLResponse
        do {
            (responseData, response) = try await session.data(for: request)
        } catch {
            throw .r2Error("R2 upload failed: \(error.localizedDescription)")
        }

        try handleResponse(data: responseData, response: response)
    }

    public func copy(
        sourceKey: String,
        destinationKey: String
    ) async throws(FrescoError) {
        let request = try buildCopyRequest(
            sourceKey: sourceKey, destinationKey: destinationKey, date: Date()
        )

        let responseData: Data
        let response: URLResponse
        do {
            (responseData, response) = try await session.data(for: request)
        } catch {
            throw .r2Error("R2 copy failed: \(error.localizedDescription)")
        }

        try handleResponse(data: responseData, response: response)
    }

    func buildCopyRequest(
        sourceKey: String,
        destinationKey: String,
        date: Date
    ) throws(FrescoError) -> URLRequest {
        let host = "\(accountId).r2.cloudflarestorage.com"

        guard let baseURL = URL(string: "https://\(host)") else {
            throw .r2Error("Invalid R2 endpoint URL")
        }

        let url = baseURL.appendingPathComponent(bucket).appendingPathComponent(destinationKey)
        let path = url.path(percentEncoded: true)

        let amzDate = date.formatted(
            .iso8601.year().month().day()
                .time(includingFractionalSeconds: false)
                .timeSeparator(.omitted).dateSeparator(.omitted)
                .timeZone(separator: .omitted)
        )
        let dateStamp = String(amzDate.prefix(8))

        let rawCopySource = "/\(bucket)/\(sourceKey)"
        let copySource = rawCopySource.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? rawCopySource
        let payloadHash = sha256Hex(Data())

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue(host, forHTTPHeaderField: "Host")
        request.setValue(copySource, forHTTPHeaderField: "x-amz-copy-source")
        request.setValue(amzDate, forHTTPHeaderField: "x-amz-date")
        request.setValue(payloadHash, forHTTPHeaderField: "x-amz-content-sha256")

        let signedHeaders = "host;x-amz-content-sha256;x-amz-copy-source;x-amz-date"
        let canonicalHeaders = [
            "host:\(host)",
            "x-amz-content-sha256:\(payloadHash)",
            "x-amz-copy-source:\(copySource)",
            "x-amz-date:\(amzDate)\n",
        ].joined(separator: "\n")

        let canonicalRequest = [
            "PUT",
            path,
            "",
            canonicalHeaders,
            signedHeaders,
            payloadHash,
        ].joined(separator: "\n")

        let region = "auto"
        let service = "s3"
        let credentialScope = "\(dateStamp)/\(region)/\(service)/aws4_request"

        let stringToSign = [
            "AWS4-HMAC-SHA256",
            amzDate,
            credentialScope,
            sha256Hex(Data(canonicalRequest.utf8)),
        ].joined(separator: "\n")

        let signingKey = deriveSigningKey(
            secretKey: secretAccessKey,
            dateStamp: dateStamp,
            region: region,
            service: service
        )

        let signature = hmacSHA256Hex(key: signingKey, data: Data(stringToSign.utf8))

        let authorization =
            "AWS4-HMAC-SHA256 Credential=\(accessKeyId)/\(credentialScope), SignedHeaders=\(signedHeaders), Signature=\(signature)"
        request.setValue(authorization, forHTTPHeaderField: "Authorization")

        return request
    }

    func buildRequest(
        data: Data,
        key: String,
        contentType: String,
        cacheControl: String,
        date: Date
    ) throws(FrescoError) -> URLRequest {
        let host = "\(accountId).r2.cloudflarestorage.com"

        guard let baseURL = URL(string: "https://\(host)") else {
            throw .r2Error("Invalid R2 endpoint URL")
        }

        let url = baseURL.appendingPathComponent(bucket).appendingPathComponent(key)
        let path = url.path(percentEncoded: true)

        let amzDate = date.formatted(
            .iso8601.year().month().day()
                .time(includingFractionalSeconds: false)
                .timeSeparator(.omitted).dateSeparator(.omitted)
                .timeZone(separator: .omitted)
        )
        let dateStamp = String(amzDate.prefix(8))

        let payloadHash = sha256Hex(data)

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = data
        request.setValue(host, forHTTPHeaderField: "Host")
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.setValue(cacheControl, forHTTPHeaderField: "Cache-Control")
        request.setValue(amzDate, forHTTPHeaderField: "x-amz-date")
        request.setValue(payloadHash, forHTTPHeaderField: "x-amz-content-sha256")

        let signedHeaders = "cache-control;content-type;host;x-amz-content-sha256;x-amz-date"
        let canonicalHeaders = [
            "cache-control:\(cacheControl)",
            "content-type:\(contentType)",
            "host:\(host)",
            "x-amz-content-sha256:\(payloadHash)",
            "x-amz-date:\(amzDate)\n",
        ].joined(separator: "\n")

        let canonicalRequest = [
            "PUT",
            path,
            "",
            canonicalHeaders,
            signedHeaders,
            payloadHash,
        ].joined(separator: "\n")

        let region = "auto"
        let service = "s3"
        let credentialScope = "\(dateStamp)/\(region)/\(service)/aws4_request"

        let stringToSign = [
            "AWS4-HMAC-SHA256",
            amzDate,
            credentialScope,
            sha256Hex(Data(canonicalRequest.utf8)),
        ].joined(separator: "\n")

        let signingKey = deriveSigningKey(
            secretKey: secretAccessKey,
            dateStamp: dateStamp,
            region: region,
            service: service
        )

        let signature = hmacSHA256Hex(key: signingKey, data: Data(stringToSign.utf8))

        let authorization =
            "AWS4-HMAC-SHA256 Credential=\(accessKeyId)/\(credentialScope), SignedHeaders=\(signedHeaders), Signature=\(signature)"
        request.setValue(authorization, forHTTPHeaderField: "Authorization")

        return request
    }

    func handleResponse(data: Data, response: URLResponse) throws(FrescoError) {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw .r2Error("Invalid response")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let bodyText = String(data: data, encoding: .utf8)
            let message: String
            if let bodyText, !bodyText.isEmpty {
                message = "HTTP \(httpResponse.statusCode): \(bodyText)"
            } else {
                message = "HTTP \(httpResponse.statusCode)"
            }
            throw .r2Error(message)
        }
    }

    private func sha256Hex(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    private func hmacSHA256(key: SymmetricKey, data: Data) -> Data {
        Data(HMAC<SHA256>.authenticationCode(for: data, using: key))
    }

    private func hmacSHA256Hex(key: SymmetricKey, data: Data) -> String {
        HMAC<SHA256>.authenticationCode(for: data, using: key)
            .map { String(format: "%02x", $0) }.joined()
    }

    private func deriveSigningKey(
        secretKey: String,
        dateStamp: String,
        region: String,
        service: String
    ) -> SymmetricKey {
        let kSecret = SymmetricKey(data: Data("AWS4\(secretKey)".utf8))
        let kDate = hmacSHA256(key: kSecret, data: Data(dateStamp.utf8))
        let kRegion = hmacSHA256(key: SymmetricKey(data: kDate), data: Data(region.utf8))
        let kService = hmacSHA256(key: SymmetricKey(data: kRegion), data: Data(service.utf8))
        let kSigning = hmacSHA256(key: SymmetricKey(data: kService), data: Data("aws4_request".utf8))
        return SymmetricKey(data: kSigning)
    }
}
