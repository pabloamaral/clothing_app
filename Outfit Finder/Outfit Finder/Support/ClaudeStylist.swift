import Foundation

/// What Claude saw in an inspiration photo. Category and colour come back as
/// the raw values of `Category` and `ColorFamily`.
struct LookAnalysis: Decodable {
    struct Piece: Decodable {
        let category: String
        let colorFamily: String
        let colorName: String
        let description: String
    }

    let title: String
    let pieces: [Piece]
}

enum StylistError: LocalizedError {
    case missingAPIKey
    case invalidAPIKey
    case rateLimited
    case overloaded
    case refused
    case truncated
    case unreadableResponse
    case server(status: Int, message: String)
    case network(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey: "Add your Anthropic API key in settings to detect pieces automatically."
        case .invalidAPIKey: "Your Anthropic API key was rejected. Check it in settings."
        case .rateLimited: "Too many requests at once. Wait a moment and try again."
        case .overloaded: "Claude is busy right now. Try again in a minute."
        case .refused: "Claude couldn't help with this photo."
        case .truncated: "Claude's answer was cut off. Try again."
        case .unreadableResponse: "Got an unexpected answer from Claude. Try again."
        case .server(let status, let message): "Claude returned an error (\(status)): \(message)"
        case .network(let message): "Couldn't reach Claude: \(message)"
        }
    }
}

/// Asks Claude to list the garments in an outfit photo.
///
/// Swift has no official Anthropic SDK, so this calls the Messages API over HTTP.
struct ClaudeStylist {
    static let model = "claude-opus-5-5"
    private static let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!

    let apiKey: String
    var session: URLSession = .shared

    func analyzeLook(jpeg: Data) async throws -> LookAnalysis {
        guard !apiKey.isEmpty else { throw StylistError.missingAPIKey }
        let request = try makeRequest(jpeg: jpeg)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw StylistError.network(error.localizedDescription)
        }

        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        switch status {
        case 200: return try Self.decode(data)
        case 401, 403: throw StylistError.invalidAPIKey
        case 429: throw StylistError.rateLimited
        case 529: throw StylistError.overloaded
        default: throw StylistError.server(status: status, message: Self.errorMessage(in: data))
        }
    }

    func makeRequest(jpeg: Data) throws -> URLRequest {
        var request = URLRequest(url: Self.endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 120
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2026-10-21", forHTTPHeaderField: "anthropic-version")
        request.setValue("server-side-fallback-2026-07-01", forHTTPHeaderField: "anthropic-beta")

        let body: [String: Any] = [
            "model": Self.model,
            "max_tokens": 16000,
            // If a safety classifier declines, the API retries on a
            // recommended fallback model instead of failing outright.
            "fallbacks": "default",
            "system": Self.systemPrompt,
            "output_config": [
                // Naming garments and colours is perception, not reasoning,
                // so deeper thinking adds cost without better answers.
                "effort": "low",
                "format": ["type": "json_schema", "schema": Self.responseSchema],
            ],
            "messages": [[
                "role": "user",
                "content": [
                    ["type": "image", "source": [
                        "type": "base64",
                        "media_type": "image/jpeg",
                        "data": jpeg.base64EncodedString(),
                    ]],
                    ["type": "text", "text": "List the pieces in this outfit."],
                ],
            ]],
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    private static let systemPrompt = """
        You catalogue outfits from photos so they can be recreated from someone's own wardrobe.

        List each clothing item and accessory worn by the main person in the photo that is \
        clearly visible, one entry per item, ordered outerwear, top, bottom or dress, shoes, \
        then accessories. Skip items you can only guess at.

        For each piece:
        - category: the closest of the allowed values. Jackets, coats and blazers worn \
        over another top are outerwear.
        - color_family: the closest allowed value for the item's main colour. Use \
        multicolor for prints and patterns where no single colour dominates.
        - color_name: a specific everyday colour name, such as olive, cream or charcoal.
        - description: a few words on the cut and fabric, without the colour, such as \
        "wide-leg chinos" or "cropped denim jacket".

        title: a short name for the overall look, under six words, such as \
        "Smart casual autumn layers". If the photo doesn't show an outfit, return a \
        title saying so and no pieces.
        """

    /// Built from the app's enums so the allowed values can't drift from them.
    /// Computed because `[String: Any]` can't be a shared static constant in Swift 6.
    private static var responseSchema: [String: Any] {[
        "type": "object",
        "properties": [
            "title": ["type": "string"],
            "pieces": [
                "type": "array",
                "items": [
                    "type": "object",
                    "properties": [
                        "category": ["type": "string", "enum": Category.allCases.map(\.rawValue)],
                        "color_family": [
                            "type": "string",
                            "enum": ColorFamily.allCases.filter { $0 != .unknown }.map(\.rawValue),
                        ],
                        "color_name": ["type": "string"],
                        "description": ["type": "string"],
                    ],
                    "required": ["category", "color_family", "color_name", "description"],
                    "additionalProperties": false,
                ],
            ],
        ],
        "required": ["title", "pieces"],
        "additionalProperties": false,
    ]}

    private struct MessageResponse: Decodable {
        struct Block: Decodable {
            let type: String
            let text: String?
        }
        let content: [Block]
        let stopReason: String?
    }

    static func decode(_ data: Data) throws -> LookAnalysis {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        guard let message = try? decoder.decode(MessageResponse.self, from: data) else {
            throw StylistError.unreadableResponse
        }
        // A refusal can arrive as a normal 200, with content that won't match the schema.
        switch message.stopReason {
        case "refusal": throw StylistError.refused
        case "max_tokens": throw StylistError.truncated
        default: break
        }

        // Thinking blocks come first; the JSON answer is in the text block.
        guard let json = message.content.last(where: { $0.type == "text" })?.text,
              let analysis = try? decoder.decode(LookAnalysis.self, from: Data(json.utf8))
        else { throw StylistError.unreadableResponse }
        return analysis
    }

    private static func errorMessage(in data: Data) -> String {
        struct ErrorBody: Decodable {
            struct Detail: Decodable { let message: String }
            let error: Detail
        }
        return (try? JSONDecoder().decode(ErrorBody.self, from: data))?.error.message ?? "Unknown error"
    }
}
