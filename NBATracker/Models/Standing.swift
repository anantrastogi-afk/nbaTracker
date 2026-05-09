import Foundation

struct Standing: Identifiable {
    let id: String
    let team: Team
    let conference: String
    let wins: Int
    let losses: Int
    let winPct: String
    let gamesBehind: String
    let streak: String
    let homeRecord: String
    let roadRecord: String
    let lastTen: String
    let playoffSeed: Int

    var record: String { "\(wins)-\(losses)" }
    var winPctDouble: Double { Double(winPct.replacingOccurrences(of: ".", with: "0.")) ?? 0 }

    static func from(entry: [String: Any], conference: String) -> Standing? {
        guard let teamDict = entry["team"] as? [String: Any],
              let id   = teamDict["id"]          as? String,
              let abbr = teamDict["abbreviation"] as? String,
              let name = teamDict["displayName"]  as? String,
              let loc  = teamDict["location"]     as? String,
              let nick = teamDict["name"]         as? String
        else { return nil }

        let color   = teamDict["color"]          as? String ?? "1D428A"
        let alt     = teamDict["alternateColor"] as? String ?? ""
        let logos   = teamDict["logos"] as? [[String: Any]] ?? []
        let logoURL = (logos.first?["href"] as? String).flatMap { URL(string: $0) }
        let team    = Team(id: id, abbreviation: abbr, displayName: name,
                           location: loc, name: nick, color: color,
                           alternateColor: alt, logoURL: logoURL)

        let stats = (entry["stats"] as? [[String: Any]] ?? [])
        var stat: [String: String] = [:]
        for s in stats { if let n = s["name"] as? String, let v = s["displayValue"] as? String { stat[n] = v } }

        let wins  = Int(stat["wins"]   ?? "0") ?? 0
        let losses = Int(stat["losses"] ?? "0") ?? 0
        let pct    = stat["winPercent"]    ?? ".000"
        let gb     = stat["gamesBehind"]   ?? "-"
        let streak = stat["streak"]        ?? "-"
        let home   = stat["Home"]          ?? "-"
        let road   = stat["Road"]          ?? "-"
        let last10 = stat["Last Ten Games"] ?? "-"
        let seed   = Int(stat["playoffSeed"] ?? "0") ?? 0

        return Standing(id: id, team: team, conference: conference,
                        wins: wins, losses: losses, winPct: pct,
                        gamesBehind: gb, streak: streak,
                        homeRecord: home, roadRecord: road,
                        lastTen: last10, playoffSeed: seed)
    }
}
