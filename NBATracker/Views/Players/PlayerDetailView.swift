import SwiftUI

@MainActor
final class PlayerDetailViewModel: ObservableObject {
    @Published var averages: SeasonAverage?
    @Published var isLoading = false
    let player: Player
    init(player: Player) { self.player = player }

    func load() async {
        isLoading = true
        do {
            let avgs = try await NBAService.shared.fetchSeasonAverages(playerIds: [player.id])
            averages = avgs.first
        } catch { }
        isLoading = false
    }
}

struct PlayerDetailView: View {
    @StateObject private var vm: PlayerDetailViewModel
    init(player: Player) { _vm = StateObject(wrappedValue: PlayerDetailViewModel(player: player)) }

    var body: some View {
        ZStack {
            Color.nbaBG.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    profileHeader
                    infoSection
                    if vm.isLoading { LoadingView().frame(height: 100) }
                    else if let avg = vm.averages { statsSection(avg: avg) }
                    else { noStatsView }
                }
                .padding(.bottom, 30)
            }
        }
        .navigationTitle(vm.player.fullName)
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.load() }
    }

    private var profileHeader: some View {
        ZStack {
            LinearGradient(
                colors: [Color.nbaGold.opacity(0.2), Color.nbaBG],
                startPoint: .top, endPoint: .bottom
            )
            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.nbaGold.opacity(0.4), Color.nbaRed.opacity(0.3)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                    Text(vm.player.initials)
                        .font(.system(size: 38, weight: .black))
                        .foregroundColor(.white)
                }
                Text(vm.player.fullName)
                    .font(.title2.bold())
                    .foregroundColor(.white)

                HStack(spacing: 12) {
                    Text(vm.player.positionDisplay)
                        .font(.caption.bold())
                        .foregroundColor(.nbaGold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.nbaGold.opacity(0.15))
                        .cornerRadius(8)

                    if let jersey = vm.player.jerseyNumber {
                        Text("#\(jersey)")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                    }

                    if let team = vm.player.team {
                        HStack(spacing: 4) {
                            TeamLogoView(team: team, size: 20)
                            Text(team.abbreviation)
                                .font(.caption.bold())
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .padding(.vertical, 24)
        }
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "Profile")
                .padding(.bottom, 12)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 1) {
                infoCell(label: "Height",  value: vm.player.height  ?? "N/A")
                infoCell(label: "Weight",  value: vm.player.weight.map { "\($0) lbs" } ?? "N/A")
                infoCell(label: "Country", value: vm.player.country  ?? "N/A")
                infoCell(label: "College", value: vm.player.college  ?? "N/A")
                if let year = vm.player.draftYear {
                    infoCell(label: "Draft Year", value: "\(year)")
                    infoCell(label: "Draft Pick", value: vm.player.draftNumber.map { "Round \(vm.player.draftRound ?? 0), #\($0)" } ?? "N/A")
                }
            }
            .background(Color.nbaCard)
            .cornerRadius(14)
            .padding(.horizontal)
        }
    }

    private func infoCell(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.nbaSecondary)
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.nbaCard)
    }

    private func statsSection(avg: SeasonAverage) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "2024-25 Season Averages")
                .padding(.horizontal)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                StatBadge(label: "PTS",  value: String(format: "%.1f", avg.pts))
                StatBadge(label: "REB",  value: String(format: "%.1f", avg.reb))
                StatBadge(label: "AST",  value: String(format: "%.1f", avg.ast))
                StatBadge(label: "STL",  value: String(format: "%.1f", avg.stl))
                StatBadge(label: "BLK",  value: String(format: "%.1f", avg.blk))
                StatBadge(label: "TOV",  value: String(format: "%.1f", avg.turnover))
                StatBadge(label: "FG%",  value: String(format: "%.1f%%", avg.fgPct * 100))
                StatBadge(label: "3P%",  value: String(format: "%.1f%%", avg.fg3Pct * 100))
                StatBadge(label: "FT%",  value: String(format: "%.1f%%", avg.ftPct * 100))
            }
            .padding(.horizontal)

            HStack {
                Spacer()
                Text("\(avg.gamesPlayed) GP · \(avg.min ?? "-") MPG")
                    .font(.caption)
                    .foregroundColor(.nbaSecondary)
                Spacer()
            }
        }
    }

    private var noStatsView: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 30))
                .foregroundColor(.nbaSecondary)
            Text("No stats available")
                .foregroundColor(.nbaSecondary)
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}
