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

        let logos  = dict["logos"] as? [[String: Any]] ?? []
        let logoHref = logos.first?["href"] as? String
        let logoURL  = logoHref.flatMap { URL(string: $0) }

        return Team(id: id, abbreviation: abbr, displayName: name, location: loc,
                    name: nick, color: color, alternateColor: alt, logoURL: logoURL)
    }
}
