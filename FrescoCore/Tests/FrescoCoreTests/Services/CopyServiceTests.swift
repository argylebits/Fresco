import Foundation
import Synchronization
import Testing

@testable import FrescoCore

@Suite("CopyService")
struct CopyServiceTests {
    private static let testSlug = "my-wallpaper"
    private static let testPublicBaseURL = "https://cdn.example.com"

    @Test("copy calls R2 with correct source and destination keys")
    func copySendsCorrectKeys() async throws {
        let receivedSourceKey = Mutex<String?>(nil)
        let receivedDestinationKey = Mutex<String?>(nil)
        let r2 = MockR2Client(onCopy: { source, destination in
            receivedSourceKey.withLock { $0 = source }
            receivedDestinationKey.withLock { $0 = destination }
        })

        let service = CopyService(r2: r2, publicBaseURL: Self.testPublicBaseURL)

        _ = try await service.copy(
            sourceFilename: "2026-04-02-150000.jpg",
            destinationFilename: "latest.jpg",
            slug: Self.testSlug
        )

        #expect(receivedSourceKey.withLock { $0 } == "my-wallpaper/2026-04-02-150000.jpg")
        #expect(receivedDestinationKey.withLock { $0 } == "my-wallpaper/latest.jpg")
    }

    @Test("copy returns correct public URL")
    func copyReturnsPublicURL() async throws {
        let service = CopyService(
            r2: MockR2Client(),
            publicBaseURL: Self.testPublicBaseURL
        )

        let result = try await service.copy(
            sourceFilename: "2026-04-02-150000.jpg",
            destinationFilename: "latest.jpg",
            slug: Self.testSlug
        )

        #expect(result.publicURL == URL(string: "https://cdn.example.com/my-wallpaper/latest.jpg")!)
        #expect(result.r2Key == "my-wallpaper/latest.jpg")
    }

    @Test("copy throws when R2 fails")
    func copyThrowsOnR2Error() async throws {
        let service = CopyService(
            r2: MockR2Client(shouldThrow: .r2Error("copy failed")),
            publicBaseURL: Self.testPublicBaseURL
        )

        await #expect(throws: FrescoError.self) {
            try await service.copy(
                sourceFilename: "2026-04-02-150000.jpg",
                destinationFilename: "latest.jpg",
                slug: Self.testSlug
            )
        }
    }

    @Test("copy throws on invalid slug")
    func copyThrowsOnInvalidSlug() async throws {
        let service = CopyService(
            r2: MockR2Client(),
            publicBaseURL: Self.testPublicBaseURL
        )

        await #expect(throws: FrescoError.self) {
            try await service.copy(
                sourceFilename: "2026-04-02-150000.jpg",
                destinationFilename: "latest.jpg",
                slug: "../etc"
            )
        }
    }

    @Test("copy throws on invalid publicBaseURL")
    func copyThrowsOnInvalidBaseURL() async throws {
        let copyCalled = Mutex(false)
        let r2 = MockR2Client(onCopy: { _, _ in
            copyCalled.withLock { $0 = true }
        })

        let service = CopyService(r2: r2, publicBaseURL: "")

        await #expect(throws: FrescoError.self) {
            try await service.copy(
                sourceFilename: "2026-04-02-150000.jpg",
                destinationFilename: "latest.jpg",
                slug: Self.testSlug
            )
        }

        #expect(copyCalled.withLock { $0 } == false)
    }

    @Test("copy throws on empty source filename")
    func copyThrowsOnEmptySource() async throws {
        let service = CopyService(
            r2: MockR2Client(),
            publicBaseURL: Self.testPublicBaseURL
        )

        await #expect(throws: FrescoError.self) {
            try await service.copy(
                sourceFilename: "",
                destinationFilename: "latest.jpg",
                slug: Self.testSlug
            )
        }
    }

    @Test("copy throws on empty destination filename")
    func copyThrowsOnEmptyDestination() async throws {
        let service = CopyService(
            r2: MockR2Client(),
            publicBaseURL: Self.testPublicBaseURL
        )

        await #expect(throws: FrescoError.self) {
            try await service.copy(
                sourceFilename: "2026-04-02-150000.jpg",
                destinationFilename: "",
                slug: Self.testSlug
            )
        }
    }
}
