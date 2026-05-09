import SwiftUI

struct StandingRow: View {
    let standing: Standing
    let rank: Int

    var body: some View {
        HStack(spacing: 0) {
            // Rank
            Text("\(rank)")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(rank <= 8 ? .nbaGold : .nbaSecondary)
                .frame(width: 28, alignment: .center)

            // Logo + abbr
            HStack(spacing: 6) {
                TeamLogoView(team: standing.team, size: 28)
                Text(standing.team.abbreviation)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 4)

            // Stats
            statCell("\(standing.wins)")
            statCell("\(standing.losses)")
            statCell(standing.winPct)
            statCell(standing.lastTen)
            streakCell(standing.streak)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(rank == 1 ? Color.nbaGold.opacity(0.06) : rank <= 6 ? Color.nbaGold.opacity(0.03) : Color.clear)
    }

    private func statCell(_ val: String) -> some View {
        Text(val)
            .font(.system(size: 12))
            .foregroundColor(.nbaSecondary)
            .frame(width: rank <= 8 ? 32 : 32, alignment: .center)
            .frame(width: 32)
    }

    private func streakCell(_ streak: String) -> some View {
        let isWin = streak.hasPrefix("W")
        return Text(streak)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(isWin ? .green : .nbaRed)
            .frame(width: 40, alignment: .center)
    }
}
