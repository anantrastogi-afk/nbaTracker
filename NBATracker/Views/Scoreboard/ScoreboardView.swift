import SwiftUI

@MainActor
final class ScoreboardViewModel: ObservableObject {
    @Published var games: [Game] = []
    @Published var isLoading = false
    @Published var error: String?

    func load() async {
        isLoading = true
        error = nil
        do {
            games = try await NBAService.shared.fetchTodaysGames()
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}

struct ScoreboardView: View {
    @StateObject private var vm = ScoreboardViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.nbaBG.ignoresSafeArea()

                if vm.isLoading { LoadingView() }
                else if let err = vm.error { ErrorView(message: err, retry: { Task { await vm.load() } }) }
                else if vm.games.isEmpty { emptyState }
                else { gameList }
            }
            .navigationTitle("Scoreboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    todayLabel
                }
            }
        }
        .task { await vm.load() }
        .refreshable { await vm.load() }
    }

    private var todayLabel: some View {
        Text(Date(), format: .dateTime.weekday(.wide).month().day())
            .font(.caption)
            .foregroundColor(.nbaSecondary)
    }

    private var gameList: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(vm.games) { game in
                    GameCard(game: game)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "basketball")
                .font(.system(size: 50))
                .foregroundColor(.nbaGold)
            Text("No games today")
                .foregroundColor(.white)
                .font(.title3.bold())
            Text("Check back on game day")
                .foregroundColor(.nbaSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
