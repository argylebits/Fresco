import Foundation

public struct UploadService: Sendable {
    public let r2: any R2ClientProtocol
    public let publicBaseURL: String

    public init(r2: any R2ClientProtocol, publicBaseURL: String) {
        self.r2 = r2
        self.publicBaseURL = publicBaseURL
    }

    public func upload(filePath: String, slug: String, destinationFilename: String? = nil) async throws(FrescoError) -> UploadResult {
        let slug = try SlugValidator.validate(slug)

        guard
            !publicBaseURL.isEmpty,
            let baseURL = URL(string: publicBaseURL),
            let scheme = baseURL.scheme?.lowercased(),
            ["http", "https"].contains(scheme),
            baseURL.host != nil
        else {
            throw FrescoError.configurationError("Invalid publicBaseURL: \(publicBaseURL)")
        }

        let fileURL = URL(fileURLWithPath: filePath)
        let filename = try FilenameValidator.validate(destinationFilename ?? fileURL.lastPathComponent)

        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch {
            throw FrescoError.fileReadError("Failed to read file at \(filePath): \(error.localizedDescription)")
        }

        let format = try ImageFormat.detect(from: data)
        let key = "\(slug)/\(filename)"

        try await r2.upload(
            data: data,
            key: key,
            contentType: format.contentType,
            cacheControl: "public, max-age=31536000"
        )

        let publicURL = baseURL
            .appendingPathComponent(slug)
            .appendingPathComponent(filename)

        return UploadResult(r2Key: key, publicURL: publicURL)
    }
}
