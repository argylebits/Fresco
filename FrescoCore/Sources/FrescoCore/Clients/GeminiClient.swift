import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct GeminiRequest: Codable, Sendable {
    struct Instance: Codable, Sendable {
        let prompt: String
    }

    struct Parameters: Codable, Sendable {
        let sampleCount: Int
    }

    let instances: [Instance]
    let parameters: Parameters
}

struct GeminiResponse: Codable, Sendable {
    struct Prediction: Codable, Sendable {
        let bytesBase64Encoded: String
    }

    let predictions: [Prediction]
}

public struct GeminiClient: GeminiClientProtocol, Sendable {
    let apiKey: String
    let session: URLSession

    public init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    public func generateImage(prompt: String) async throws(FrescoError) -> Data {
        let request = try buildRequest(prompt: prompt)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw .geminiError("Gemini request failed: \(error.localizedDescription)")
        }

        return try handleResponse(data: data, response: response)
    }

    func buildRequest(prompt: String) throws(FrescoError) -> URLRequest {
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/imagen-4.0-generate-001:predict")
        else {
            throw .geminiError("Invalid Gemini endpoint URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = GeminiRequest(
            instances: [.init(prompt: prompt)],
            parameters: .init(sampleCount: 1)
        )
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            throw .geminiError("Failed to serialize request body: \(error.localizedDescription)")
        }

        return request
    }

    func handleResponse(data: Data, response: URLResponse) throws(FrescoError) -> Data {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw .geminiError("Invalid response")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let bodyText = String(data: data, encoding: .utf8)
            let message: String
            if let bodyText, !bodyText.isEmpty {
                message = "HTTP \(httpResponse.statusCode): \(bodyText)"
            } else {
                message = "HTTP \(httpResponse.statusCode)"
            }
            throw .geminiError(message)
        }

        let geminiResponse: GeminiResponse
        do {
            geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        } catch {
            throw .geminiError("Failed to decode response: \(error.localizedDescription)")
        }

        guard let base64String = geminiResponse.predictions.first?.bytesBase64Encoded,
            let imageData = Data(base64Encoded: base64String)
        else {
            throw .geminiError("Failed to decode image from response")
        }

        return imageData
    }
}
