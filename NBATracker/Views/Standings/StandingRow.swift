import SwiftUI

struct StandingRow: View {
    let standing: Standing
    let rank: Int

    var body: some View {
        HStack {
            rankBadge
            TeamLogoView(team: standing.team, size: 30)
                .padding(.horizontal, 4)
            Text(standing.team.abbreviation)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 40, alignment: .leading)
            Spacer()
            Group {
                Text("\(standing.wins)").frame(width: 32)
                Text("\(standing.losses)").frame(width: 32)
                Text(String(format: "%.3f", standing.winPct)).frame(width: 50)
                Text(gamesBack).frame(width: 40)
            }
            .font(.system(size: 14))
            .foregroundColor(rank == 1 ? .white : .nbaSecondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(rank <= 6 ? Color.nbaGold.opacity(0.04) : Color.clear)
    }

    private var rankBadge: some View {
        Text("\(rank)")
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(rank <= 8 ? .nbaGold : .nbaSecondary)
            .frame(width: 24)
    }

    private var gamesBack: String {
        if rank == 1 { return "-" }
        return "-"
    }
}
