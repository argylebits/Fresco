import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct GeminiRequest: Codable, Sendable {
    struct Content: Codable, Sendable {
        struct Part: Codable, Sendable {
            let text: String
        }

        let parts: [Part]
    }

    struct GenerationConfig: Codable, Sendable {
        let responseModalities: [String]
    }

    let contents: [Content]
    let generationConfig: GenerationConfig
}

struct GeminiResponse: Codable, Sendable {
    struct Candidate: Codable, Sendable {
        struct Content: Codable, Sendable {
            struct Part: Codable, Sendable {
                let inlineData: InlineData?

                struct InlineData: Codable, Sendable {
                    let mimeType: String
                    let data: String
                }
            }

            let parts: [Part]
        }

        let content: Content
    }

    let candidates: [Candidate]
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
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent")
        else {
            throw .geminiError("Invalid Gemini endpoint URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = GeminiRequest(
            contents: [.init(parts: [.init(text: prompt)])],
            generationConfig: .init(responseModalities: ["IMAGE", "TEXT"])
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

        guard let imagePart = geminiResponse.candidates.first?.content.parts.first(where: { $0.inlineData != nil }),
            let inlineData = imagePart.inlineData,
            let imageData = Data(base64Encoded: inlineData.data)
        else {
            throw .geminiError("Failed to decode image from response")
        }

        return imageData
    }
}
