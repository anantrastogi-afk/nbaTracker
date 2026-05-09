import Foundation

struct Game: Codable, Identifiable {
    let id: Int
    let date: String
    let homeTeamScore: Int
    let visitorTeamScore: Int
    let season: Int
    let period: Int
    let status: String
    let time: String?
    let postseason: Bool
    let homeTeam: Team
    let visitorTeam: Team

    enum CodingKeys: String, CodingKey {
        case id, date, season, period, status, time, postseason
        case homeTeamScore    = "home_team_score"
        case visitorTeamScore = "visitor_team_score"
        case homeTeam         = "home_team"
        case visitorTeam      = "visitor_team"
    }

    var isLive: Bool {
        guard let t = time, !t.isEmpty else { return false }
        return status.lowercased() != "final" && period > 0
    }

    var statusDisplay: String {
        if status.lowercased() == "final" { return "Final" }
        if let t = time, !t.isEmpty { return "Q\(period) \(t)" }
        return formattedTime
    }

    var formattedTime: String {
        guard date.count >= 16 else { return status }
        let parts = date.split(separator: "T")
        guard parts.count == 2 else { return status }
        let timePart = String(parts[1].prefix(5))
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        if let d = formatter.date(from: timePart) {
            let out = DateFormatter()
            out.dateFormat = "h:mm a"
            out.timeZone = TimeZone.current
            return out.string(from: d)
        }
        return status
    }
}

struct GamesResponse: Codable {
    let data: [Game]
    let meta: PaginationMeta
}

struct Standing: Codable, Identifiable {
    let id: Int
    let team: Team
    let conference: String
    let division: String
    let wins: Int
    let losses: Int
    let homeRecord: String?
    let awayRecord: String?
    let divisionRecord: String?
    let conferenceRank: Int
    let divisionRank: Int

    enum CodingKeys: String, CodingKey {
        case id, team, conference, division, wins, losses
        case homeRecord      = "home_record"
        case awayRecord      = "away_record"
        case divisionRecord  = "division_record"
        case conferenceRank  = "conference_rank"
        case divisionRank    = "division_rank"
    }

    var winPct: Double {
        let total = wins + losses
        return total > 0 ? Double(wins) / Double(total) : 0
    }

    var record: String { "\(wins)-\(losses)" }
}

struct StandingsResponse: Codable {
    let data: [Standing]
}
