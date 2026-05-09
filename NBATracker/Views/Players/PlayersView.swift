import SwiftUI

@MainActor
final class PlayersViewModel: ObservableObject {
    @Published var players: [Player] = []
    @Published var searchText = ""
    @Published var isLoading = false
    @Published var error: String?

    private var searchTask: Task<Void, Never>?

    func search() {
        searchTask?.cancel()
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else {
            players = []
            return
        }
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            isLoading = true
            error = nil
            do {
                players = try await NBAService.shared.searchPlayers(query: searchText)
            } catch {
                if !Task.isCancelled { self.error = error.localizedDescription }
            }
            isLoading = false
        }
    }
}

struct PlayersView: View {
    @StateObject private var vm = PlayersViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.nbaBG.ignoresSafeArea()
                VStack(spacing: 0) {
                    searchBar
                    if vm.isLoading { LoadingView() }
                    else if let err = vm.error { ErrorView(message: err, retry: { }) }
                    else if vm.searchText.isEmpty { promptState }
                    else if vm.players.isEmpty && !vm.isLoading { noResults }
                    else { playerGrid }
                }
            }
            .navigationTitle("Players")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.nbaSecondary)
            TextField("Search players...", text: $vm.searchText)
                .foregroundColor(.white)
                .autocorrectionDisabled()
                .onChange(of: vm.searchText) { vm.search() }
            if !vm.searchText.isEmpty {
                Button { vm.searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.nbaSecondary)
                }
            }
        }
        .padding(12)
        .background(Color.nbaCard)
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.nbaBG)
    }

    private var promptState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 50))
                .foregroundColor(.nbaGold)
            Text("Search for a player")
                .font(.title3.bold())
                .foregroundColor(.white)
            Text("Type a name to find player cards")
                .foregroundColor(.nbaSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var noResults: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.slash")
                .font(.system(size: 40))
                .foregroundColor(.nbaSecondary)
            Text("No players found")
                .foregroundColor(.white)
                .font(.headline)
            Text("Try a different name")
                .foregroundColor(.nbaSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var playerGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(vm.players) { player in
                    NavigationLink(destination: PlayerDetailView(player: player)) {
                        PlayerCard(player: player)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
        }
    }
}
