import Foundation

struct Team: Identifiable, Hashable {
    let id: String
    let abbreviation: String
    let displayName: String
    let location: String
    let name: String
    let color: String
    let alternateColor: String
    let logoURL: URL?

    static func == (lhs: Team, rhs: Team) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    // Best logo URL for dark backgrounds: parsed dark variant → parsed any → built from abbr
    var darkLogoURL: URL {
        // Guaranteed URL built from abbreviation using ESPN's dark CDN path
        URL(string: "https://a.espncdn.com/i/teamlogos/nba/500-dark/\(abbreviation.lowercased()).png")
            ?? URL(string: "https://a.espncdn.com/i/teamlogos/nba/500/\(abbreviation.lowercased()).png")!
    }

    // Parse from ESPN /teams response
    static func from(_ dict: [String: Any]) -> Team? {
        guard let id   = dict["id"]           as? String,
              let abbr = dict["abbreviation"] as? String,
              let name = dict["displayName"]  as? String,
              let loc  = dict["location"]     as? String,
              let nick = dict["name"]         as? String
        else { return nil }

        let color = dict["color"]          as? String ?? "1D428A"
        let alt   = dict["alternateColor"] as? String ?? "C4CED4"

        let logos    = dict["logos"] as? [[String: Any]] ?? []
        let logoHref = preferredLogo(from: logos)
        let logoURL  = logoHref.flatMap { URL(string: $0) }

        return Team(id: id, abbreviation: abbr, displayName: name, location: loc,
                    name: nick, color: color, alternateColor: alt, logoURL: logoURL)
    }

    // Prefer the 500-dark variant (no scoreboard suffix) for dark-themed app
    static func preferredLogo(from logos: [[String: Any]]) -> String? {
        let hrefs = logos.compactMap { $0["href"] as? String }
        return hrefs.first(where: { $0.contains("500-dark") && !$0.contains("scoreboard") })
            ?? hrefs.first(where: { $0.contains("500") && !$0.contains("dark") && !$0.contains("scoreboard") })
            ?? hrefs.first
    }
}
