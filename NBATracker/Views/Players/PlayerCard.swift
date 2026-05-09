import SwiftUI

struct PlayerCard: View {
    let player: Player
    let team: Team?

    var body: some View {
        VStack(spacing: 10) {
            PlayerHeadshotView(player: player, size: 72)

            VStack(spacing: 3) {
                Text(player.firstName)
                    .font(.caption).foregroundColor(.nbaSecondary)
                Text(player.lastName)
                    .font(.system(size: 15, weight: .bold)).foregroundColor(.white).lineLimit(1)
            }

            HStack(spacing: 6) {
                Text(player.position)
                    .font(.caption2.bold()).foregroundColor(.nbaGold)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(Color.nbaGold.opacity(0.15)).cornerRadius(6)
                Text("#\(player.jersey)")
                    .font(.caption2.bold()).foregroundColor(.nbaSecondary)
            }

            if player.isInjured, let status = player.injuryStatus {
                Text(status)
                    .font(.caption2.bold()).foregroundColor(.nbaRed)
                    .padding(.horizontal, 7).padding(.vertical, 2)
                    .background(Color.nbaRed.opacity(0.12)).cornerRadius(5)
            }

            if let team {
                HStack(spacing: 4) {
                    TeamLogoView(team: team, size: 16)
                    Text(team.abbreviation).font(.caption2.bold()).foregroundColor(.nbaSecondary)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Color.nbaCard)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.nbaGold.opacity(0.08), lineWidth: 1))
    }
}
