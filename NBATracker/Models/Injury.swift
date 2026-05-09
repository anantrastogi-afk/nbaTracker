import Foundation

// Injury data is not available in the balldontlie free tier.
// This model is used with mock data for the UI demonstration.
struct Injury: Identifiable {
    let id = UUID()
    let playerName: String
    let team: String
    let status: InjuryStatus
    let description: String
    let updatedDate: String

    enum InjuryStatus: String {
        case out       = "Out"
        case doubtful  = "Doubtful"
        case questionable = "Questionable"
        case dayToDay  = "Day-To-Day"
        case probable  = "Probable"

        var color: String {
            switch self {
            case .out:          return "E03A3E"
            case .doubtful:     return "E03A3E"
            case .questionable: return "F7B500"
            case .dayToDay:     return "F7B500"
            case .probable:     return "34C759"
            }
        }
    }

    static let mockData: [Injury] = [
        Injury(playerName: "LeBron James",   team: "LAL", status: .probable,     description: "Left ankle soreness",         updatedDate: "Today"),
        Injury(playerName: "Joel Embiid",    team: "PHI", status: .out,          description: "Left knee (meniscus)",        updatedDate: "Yesterday"),
        Injury(playerName: "Damian Lillard", team: "MIL", status: .questionable, description: "Right Achilles tightness",    updatedDate: "Today"),
        Injury(playerName: "Kawhi Leonard",  team: "LAC", status: .out,          description: "Right knee management",       updatedDate: "2 days ago"),
        Injury(playerName: "Paul George",    team: "PHI", status: .dayToDay,     description: "Right shoulder inflammation", updatedDate: "Today"),
        Injury(playerName: "Jaylen Brown",   team: "BOS", status: .probable,     description: "Left foot soreness",          updatedDate: "Yesterday"),
    ]
}
