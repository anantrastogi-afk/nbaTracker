import Foundation

struct Game: Identifiable {
    let id: String
    let date: Date
    let homeTeam: GameCompetitor
    let awayTeam: GameCompetitor
    let status: GameStatus
    let isPostseason: Bool

    struct GameCompetitor {
        let team: Team
        let score: Int
        let record: String
    }

    struct GameStatus {
        let description: String  // "Scheduled", "In Progress", "Final"
        let period: Int
        let clock: String

        var isFinal:     Bool { description.lowercased() == "final" }
        var isLive:      Bool { description.lowercased().contains("progress") }
        var isScheduled: Bool { !isFinal && !isLive }

        var display: String {
            if isFinal  { return "Final" }
            if isLive   { return "Q\(period) \(clock)" }
            return ""   // caller uses formatted date
        }
    }

    var formattedTime: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        f.timeZone = TimeZone.current
        return f.string(from: date)
    }

    var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: date)
    }

    // Parse from ESPN scoreboard event
    static func from(_ event: [String: Any]) -> Game? {
        guard let id   = event["id"] as? String,
              let dateStr = event["date"] as? String,
              let comps   = (event["competitions"] as? [[String: Any]])?.first
        else { return nil }

        guard let date = Self.parseDate(dateStr) else { return nil }

        let competitors = comps["competitors"] as? [[String: Any]] ?? []
        guard let homeData = competitors.first(where: { ($0["homeAway"] as? String) == "home" }),
              let awayData = competitors.first(where: { ($0["homeAway"] as? String) == "away" })
        else { return nil }

        func competitor(_ d: [String: Any]) -> GameCompetitor? {
            guard let teamDict = d["team"] as? [String: Any] else { return nil }
            let id    = teamDict["id"]           as? String ?? ""
            let abbr  = teamDict["abbreviation"] as? String ?? ""
            let name  = teamDict["displayName"]  as? String ?? ""
            let loc   = teamDict["location"]     as? String ?? ""
            let nick  = teamDict["name"]         as? String ?? ""
            let color = teamDict["color"]        as? String ?? "1D428A"
            let alt   = teamDict["alternateColor"] as? String ?? ""
            let logo  = (teamDict["logo"] as? String).flatMap { URL(string: $0) }
            let team  = Team(id: id, abbreviation: abbr, displayName: name,
                             location: loc, name: nick, color: color,
                             alternateColor: alt, logoURL: logo)
            let score  = Int(d["score"] as? String ?? "0") ?? 0
            let records = d["records"] as? [[String: Any]] ?? []
            let record  = records.first(where: { ($0["type"] as? String) == "total" })?["summary"] as? String ?? ""
            return GameCompetitor(team: team, score: score, record: record)
        }

        guard let home = competitor(homeData), let away = competitor(awayData) else { return nil }

        let statusDict = comps["status"] as? [String: Any] ?? [:]
        let typeDict   = statusDict["type"] as? [String: Any] ?? [:]
        let desc   = typeDict["description"]  as? String ?? "Scheduled"
        let period = statusDict["period"]     as? Int    ?? 0
        let clock  = statusDict["displayClock"] as? String ?? ""
        let status = GameStatus(description: desc, period: period, clock: clock)

        let seasonType = (event["season"] as? [String: Any])?["type"] as? Int ?? 2
        let isPost = seasonType == 3

        return Game(id: id, date: date, homeTeam: home, awayTeam: away,
                    status: status, isPostseason: isPost)
    }

    // ESPN sends several date formats — try each one
    private static func parseDate(_ s: String) -> Date? {
        let formats = [
            "yyyy-MM-dd'T'HH:mmZ",      // "2026-05-09T19:00Z"  (no seconds)
            "yyyy-MM-dd'T'HH:mm:ssZ",   // "2026-05-09T19:00:00Z"
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ", // with fractional seconds
            "yyyy-MM-dd"                 // date-only fallback
        ]
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        for fmt in formats {
            df.dateFormat = fmt
            if let d = df.date(from: s) { return d }
        }
        return nil
    }
}
