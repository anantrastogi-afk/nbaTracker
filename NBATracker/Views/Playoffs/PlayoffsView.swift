import SwiftUI

@MainActor
final class PlayoffsViewModel: ObservableObject {
    @Published var games: [Game] = []
    @Published var news: [Article] = []
    @Published var isLoading = false
    @Published var error: String?

    // Group today's postseason games; fetch news for context
    func load() async {
        isLoading = true; error = nil
        async let g = NBAService.shared.fetchScoreboard()
        async let n = NBAService.shared.fetchNews(limit: 5)
        do {
            let (all, articles) = try await (g, n)
            games = all.filter { $0.isPostseason }
            news  = articles
        } catch { self.error = error.localizedDescription }
        isLoading = false
    }
}

struct PlayoffsView: View {
    @StateObject private var vm = PlayoffsViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.nbaBG.ignoresSafeArea()
                if vm.isLoading { LoadingView() }
                else if let err = vm.error { ErrorView(message: err, retry: { Task { await vm.load() } }) }
                else { content }
            }
            .navigationTitle("Playoffs")
            .navigationBarTitleDisplayMode(.large)
        }
        .task { await vm.load() }
        .refreshable { await vm.load() }
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 20) {
                playoffsBanner

                if vm.games.isEmpty {
                    noGamesView
                } else {
                    SectionHeader(title: "Today's Playoff Games")
                    LazyVStack(spacing: 12) {
                        ForEach(vm.games, id: \.id) { game in
                            PlayoffGameCard(game: game).padding(.horizontal)
                        }
                    }
                }

                if !vm.news.isEmpty {
                    SectionHeader(title: "Playoff News").padding(.top, 8)
                    LazyVStack(spacing: 10) {
                        ForEach(vm.news, id: \.id) { article in
                            ArticleRow(article: article).padding(.horizontal)
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
                colors: [Color.nbaGold.opacity(0.35), Color.nbaRed.opacity(0.2)],
                startPoint: .leading, endPoint: .trailing
            )
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("NBA PLAYOFFS")
                        .font(.system(size: 22, weight: .black))
                        .foregroundColor(.nbaGold)
                        .tracking(2)
                    Text("2025-26 Season")
                        .font(.subheadline).foregroundColor(.white.opacity(0.75))
                }
                Spacer()
                Image(systemName: "trophy.fill")
                    .font(.system(size: 44)).foregroundColor(.nbaGold)
            }
            .padding(20)
        }
        .cornerRadius(16).padding(.horizontal).padding(.top, 8)
    }

    private var noGamesView: some View {
        VStack(spacing: 14) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 40)).foregroundColor(.nbaSecondary)
            Text("No playoff games today")
                .font(.headline).foregroundColor(.white)
            Text("Check back on game days")
                .foregroundColor(.nbaSecondary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 40)
    }
}

struct PlayoffGameCard: View {
    let game: Game

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                teamSide(competitor: game.awayTeam, isWinner: awayWins)
                centerSection
                teamSide(competitor: game.homeTeam, isWinner: homeWins)
            }
            .padding(16)
        }
        .background(Color.nbaCard)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(
            game.status.isLive ? Color.nbaGold.opacity(0.6) : Color.nbaGold.opacity(0.15),
            lineWidth: game.status.isLive ? 1.5 : 1
        ))
    }

    private func teamSide(competitor: Game.GameCompetitor, isWinner: Bool) -> some View {
        VStack(spacing: 8) {
            TeamLogoView(team: competitor.team, size: 56)
            Text(competitor.team.abbreviation)
                .font(.system(size: 14, weight: .bold)).foregroundColor(.white)
            if game.status.isScheduled {
                Text(competitor.record).font(.caption2).foregroundColor(.nbaSecondary)
            } else {
                Text("\(competitor.score)")
                    .font(.system(size: 32, weight: .black))
                    .foregroundColor(isWinner ? .white : .nbaSecondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var centerSection: some View {
        VStack(spacing: 6) {
            if game.status.isLive {
                HStack(spacing: 4) {
                    Circle().fill(Color.nbaRed).frame(width: 7, height: 7)
                    Text("LIVE").font(.system(size: 10, weight: .black)).foregroundColor(.nbaRed)
                }
            }
            Text(game.status.isFinal ? "Final" : game.status.isLive ? game.status.display : game.formattedTime)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(game.status.isLive ? .nbaRed : .nbaSecondary)
                .multilineTextAlignment(.center)
            Text("PLAYOFFS")
                .font(.system(size: 8, weight: .black))
                .foregroundColor(.nbaGold).tracking(1)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(Color.nbaGold.opacity(0.15)).cornerRadius(4)
            Text("@").font(.caption2).foregroundColor(.nbaSecondary)
        }
        .frame(width: 82)
    }

    private var homeWins: Bool { game.status.isFinal && game.homeTeam.score > game.awayTeam.score }
    private var awayWins: Bool { game.status.isFinal && game.awayTeam.score > game.homeTeam.score }
}
