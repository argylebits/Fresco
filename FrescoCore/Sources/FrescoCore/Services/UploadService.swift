import Foundation

public struct UploadService: Sendable {
    public let r2: any R2ClientProtocol
    public let publicBaseURL: String

    public init(r2: any R2ClientProtocol, publicBaseURL: String) {
        self.r2 = r2
        self.publicBaseURL = publicBaseURL
    }

    public func upload(filePath: String, slug: String) async throws(FrescoError) -> UploadResult {
        let fileURL = URL(fileURLWithPath: filePath)
        let filename = fileURL.lastPathComponent

        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch {
            throw FrescoError.fileWriteError("Failed to read file at \(filePath): \(error.localizedDescription)")
        }

        let format = ImageFormat.detect(from: data)
        let key = "\(slug)/\(filename)"

        try await r2.upload(
            data: data,
            key: key,
            contentType: format.contentType,
            cacheControl: "public, max-age=31536000"
        )

        guard let baseURL = URL(string: publicBaseURL) else {
            throw FrescoError.configurationError("Invalid publicBaseURL: \(publicBaseURL)")
        }

        let publicURL = baseURL
            .appendingPathComponent(slug)
            .appendingPathComponent(filename)

        return UploadResult(r2Key: key, publicURL: publicURL)
    }
}
