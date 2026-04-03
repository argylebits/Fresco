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

        guard !sourceFilename.isEmpty, sourceFilename != ".", sourceFilename != ".." else {
            throw FrescoError.configurationError("Invalid source filename: \(sourceFilename)")
        }

        guard !destinationFilename.isEmpty, destinationFilename != ".", destinationFilename != ".." else {
            throw FrescoError.configurationError("Invalid destination filename: \(destinationFilename)")
        }

        let sourceKey = "\(slug)/\(sourceFilename)"
        let destinationKey = "\(slug)/\(destinationFilename)"

        try await r2.copy(sourceKey: sourceKey, destinationKey: destinationKey)

        let publicURL = baseURL
            .appendingPathComponent(slug)
            .appendingPathComponent(destinationFilename)

        return UploadResult(r2Key: destinationKey, publicURL: publicURL)
    }
}
