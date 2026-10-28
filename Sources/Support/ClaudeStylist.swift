import Foundation

/// A closet item as sent to Claude. `index` is how Claude refers back to it.
struct ClosetEntry {
    let index: Int
    let name: String
    let category: String
    let color: String
    let notes: String
    /// A small JPEG thumbnail, or nil if the item has no photo.
    let jpeg: Data?
}

/// Claude's answer for one inspiration photo.
struct LookMatch: Decodable {
    let lookDescription: String
    let matchedItemIndices: [Int]
    let stylingTip: String
    let missingPieces: [String]
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
        case .missingAPIKey: "Add your Anthropic API key in Ideas settings first."
        case .invalidAPIKey: "Your Anthropic API key was rejected. Check it in Ideas settings."
        case .rateLimited: "Too many requests at once. Wait a moment and try again."
        case .overloaded: "Claude is busy right now. Try again in a minute."
        case .refused: "Claude couldn't help with this image."
        case .truncated: "Claude's answer was cut off. Try again."
        case .unreadableResponse: "Got an unexpected answer from Claude. Try again."
        case .server(let status, let message): "Claude returned an error (\(status)): \(message)"
        case .network(let message): "Couldn't reach Claude: \(message)"
        }
    }
}

/// Asks Claude which closet items recreate the look in an inspiration photo.
///
/// Swift has no official Anthropic SDK, so this calls the Messages API over HTTP.
struct ClaudeStylist {
    static let model = "claude-opus-5-5"
    private static let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!

    let apiKey: String
    var session: URLSession = .shared

    func match(pinImageURL: URL, closet: [ClosetEntry]) async throws -> LookMatch {
        guard !apiKey.isEmpty else { throw StylistError.missingAPIKey }
        let request = try makeRequest(pinImageURL: pinImageURL, closet: closet)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw StylistError.network(error.localizedDescription)
        }

        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        switch status {
        case 200: return try Self.decode(data, closetCount: closet.count)
        case 401, 403: throw StylistError.invalidAPIKey
        case 429: throw StylistError.rateLimited
        case 529: throw StylistError.overloaded
        default: throw StylistError.server(status: status, message: Self.errorMessage(in: data))
        }
    }

    func makeRequest(pinImageURL: URL, closet: [ClosetEntry]) throws -> URLRequest {
        var request = URLRequest(url: Self.endpoint)
        request.httpMethod = "POST"
        // Thinking on a dozen images can take a while; the default 60s is tight.
        request.timeoutInterval = 180
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
                "effort": "medium",
                "format": ["type": "json_schema", "schema": Self.responseSchema],
            ],
            "messages": [["role": "user", "content": Self.content(pinImageURL: pinImageURL, closet: closet)]],
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    private static func content(pinImageURL: URL, closet: [ClosetEntry]) -> [[String: Any]] {
        var blocks: [[String: Any]] = [
            ["type": "text", "text": "Inspiration photo:"],
            ["type": "image", "source": ["type": "url", "url": pinImageURL.absoluteString]],
            ["type": "text", "text": "My closet (\(closet.count) items):"],
        ]
        for entry in closet {
            var line = "Item \(entry.index): \(entry.name) — \(entry.category)"
            if !entry.color.isEmpty { line += ", \(entry.color)" }
            if !entry.notes.isEmpty { line += ". Notes: \(entry.notes)" }
            if entry.jpeg == nil { line += " (no photo)" }
            blocks.append(["type": "text", "text": line])

            if let jpeg = entry.jpeg {
                blocks.append(["type": "image", "source": [
                    "type": "base64",
                    "media_type": "image/jpeg",
                    "data": jpeg.base64EncodedString(),
                ]])
            }
        }
        blocks.append(["type": "text", "text": "Which of my items recreate this look?"])
        return blocks
    }

    private static let systemPrompt = """
        You are a personal stylist. The user shares an inspiration photo of an outfit \
        and photos of the clothes they own, each labelled with an item number.

        Choose the items from their closet that come closest to recreating the outfit \
        in the photo: a top and a bottom, or a dress, plus shoes and outerwear or an \
        accessory when the look includes them. Pick at most one item for each part of \
        the outfit, and use only item numbers from the list. Match on silhouette, colour \
        and formality, and look at the photos as well as the labels.

        For any part of the look the closet can't cover, add a short shopping-list \
        description to missing_pieces, such as "white leather sneakers". \
        Write look_description as one sentence describing the inspiration outfit, and \
        styling_tip as one sentence on how to wear the chosen items to get closer to it. \
        If the photo doesn't show an outfit, return no items and say so in look_description.
        """

    /// Computed rather than stored: `[String: Any]` isn't `Sendable`, so Swift 6
    /// won't allow it as a shared static constant.
    private static var responseSchema: [String: Any] {[
        "type": "object",
        "properties": [
            "look_description": ["type": "string"],
            "matched_item_indices": ["type": "array", "items": ["type": "integer"]],
            "styling_tip": ["type": "string"],
            "missing_pieces": ["type": "array", "items": ["type": "string"]],
        ],
        "required": ["look_description", "matched_item_indices", "styling_tip", "missing_pieces"],
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

    static func decode(_ data: Data, closetCount: Int) throws -> LookMatch {
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
              let match = try? decoder.decode(LookMatch.self, from: Data(json.utf8))
        else { throw StylistError.unreadableResponse }

        // The schema can't bound the numbers, so drop any that aren't real items.
        var seen = Set<Int>()
        let valid = match.matchedItemIndices.filter { (0..<closetCount).contains($0) && seen.insert($0).inserted }
        return LookMatch(
            lookDescription: match.lookDescription,
            matchedItemIndices: valid,
            stylingTip: match.stylingTip,
            missingPieces: match.missingPieces
        )
    }

    private static func errorMessage(in data: Data) -> String {
        struct ErrorBody: Decodable {
            struct Detail: Decodable { let message: String }
            let error: Detail
        }
        return (try? JSONDecoder().decode(ErrorBody.self, from: data))?.error.message ?? "Unknown error"
    }
}
