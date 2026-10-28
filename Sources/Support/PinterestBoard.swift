import Foundation

/// One image from a Pinterest board.
struct InspirationPin: Identifiable, Hashable {
    /// The pin's page URL, which is unique per pin.
    let id: String
    let title: String
    let imageURL: URL
}

enum PinterestError: LocalizedError {
    case notABoardLink
    case boardNotFound
    case emptyBoard
    case unreachable

    var errorDescription: String? {
        switch self {
        case .notABoardLink:
            "That isn't a board link. In Pinterest, open the board, tap Share, then Copy link."
        case .boardNotFound:
            "Couldn't find that board. Check it's public — secret boards can't be read."
        case .emptyBoard:
            "That board has no pins yet."
        case .unreachable:
            "Couldn't reach Pinterest. Check your connection and try again."
        }
    }
}

/// Reads a public board through its RSS feed, which needs no Pinterest
/// developer account. The feed only carries the 25 most recent pins.
enum PinterestBoard {
    /// First path segments that belong to Pinterest pages rather than users.
    private static let nonBoardPaths: Set<String> = ["pin", "search", "ideas", "today", "_", "settings"]

    static func fetchPins(fromLink link: String, session: URLSession = .shared) async throws -> [InspirationPin] {
        let boardURL = try await resolve(link, session: session)
        let feed = try feedURL(forBoardURL: boardURL)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: feed)
        } catch {
            throw PinterestError.unreachable
        }
        if let http = response as? HTTPURLResponse, http.statusCode == 404 {
            throw PinterestError.boardNotFound
        }

        let pins = parse(data)
        if pins.isEmpty { throw PinterestError.emptyBoard }
        return pins
    }

    /// The Pinterest app's Share button produces `pin.it` short links, which
    /// only reveal the board once their redirect is followed.
    private static func resolve(_ link: String, session: URLSession) async throws -> URL {
        let trimmed = link.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed.contains("://") ? trimmed : "https://\(trimmed)"),
              let host = url.host?.lowercased()
        else { throw PinterestError.notABoardLink }

        guard host == "pin.it" else { return url }
        do {
            let (_, response) = try await session.data(from: url)
            guard let resolved = response.url else { throw PinterestError.notABoardLink }
            return resolved
        } catch let error as PinterestError {
            throw error
        } catch {
            throw PinterestError.unreachable
        }
    }

    /// `pinterest.com/<user>/<board>/…` → `www.pinterest.com/<user>/<board>.rss`.
    /// Country domains such as pinterest.co.uk are accepted too.
    static func feedURL(forBoardURL url: URL) throws -> URL {
        guard let host = url.host?.lowercased(), host.contains("pinterest.") else {
            throw PinterestError.notABoardLink
        }
        let parts = url.pathComponents.filter { $0 != "/" }
        guard parts.count >= 2, !nonBoardPaths.contains(parts[0].lowercased()) else {
            throw PinterestError.notABoardLink
        }

        var components = URLComponents()
        components.scheme = "https"
        components.host = "www.pinterest.com"
        components.path = "/\(parts[0])/\(parts[1]).rss"
        guard let feed = components.url else { throw PinterestError.notABoardLink }
        return feed
    }

    static func parse(_ data: Data) -> [InspirationPin] {
        let delegate = FeedParser()
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        parser.parse()
        return delegate.pins
    }
}

/// Collects `<item>` entries. Each item's image only appears inside the HTML
/// of its `<description>`, so that is where the URL is pulled from.
private final class FeedParser: NSObject, XMLParserDelegate {
    private(set) var pins: [InspirationPin] = []

    private var inItem = false
    private var currentElement = ""
    private var title = ""
    private var link = ""
    private var descriptionHTML = ""

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        currentElement = elementName
        if elementName == "item" {
            inItem = true
            title = ""
            link = ""
            descriptionHTML = ""
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard inItem else { return }
        switch currentElement {
        case "title": title += string
        case "link": link += string
        case "description": descriptionHTML += string
        default: break
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?) {
        currentElement = ""
        guard elementName == "item" else { return }
        inItem = false

        if let imageURL = Self.imageURL(in: descriptionHTML) {
            let id = link.trimmingCharacters(in: .whitespacesAndNewlines)
            pins.append(InspirationPin(
                id: id.isEmpty ? imageURL.absoluteString : id,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                imageURL: imageURL
            ))
        }
    }

    /// The feed links 236px thumbnails, too small to make out clothing
    /// details, so the URL is swapped for the 736px rendition of the same image.
    private static func imageURL(in html: String) -> URL? {
        guard let match = html.firstMatch(of: #/<img[^>]+src="([^"]+)"/#) else { return nil }
        let upgraded = String(match.1).replacingOccurrences(of: "/236x/", with: "/736x/")
        return URL(string: upgraded)
    }
}
