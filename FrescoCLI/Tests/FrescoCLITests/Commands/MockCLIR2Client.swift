import Foundation
import FrescoCore

struct MockCLIR2Client: R2ClientProtocol {
    var shouldThrow: FrescoError?

    func upload(data: Data, key: String, contentType: String, cacheControl: String) async throws(FrescoError) {
        if let error = shouldThrow { throw error }
    }
}
