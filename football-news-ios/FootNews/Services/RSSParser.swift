import Foundation

// MARK: - Raw feed item (intermediate before scoring)

struct RawFeedItem {
    let id: String
    let title: String
    let url: URL
    let summary: String?
    let publishedAt: Date
    let author: String?
    let imageURL: URL?
}

// MARK: - RSS/Atom Parser

final class RSSParser: NSObject, XMLParserDelegate {

    private var items: [RawFeedItem] = []
    private var currentElement = ""
    private var currentTitle = ""
    private var currentLink = ""
    private var currentSummary = ""
    private var currentPubDate = ""
    private var currentAuthor = ""
    private var currentEnclosureURL: String? = nil
    private var isItem = false
    private var isAtom = false

    // Detect atom:link href
    private var pendingAtomLink: String? = nil

    static func parse(data: Data) -> [RawFeedItem] {
        let parser = RSSParser()
        let xmlParser = XMLParser(data: data)
        xmlParser.delegate = parser
        xmlParser.parse()
        return parser.items
    }

    // MARK: - XMLParserDelegate

    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName: String?,
                attributes: [String: String]) {
        currentElement = elementName.lowercased()

        switch currentElement {
        case "item", "entry":
            isItem = true
            isAtom = currentElement == "entry"
            currentTitle = ""
            currentLink = ""
            currentSummary = ""
            currentPubDate = ""
            currentAuthor = ""
            currentEnclosureURL = nil

        case "link":
            // Atom: <link href="..." rel="alternate"/>
            if let href = attributes["href"],
               attributes["rel"] == "alternate" || attributes["rel"] == nil {
                pendingAtomLink = href
            }

        case "enclosure":
            if let url = attributes["url"],
               attributes["type"]?.hasPrefix("image") == true || attributes["type"] == nil {
                currentEnclosureURL = url
            }

        case "media:content", "media:thumbnail":
            if let url = attributes["url"], currentEnclosureURL == nil {
                currentEnclosureURL = url
            }

        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, isItem else { return }

        switch currentElement {
        case "title":
            currentTitle += trimmed
        case "link":
            currentLink += trimmed
        case "description", "summary", "content", "content:encoded":
            currentSummary += trimmed
        case "pubdate", "published", "updated", "dc:date":
            currentPubDate += trimmed
        case "author", "dc:creator", "name":
            currentAuthor += trimmed
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName: String?) {
        let lower = elementName.lowercased()

        // Resolve atom link
        if lower == "link", let href = pendingAtomLink {
            if isItem { currentLink = href }
            pendingAtomLink = nil
        }

        guard lower == "item" || lower == "entry", isItem else { return }
        isItem = false

        let linkStr = currentLink.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: linkStr), !currentTitle.isEmpty else { return }

        let summaryClean = stripHTML(currentSummary).prefix(500)
        let published = parseDate(currentPubDate.trimmingCharacters(in: .whitespacesAndNewlines))
        let imgURL = currentEnclosureURL.flatMap { URL(string: $0) }
                  ?? extractFirstImageURL(from: currentSummary)

        let idStr = String(Data(linkStr.utf8).base64EncodedString().prefix(16))

        items.append(RawFeedItem(
            id: idStr,
            title: currentTitle.trimmingCharacters(in: .whitespacesAndNewlines),
            url: url,
            summary: summaryClean.isEmpty ? nil : String(summaryClean),
            publishedAt: published,
            author: currentAuthor.isEmpty ? nil : currentAuthor,
            imageURL: imgURL
        ))
    }

    // MARK: - Helpers

    private func stripHTML(_ html: String) -> String {
        guard !html.isEmpty else { return "" }
        return html.replacingOccurrences(of: "<[^>]+>", with: "",
                                         options: .regularExpression)
                   .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func extractFirstImageURL(from html: String) -> URL? {
        guard let regex = try? NSRegularExpression(pattern: #"<img[^>]+src=["']([^"']+)["']"#,
                                                   options: .caseInsensitive) else { return nil }
        let range = NSRange(html.startIndex..., in: html)
        guard let match = regex.firstMatch(in: html, range: range),
              let captureRange = Range(match.range(at: 1), in: html) else { return nil }
        return URL(string: String(html[captureRange]))
    }

    private func parseDate(_ raw: String) -> Date {
        guard !raw.isEmpty else { return .now }
        let formatters: [DateFormatter] = [
            { let f = DateFormatter(); f.locale = Locale(identifier: "en_US_POSIX"); f.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"; return f }(),
            { let f = DateFormatter(); f.locale = Locale(identifier: "en_US_POSIX"); f.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"; return f }(),
            { let f = ISO8601DateFormatter(); return f as! DateFormatter }(),
        ]
        for fmt in formatters {
            if let d = fmt.date(from: raw) { return d }
        }
        // ISO8601 fallback
        if let d = ISO8601DateFormatter().date(from: raw) { return d }
        return .now
    }
}
