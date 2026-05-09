import SwiftUI

struct GameCard: View {
    let game: Game

    var body: some View {
        HStack(spacing: 0) {
            teamSide(team: game.visitorTeam, score: game.visitorTeamScore, isLeading: false)
            middleSection
            teamSide(team: game.homeTeam, score: game.homeTeamScore, isLeading: true)
        }
        .padding()
        .background(Color.nbaCard)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(game.isLive ? Color.nbaGold.opacity(0.5) : Color.clear, lineWidth: 1)
        )
    }

    private func teamSide(team: Team, score: Int, isLeading: Bool) -> some View {
        VStack(spacing: 6) {
            TeamLogoView(team: team, size: 50)
            Text(team.abbreviation)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
            if game.status.lowercased() != "final" && !game.isLive {
                Text(team.city)
                    .font(.caption2)
                    .foregroundColor(.nbaSecondary)
                    .lineLimit(1)
            } else {
                Text("\(score)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(isWinner(team: team, score: score) ? .white : .nbaSecondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var middleSection: some View {
        VStack(spacing: 4) {
            if game.isLive {
                Circle()
                    .fill(Color.nbaRed)
                    .frame(width: 8, height: 8)
            }
            Text(game.statusDisplay)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(game.isLive ? .nbaRed : .nbaSecondary)
                .multilineTextAlignment(.center)

            if game.postseason {
                Text("PLAYOFFS")
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(.nbaGold)
                    .tracking(1)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.nbaGold.opacity(0.15))
                    .cornerRadius(4)
            }

            Text("vs")
                .font(.caption2)
                .foregroundColor(.nbaSecondary)
        }
        .frame(width: 80)
    }

    private func isWinner(team: Team, score: Int) -> Bool {
        guard game.status.lowercased() == "final" else { return false }
        let otherScore = team.id == game.homeTeam.id ? game.visitorTeamScore : game.homeTeamScore
        return score > otherScore
    }
}
