import SwiftUI

struct PlayerCard: View {
    let player: Player

    var body: some View {
        VStack(spacing: 12) {
            avatar
            VStack(spacing: 3) {
                Text(player.firstName)
                    .font(.caption)
                    .foregroundColor(.nbaSecondary)
                Text(player.lastName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            HStack(spacing: 8) {
                positionBadge
                if let jersey = player.jerseyNumber {
                    Text("#\(jersey)")
                        .font(.caption2.bold())
                        .foregroundColor(.nbaSecondary)
                }
            }
            if let team = player.team {
                HStack(spacing: 4) {
                    TeamLogoView(team: team, size: 18)
                    Text(team.abbreviation)
                        .font(.caption2.bold())
                        .foregroundColor(.nbaSecondary)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(Color.nbaCard)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.nbaGold.opacity(0.1), lineWidth: 1)
        )
    }

    private var avatar: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.nbaGold.opacity(0.3), Color.nbaRed.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 70, height: 70)
            Text(player.initials)
                .font(.system(size: 26, weight: .black))
                .foregroundColor(.white)
        }
    }

    private var positionBadge: some View {
        Text(player.positionDisplay)
            .font(.caption2.bold())
            .foregroundColor(.nbaGold)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.nbaGold.opacity(0.15))
            .cornerRadius(6)
    }
}
