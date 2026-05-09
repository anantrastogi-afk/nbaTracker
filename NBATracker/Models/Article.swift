import Foundation

struct Article: Identifiable {
    let id: String
    let headline: String
    let description: String
    let published: Date
    let imageURL: URL?
    let link: URL?

    var timeAgo: String {
        let diff = Date().timeIntervalSince(published)
        if diff < 3600  { return "\(Int(diff / 60))m ago" }
        if diff < 86400 { return "\(Int(diff / 3600))h ago" }
        return "\(Int(diff / 86400))d ago"
    }

    static func from(_ dict: [String: Any]) -> Article? {
        guard let id  = (dict["id"] as? Int).map(String.init) ?? dict["id"] as? String,
              let hl  = dict["headline"] as? String
        else { return nil }

        let desc = dict["description"] as? String ?? ""
        let iso  = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let pubStr   = dict["published"] as? String ?? ""
        let published = iso.date(from: pubStr) ?? Date()

        let images  = dict["images"]  as? [[String: Any]] ?? []
        let imgURL  = (images.first?["url"] as? String).flatMap { URL(string: $0) }

        let links   = dict["links"]   as? [String: Any] ?? [:]
        let webLink = (links["web"] as? [String: Any])?["href"] as? String
        let link    = webLink.flatMap { URL(string: $0) }

        return Article(id: id, headline: hl, description: desc,
                       published: published, imageURL: imgURL, link: link)
    }
}
