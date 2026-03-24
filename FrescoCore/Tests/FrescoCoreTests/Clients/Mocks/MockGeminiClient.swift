import Foundation
@testable import FrescoCore

final class MockGeminiClient: GeminiClientProtocol, Sendable {
    enum Behaviour: Sendable {
        case success(Data)
        case failure(FrescoError)
    }

    let behaviour: Behaviour

    init(behaviour: Behaviour) {
        self.behaviour = behaviour
    }

    func generateImage(prompt: String) async throws(FrescoError) -> Data {
        switch behaviour {
        case .success(let data):
            return data
        case .failure(let error):
            throw error
        }
    }
}
