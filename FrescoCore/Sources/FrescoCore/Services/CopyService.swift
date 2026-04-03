import Foundation

public struct CopyService: Sendable {
    public let r2: any R2ClientProtocol
    public let publicBaseURL: String

    public init(r2: any R2ClientProtocol, publicBaseURL: String) {
        self.r2 = r2
        self.publicBaseURL = publicBaseURL
    }

    public func copy(sourceFilename: String, destinationFilename: String, slug: String) async throws(FrescoError) -> UploadResult {
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

        let validatedSource = try FilenameValidator.validate(sourceFilename)
        let validatedDestination = try FilenameValidator.validate(destinationFilename)

        let sourceKey = "\(slug)/\(validatedSource)"
        let destinationKey = "\(slug)/\(validatedDestination)"

        try await r2.copy(sourceKey: sourceKey, destinationKey: destinationKey)

        let publicURL = baseURL
            .appendingPathComponent(slug)
            .appendingPathComponent(validatedDestination)

        return UploadResult(r2Key: destinationKey, publicURL: publicURL)
    }
}
