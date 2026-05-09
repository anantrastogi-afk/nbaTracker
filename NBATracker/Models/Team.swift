import Foundation

struct Team: Codable, Identifiable, Hashable {
    let id: Int
    let abbreviation: String
    let city: String
    let conference: String
    let division: String
    let fullName: String
    let name: String

    enum CodingKeys: String, CodingKey {
        case id, abbreviation, city, conference, division
        case fullName = "full_name"
        case name
    }

    var logoURL: URL? {
        URL(string: "https://a.espncdn.com/i/teamlogos/nba/500/\(abbreviation.lowercased()).png")
    }

    var primaryColor: String {
        switch abbreviation {
        case "LAL": return "552583"
        case "GSW": return "1D428A"
        case "BOS": return "007A33"
        case "MIA": return "98002E"
        case "CHI": return "CE1141"
        case "NYK": return "006BB6"
        case "BKN": return "000000"
        case "PHI": return "006BB6"
        case "MIL": return "00471B"
        case "CLE": return "860038"
        case "IND": return "002D62"
        case "ORL": return "0077C0"
        case "ATL": return "E03A3E"
        case "TOR": return "CE1141"
        case "CHA": return "1D1160"
        case "WAS": return "002B5C"
        case "DEN": return "0E2240"
        case "MIN": return "0C2340"
        case "OKC": return "007AC1"
        case "UTA": return "002B5C"
        case "PHX": return "1D1160"
        case "SAC": return "5A2D81"
        case "POR": return "E03A3E"
        case "LAC": return "C8102E"
        case "DAL": return "00538C"
        case "SAS": return "C4CED4"
        case "HOU": return "CE1141"
        case "NOP": return "0C2340"
        case "MEM": return "5D76A9"
        default:     return "1D428A"
        }
    }
}

struct TeamsResponse: Codable {
    let data: [Team]
}
