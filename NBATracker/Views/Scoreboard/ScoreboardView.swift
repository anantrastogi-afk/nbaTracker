import SwiftUI

@MainActor
final class ScoreboardViewModel: ObservableObject {
    @Published var games: [Game] = []
    @Published var news: [Article] = []
    @Published var isLoading = false
    @Published var error: String?

    func load() async {
        isLoading = true; error = nil
        async let g = NBAService.shared.fetchScoreboard()
        async let n = NBAService.shared.fetchNews(limit: 8)
        do { (games, news) = try await (g, n) }
        catch { self.error = error.localizedDescription }
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
                else { content }
            }
            .navigationTitle("Scoreboard")
            .navigationBarTitleDisplayMode(.large)
        }
        .task { await vm.load() }
        .refreshable { await vm.load() }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Today's date
                Text(Date(), format: .dateTime.weekday(.wide).month().day().year())
                    .font(.caption)
                    .foregroundColor(.nbaSecondary)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                if vm.games.isEmpty {
                    noGamesView
                } else {
                    SectionHeader(title: "Today's Games")
                    LazyVStack(spacing: 12) {
                        ForEach(vm.games, id: \.id) { game in
                            GameCard(game: game).padding(.horizontal)
                        }
                    }
                    .padding(.top, 10)
                }

                if !vm.news.isEmpty {
                    SectionHeader(title: "Latest News")
                        .padding(.top, 28)
                    LazyVStack(spacing: 10) {
                        ForEach(vm.news, id: \.id) { article in
                            ArticleRow(article: article).padding(.horizontal)
                        }
                    }
                    .padding(.top, 10)
                }
            }
            .padding(.bottom, 30)
        }
    }

    private var noGamesView: some View {
        VStack(spacing: 12) {
            Image(systemName: "basketball").font(.system(size: 44)).foregroundColor(.nbaGold)
            Text("No games today").font(.title3.bold()).foregroundColor(.white)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 40)
    }
}

struct ArticleRow: View {
    let article: Article

    var body: some View {
        HStack(spacing: 12) {
            if let url = article.imageURL {
                AsyncImage(url: url) { phase in
                    if case .success(let img) = phase { img.resizable().scaledToFill() }
                    else { Color.nbaCard }
                }
                .frame(width: 80, height: 60)
                .clipped()
                .cornerRadius(8)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(article.headline)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                Text(article.timeAgo)
                    .font(.caption2)
                    .foregroundColor(.nbaSecondary)
            }
            Spacer()
        }
        .padding(12)
        .background(Color.nbaCard)
        .cornerRadius(12)
    }
}
