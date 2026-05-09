import SwiftUI

struct TeamLogoView: View {
    let team: Team
    let size: CGFloat

    var body: some View {
        // Always lead with the dark-variant URL built from abbreviation;
        // it's designed for dark backgrounds and verified valid for all 30 teams.
        AsyncImage(url: team.darkLogoURL) { phase in
            switch phase {
            case .success(let img):
                img.resizable().scaledToFit()
                    .frame(width: size, height: size)
            case .failure:
                // darkLogoURL failed — try the API-parsed URL as last resort
                if let fallbackURL = team.logoURL {
                    AsyncImage(url: fallbackURL) { retry in
                        switch retry {
                        case .success(let img):
                            img.resizable().scaledToFit()
                                .frame(width: size, height: size)
                        default: fallback
                        }
                    }
                } else {
                    fallback
                }
            default:
                fallback
            }
        }
        .frame(width: size, height: size)
    }

    private var fallback: some View {
        ZStack {
            Circle().fill(Color(hex: team.color).opacity(0.3))
            Text(team.abbreviation)
                .font(.system(size: size * 0.3, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(width: size, height: size)
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
