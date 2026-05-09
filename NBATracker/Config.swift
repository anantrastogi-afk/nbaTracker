import SwiftUI

enum ESPN {
    static let base     = "https://site.api.espn.com/apis/site/v2/sports/basketball/nba"
    static let coreBase = "https://site.api.espn.com/apis/v2/sports/basketball/nba"

    static func url(_ path: String, base: String = ESPN.base, params: [String: String] = [:]) -> URL {
        var c = URLComponents(string: base + path)!
        if !params.isEmpty { c.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) } }
        return c.url!
    }
}

extension Color {
    static let nbaBG        = Color(red: 0.07, green: 0.07, blue: 0.07)
    static let nbaCard      = Color(red: 0.12, green: 0.12, blue: 0.12)
    static let nbaGold      = Color(red: 0.97, green: 0.71, blue: 0.00)
    static let nbaRed       = Color(red: 0.78, green: 0.06, blue: 0.18)
    static let nbaSecondary = Color(red: 0.60, green: 0.60, blue: 0.60)

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int & 0xFF)          / 255
        self.init(red: r, green: g, blue: b)
    }
}
