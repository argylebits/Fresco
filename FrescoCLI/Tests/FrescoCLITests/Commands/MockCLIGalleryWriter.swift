import FrescoCore
@testable import FrescoCLI

struct MockCLIGalleryWriter: GalleryWriterProtocol {
    var shouldThrow: FrescoError?

    func appendEntry(to galleryPath: String, date: String, imageURL: String) throws(FrescoError) {
        if let error = shouldThrow { throw error }
    }
}
