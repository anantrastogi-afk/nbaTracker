import Foundation

struct Player: Identifiable, Hashable {
    let id: String
    let fullName: String
    let firstName: String
    let lastName: String
    let position: String
    let jersey: String
    let headshotURL: URL?
    let displayHeight: String
    let displayWeight: String
    let age: Int?
    let college: String?
    let birthCity: String?
    let birthCountry: String?
    let injuryStatus: String?   // "Active", "Out", "Questionable", etc.
    let injuryDetail: String?

    static func == (lhs: Player, rhs: Player) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    var initials: String {
        let f = firstName.first.map(String.init) ?? ""
        let l = lastName.first.map(String.init) ?? ""
        return "\(f)\(l)"
    }
    var isInjured: Bool {
        guard let s = injuryStatus else { return false }
        return s != "Active" && !s.isEmpty
    }

    // Parse from ESPN /teams/{id}/roster athletes array
    static func from(_ dict: [String: Any]) -> Player? {
        guard let id   = dict["id"]          as? String,
              let full = dict["fullName"]     as? String,
              let first = dict["firstName"]   as? String,
              let last  = dict["lastName"]    as? String
        else { return nil }

        let pos     = (dict["position"] as? [String: Any])?["displayName"] as? String ?? "N/A"
        let jersey  = dict["jersey"]          as? String ?? "--"
        let height  = dict["displayHeight"]   as? String ?? "--"
        let weight  = dict["displayWeight"]   as? String ?? "--"
        let age     = dict["age"]             as? Int
        let college = dict["college"]         as? String

        let birth      = dict["birthPlace"] as? [String: Any]
        let birthCity  = birth?["city"]    as? String
        let birthCountry = birth?["country"] as? String

        let hsDict   = dict["headshot"] as? [String: Any]
        let hsHref   = hsDict?["href"] as? String
        let hsURL    = hsHref.flatMap { URL(string: $0) }

        let injuries = dict["injuries"] as? [[String: Any]] ?? []
        let inj      = injuries.first
        let injStatus  = inj?["status"]  as? String
        let injDetail  = inj?["longComment"] as? String

        return Player(id: id, fullName: full, firstName: first, lastName: last,
                      position: pos, jersey: jersey, headshotURL: hsURL,
                      displayHeight: height, displayWeight: weight, age: age,
                      college: college, birthCity: birthCity, birthCountry: birthCountry,
                      injuryStatus: injStatus, injuryDetail: injDetail)
    }
}
