import SwiftUI

struct TeamLogoView: View {
    let team: Team
    let size: CGFloat

    var body: some View {
        AsyncImage(url: team.logoURL) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFit()
            default:
                fallbackLogo
            }
        }
        .frame(width: size, height: size)
    }

    private var fallbackLogo: some View {
        ZStack {
            Circle()
                .fill(Color(hex: team.primaryColor).opacity(0.3))
            Text(team.abbreviation)
                .font(.system(size: size * 0.3, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

extension Color {
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
