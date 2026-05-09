import SwiftUI

@MainActor
final class PlayoffsViewModel: ObservableObject {
    @Published var games: [Game] = []
    @Published var isLoading = false
    @Published var error: String?

    var rounds: [PlayoffRound] {
        buildRounds(from: games)
    }

    func load() async {
        isLoading = true
        error = nil
        do { games = try await NBAService.shared.fetchPlayoffGames() }
        catch { self.error = error.localizedDescription }
        isLoading = false
    }

    private func buildRounds(from games: [Game]) -> [PlayoffRound] {
        guard !games.isEmpty else { return [] }
        // Group games by matchup pairs
        var matchups: [String: [Game]] = [:]
        for game in games {
            let ids = [game.homeTeam.id, game.visitorTeam.id].sorted()
            let key = "\(ids[0])-\(ids[1])"
            matchups[key, default: []].append(game)
        }
        let series = matchups.values.map { PlayoffSeries(games: $0) }
        // Simple round grouping by series count
        let sorted = series.sorted { $0.startDate < $1.startDate }
        var rounds: [PlayoffRound] = []
        let roundNames = ["First Round", "Conference Semifinals", "Conference Finals", "NBA Finals"]
        let chunkSizes = [8, 4, 2, 1]
        var offset = 0
        for (i, size) in chunkSizes.enumerated() {
            let chunk = Array(sorted.dropFirst(offset).prefix(size))
            if !chunk.isEmpty {
                rounds.append(PlayoffRound(name: roundNames[i], series: chunk))
            }
            offset += size
        }
        return rounds
    }
}

struct PlayoffRound: Identifiable {
    let id = UUID()
    let name: String
    let series: [PlayoffSeries]
}

struct PlayoffSeries: Identifiable {
    let id = UUID()
    let games: [Game]

    var homeTeam: Team  { games.first!.homeTeam }
    var awayTeam: Team  { games.first!.visitorTeam }
    var homeWins: Int   { games.filter { $0.homeTeamScore > $0.visitorTeamScore && $0.status.lowercased() == "final" }.count }
    var awayWins: Int   { games.filter { $0.visitorTeamScore > $0.homeTeamScore && $0.status.lowercased() == "final" }.count }
    var startDate: String { games.map(\.date).min() ?? "" }

    var seriesScore: String { "\(awayWins)-\(homeWins)" }
    var leader: Team? {
        if homeWins > awayWins { return homeTeam }
        if awayWins > homeWins { return awayTeam }
        return nil
    }
    var isComplete: Bool { homeWins == 4 || awayWins == 4 }
}

struct PlayoffsView: View {
    @StateObject private var vm = PlayoffsViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.nbaBG.ignoresSafeArea()
                if vm.isLoading { LoadingView() }
                else if let err = vm.error { ErrorView(message: err, retry: { Task { await vm.load() } }) }
                else if vm.rounds.isEmpty { offseasonView }
                else { bracketContent }
            }
            .navigationTitle("Playoffs")
            .navigationBarTitleDisplayMode(.large)
        }
        .task { await vm.load() }
        .refreshable { await vm.load() }
    }

    private var bracketContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                playoffsBanner
                ForEach(vm.rounds) { round in
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: round.name)
                        ForEach(round.series) { series in
                            SeriesCard(series: series)
                                .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.bottom, 30)
        }
    }

    private var playoffsBanner: some View {
        ZStack {
            LinearGradient(
                colors: [Color.nbaGold.opacity(0.3), Color.nbaRed.opacity(0.2)],
                startPoint: .leading, endPoint: .trailing
            )
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("NBA PLAYOFFS")
                        .font(.system(size: 22, weight: .black))
                        .foregroundColor(.nbaGold)
                        .tracking(2)
                    Text("2024-25 Season")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                Spacer()
                Image(systemName: "trophy.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.nbaGold)
            }
            .padding(20)
        }
        .cornerRadius(16)
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var offseasonView: some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 60))
                .foregroundColor(.nbaGold.opacity(0.3))
            Text("Playoffs Not Started")
                .font(.title3.bold())
                .foregroundColor(.white)
            Text("Check back when the postseason begins")
                .foregroundColor(.nbaSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct SeriesCard: View {
    let series: PlayoffSeries

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                seriesSide(team: series.awayTeam, wins: series.awayWins, isLeader: series.awayWins > series.homeWins)
                VStack(spacing: 4) {
                    Text(series.seriesScore)
                        .font(.system(size: 24, weight: .black))
                        .foregroundColor(.white)
                    Text(series.isComplete ? "FINAL" : "SERIES")
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(series.isComplete ? .nbaGold : .nbaSecondary)
                        .tracking(1)
                    Text("\(series.games.count) games played")
                        .font(.caption2)
                        .foregroundColor(.nbaSecondary)
                }
                .frame(width: 90)
                seriesSide(team: series.homeTeam, wins: series.homeWins, isLeader: series.homeWins > series.awayWins)
            }
            if series.isComplete, let winner = series.leader {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.nbaGold)
                    Text("\(winner.fullName) advance")
                        .font(.caption.bold())
                        .foregroundColor(.nbaGold)
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(Color.nbaCard)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(series.isComplete ? Color.nbaGold.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }

    private func seriesSide(team: Team, wins: Int, isLeader: Bool) -> some View {
        VStack(spacing: 8) {
            TeamLogoView(team: team, size: 50)
            Text(team.abbreviation)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(isLeader ? .white : .nbaSecondary)
            HStack(spacing: 4) {
                ForEach(0..<4) { i in
                    Circle()
                        .fill(i < wins ? Color.nbaGold : Color.white.opacity(0.1))
                        .frame(width: 8, height: 8)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}
