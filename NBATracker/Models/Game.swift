import Foundation

struct Game: Codable, Identifiable {
    let id: Int
    let date: String
    let datetime: String?
    let homeTeamScore: Int
    let visitorTeamScore: Int
    let season: Int
    let period: Int
    let status: String
    let time: String?
    let postseason: Bool
    let postponed: Bool?
    let homeTeam: Team
    let visitorTeam: Team

    enum CodingKeys: String, CodingKey {
        case id, date, datetime, season, period, status, time, postseason, postponed
        case homeTeamScore    = "home_team_score"
        case visitorTeamScore = "visitor_team_score"
        case homeTeam         = "home_team"
        case visitorTeam      = "visitor_team"
    }

    var isFinal: Bool { status.lowercased() == "final" }
    var isPostponed: Bool { postponed == true }
    // Scheduled games have an ISO8601 datetime string in the status field
    var isScheduled: Bool { status.contains("T") && status.contains(":") && !isFinal }

    var isLive: Bool {
        guard !isFinal, !isPostponed, !isScheduled, period > 0 else { return false }
        return true
    }

    var statusDisplay: String {
        if isPostponed { return "PPD" }
        if isFinal     { return "Final" }
        if isLive, let t = time, !t.isEmpty { return "Q\(period) \(t)" }
        if isLive      { return "Q\(period)" }
        return formattedStartTime
    }

    var formattedStartTime: String {
        // Use datetime field if available, fall back to status (which may be ISO8601)
        let raw = datetime ?? (isScheduled ? status : nil)
        guard let raw else { return status }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = formatter.date(from: raw) {
            let out = DateFormatter()
            out.dateFormat = "h:mm a"
            out.timeZone = TimeZone.current
            return out.string(from: d)
        }
        // Try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        if let d = formatter.date(from: raw) {
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
    let meta: CursorMeta
}

struct CursorMeta: Codable {
    let nextCursor: Int?
    let perPage: Int

    enum CodingKeys: String, CodingKey {
        case nextCursor = "next_cursor"
        case perPage    = "per_page"
    }
}

// Computed standing — built from game results, no paid API needed
struct Standing: Identifiable {
    let team: Team
    var wins: Int
    var losses: Int
    var conferenceRank: Int = 0

    var id: Int { team.id }
    var winPct: Double { Double(wins) / Double(max(1, wins + losses)) }
    var record: String { "\(wins)-\(losses)" }
}
