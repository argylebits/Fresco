import FrescoCore

protocol GalleryWriterProtocol: Sendable {
    func appendEntry(to galleryPath: String, date: String, imageURL: String) throws(FrescoError)
}
