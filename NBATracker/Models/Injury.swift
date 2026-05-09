import SwiftUI

struct Injury: Identifiable {
    let id: String
    let athleteId: String
    let athleteName: String
    let teamName: String
    let status: String
    let shortComment: String
    let longComment: String
    let date: String

    var statusColor: Color {
        switch status.lowercased() {
        case "out":          return .nbaRed
        case "doubtful":     return .nbaRed
        case "questionable": return .nbaGold
        case "day-to-day":   return .nbaGold
        case "probable":     return Color.green
        default:             return .nbaSecondary
        }
    }

    var displayComment: String {
        shortComment.isEmpty ? longComment : shortComment
    }

    static func from(teamGroup: [String: Any]) -> [Injury] {
        let teamName  = teamGroup["displayName"] as? String ?? ""
        let innerList = teamGroup["injuries"]    as? [[String: Any]] ?? []
        return innerList.compactMap { inj -> Injury? in
            guard let id = inj["id"] as? String else { return nil }
            let athlete       = inj["athlete"] as? [String: Any] ?? [:]
            let athleteId     = athlete["id"]          as? String ?? ""
            let athleteName   = athlete["displayName"] as? String ?? "Unknown"
            let status        = inj["status"]       as? String ?? "Questionable"
            let shortComment  = inj["shortComment"] as? String ?? ""
            let longComment   = inj["longComment"]  as? String ?? ""
            let date          = inj["date"]         as? String ?? ""
            return Injury(id: id, athleteId: athleteId, athleteName: athleteName,
                          teamName: teamName, status: status, shortComment: shortComment,
                          longComment: longComment, date: date)
        }
    }
}
