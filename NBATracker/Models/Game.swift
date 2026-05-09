import Foundation

struct Game: Identifiable {
    let id: String
    let date: Date
    let homeTeam: GameCompetitor
    let awayTeam: GameCompetitor
    let status: GameStatus
    let isPostseason: Bool
    let odds: GameOdds?

    struct GameCompetitor {
        let team: Team
        let score: Int
        let record: String
    }

    struct GameOdds {
        let homeWinPct: Double   // 0.0–1.0, vig-normalized
        let awayWinPct: Double
        let details: String      // e.g. "OKC -8.5"

        // American moneyline string ("−375" or "+295") → raw implied probability
        private static func impliedProb(_ raw: String) -> Double? {
            let cleaned = raw.replacingOccurrences(of: "−", with: "-")
                             .replacingOccurrences(of: "\u{2212}", with: "-")
                             .trimmingCharacters(in: .whitespaces)
            guard let value = Double(cleaned), value != 0 else { return nil }
            if value < 0 {
                return abs(value) / (abs(value) + 100)
            } else {
                return 100 / (value + 100)
            }
        }

        static func from(_ oddsArray: [[String: Any]]) -> GameOdds? {
            guard let first = oddsArray.first else { return nil }
            let details = first["details"] as? String ?? ""

            // Prefer moneyline close odds
            let ml = first["moneyline"] as? [String: Any]
            let homeClose = ((ml?["home"] as? [String: Any])?["close"] as? [String: Any])?["odds"] as? String ?? ""
            let awayClose = ((ml?["away"] as? [String: Any])?["close"] as? [String: Any])?["odds"] as? String ?? ""

            // Fallback: homeTeamOdds / awayTeamOdds moneyLine
            let homeML = homeClose.isEmpty
                ? (first["homeTeamOdds"] as? [String: Any])?["moneyLine"] as? String ?? ""
                : homeClose
            let awayML = awayClose.isEmpty
                ? (first["awayTeamOdds"] as? [String: Any])?["moneyLine"] as? String ?? ""
                : awayClose

            guard let rawHome = impliedProb(homeML), let rawAway = impliedProb(awayML) else { return nil }
            let total = rawHome + rawAway
            guard total > 0 else { return nil }
            return GameOdds(homeWinPct: rawHome / total, awayWinPct: rawAway / total, details: details)
        }
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

        let oddsArray = comps["odds"] as? [[String: Any]] ?? []
        let gameOdds = GameOdds.from(oddsArray)

        return Game(id: id, date: date, homeTeam: home, awayTeam: away,
                    status: status, isPostseason: isPost, odds: gameOdds)
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
