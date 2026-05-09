import SwiftUI

enum NBAConfig {
    static let apiKey = "ac6b81cb-5f12-4f58-ae90-bb0e98fbb0fb"
    static let baseURL = "https://api.balldontlie.io/v1"
    static let currentSeason = 2024
}

extension Color {
    static let nbaBG       = Color(red: 0.07, green: 0.07, blue: 0.07)
    static let nbaCard     = Color(red: 0.12, green: 0.12, blue: 0.12)
    static let nbaGold     = Color(red: 0.97, green: 0.71, blue: 0.00)
    static let nbaRed      = Color(red: 0.78, green: 0.06, blue: 0.18)
    static let nbaSecondary = Color(red: 0.60, green: 0.60, blue: 0.60)
    static let nbaAccent   = Color(red: 0.97, green: 0.71, blue: 0.00)
}
