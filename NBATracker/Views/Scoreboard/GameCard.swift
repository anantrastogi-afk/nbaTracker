import SwiftUI

struct GameCard: View {
    let game: Game

    var body: some View {
        HStack(spacing: 0) {
            teamSide(competitor: game.awayTeam, isWinner: awayWins)
            centerInfo
            teamSide(competitor: game.homeTeam, isWinner: homeWins)
        }
        .padding(14)
        .background(Color.nbaCard)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(game.status.isLive ? Color.nbaGold.opacity(0.6) : Color.clear, lineWidth: 1)
        )
    }

    private func teamSide(competitor: Game.GameCompetitor, isWinner: Bool) -> some View {
        VStack(spacing: 6) {
            TeamLogoView(team: competitor.team, size: 46)
            Text(competitor.team.abbreviation)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
            if game.status.isScheduled {
                Text(competitor.record)
                    .font(.caption2)
                    .foregroundColor(.nbaSecondary)
            } else {
                Text("\(competitor.score)")
                    .font(.system(size: 30, weight: .black))
                    .foregroundColor(isWinner ? .white : .nbaSecondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var centerInfo: some View {
        VStack(spacing: 5) {
            if game.status.isLive {
                HStack(spacing: 4) {
                    Circle().fill(Color.nbaRed).frame(width: 7, height: 7)
                    Text("LIVE").font(.system(size: 10, weight: .black)).foregroundColor(.nbaRed)
                }
            }
            Text(game.status.isFinal ? "Final" : game.status.isLive ? game.status.display : game.formattedTime)
                .font(.system(size: game.status.isLive ? 13 : 12, weight: .bold))
                .foregroundColor(game.status.isLive ? .nbaRed : .nbaSecondary)
                .multilineTextAlignment(.center)

            if game.isPostseason {
                Text("PLAYOFFS")
                    .font(.system(size: 8, weight: .black))
                    .foregroundColor(.nbaGold)
                    .tracking(1)
                    .padding(.horizontal, 5).padding(.vertical, 2)
                    .background(Color.nbaGold.opacity(0.15))
                    .cornerRadius(4)
            }
            Text("@").font(.caption2).foregroundColor(.nbaSecondary)
        }
        .frame(width: 76)
    }

    private var homeWins: Bool {
        guard game.status.isFinal else { return false }
        return game.homeTeam.score > game.awayTeam.score
    }
    private var awayWins: Bool {
        guard game.status.isFinal else { return false }
        return game.awayTeam.score > game.homeTeam.score
    }
}
