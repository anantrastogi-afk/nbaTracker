import Foundation

struct Player: Codable, Identifiable, Hashable {
    let id: Int
    let firstName: String
    let lastName: String
    let position: String?
    let height: String?
    let weight: String?
    let jerseyNumber: String?
    let college: String?
    let country: String?
    let draftYear: Int?
    let draftRound: Int?
    let draftNumber: Int?
    let team: Team?

    enum CodingKeys: String, CodingKey {
        case id, position, height, weight, college, country, team
        case firstName    = "first_name"
        case lastName     = "last_name"
        case jerseyNumber = "jersey_number"
        case draftYear    = "draft_year"
        case draftRound   = "draft_round"
        case draftNumber  = "draft_number"
    }

    var fullName: String { "\(firstName) \(lastName)" }
    var initials: String {
        let f = firstName.first.map(String.init) ?? ""
        let l = lastName.first.map(String.init) ?? ""
        return "\(f)\(l)"
    }
    var positionDisplay: String { position?.isEmpty == false ? position! : "N/A" }
}

struct PlayersResponse: Codable {
    let data: [Player]
    let meta: CursorMeta
}
