import Foundation

public struct GeminiClient: GeminiClientProtocol, Sendable {
    public let apiKey: String
    public let session: URLSession

    public init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    public func generateImage(prompt: String) async throws(FrescoError) -> Data {
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/imagen-3.0-generate-002:predict")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "instances": [["prompt": prompt]],
            "parameters": ["sampleCount": 1]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw .geminiError(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw .geminiError("Invalid response")
        }

        guard httpResponse.statusCode == 200 else {
            let message = String(data: data, encoding: .utf8) ?? "HTTP \(httpResponse.statusCode)"
            throw .geminiError(message)
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let predictions = json["predictions"] as? [[String: Any]],
              let first = predictions.first,
              let base64String = first["bytesBase64Encoded"] as? String,
              let imageData = Data(base64Encoded: base64String) else {
            throw .geminiError("Failed to decode image from response")
        }

        return imageData
    }
}
