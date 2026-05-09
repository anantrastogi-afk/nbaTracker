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
    let meta: PaginationMeta
}

struct PaginationMeta: Codable {
    let totalPages: Int
    let currentPage: Int
    let nextPage: Int?
    let perPage: Int
    let totalCount: Int

    enum CodingKeys: String, CodingKey {
        case totalPages  = "total_pages"
        case currentPage = "current_page"
        case nextPage    = "next_page"
        case perPage     = "per_page"
        case totalCount  = "total_count"
    }
}

struct SeasonAverage: Codable, Identifiable {
    let playerId: Int
    let season: Int
    let gamesPlayed: Int
    let pts: Double
    let reb: Double
    let ast: Double
    let stl: Double
    let blk: Double
    let fgPct: Double
    let fg3Pct: Double
    let ftPct: Double
    let min: String?
    let turnover: Double

    var id: Int { playerId }

    enum CodingKeys: String, CodingKey {
        case season, pts, reb, ast, stl, blk, min, turnover
        case playerId   = "player_id"
        case gamesPlayed = "games_played"
        case fgPct      = "fg_pct"
        case fg3Pct     = "fg3_pct"
        case ftPct      = "ft_pct"
    }
}

struct SeasonAveragesResponse: Codable {
    let data: [SeasonAverage]
}
