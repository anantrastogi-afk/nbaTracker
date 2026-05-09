import SwiftUI

struct TeamLogoView: View {
    let team: Team
    let size: CGFloat

    var body: some View {
        if let url = team.logoURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let img): img.resizable().scaledToFit()
                default: fallback
                }
            }
            .frame(width: size, height: size)
        } else {
            fallback.frame(width: size, height: size)
        }
    }

    private var fallback: some View {
        ZStack {
            Circle().fill(Color(hex: team.color).opacity(0.3))
            Text(team.abbreviation)
                .font(.system(size: size * 0.3, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

struct PlayerHeadshotView: View {
    let player: Player
    let size: CGFloat

    var body: some View {
        if let url = player.headshotURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().scaledToFill()
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                default: initialsView
                }
            }
        } else {
            initialsView
        }
    }

    private var initialsView: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(
                    colors: [Color.nbaGold.opacity(0.4), Color.nbaRed.opacity(0.3)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
                .frame(width: size, height: size)
            Text(player.initials)
                .font(.system(size: size * 0.35, weight: .black))
                .foregroundColor(.white)
        }
    }
}
