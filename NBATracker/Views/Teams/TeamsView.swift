import SwiftUI

@MainActor
final class TeamsViewModel: ObservableObject {
    @Published var teams: [Team] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var searchText = ""

    var filtered: [Team] {
        searchText.isEmpty ? teams : teams.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText) ||
            $0.abbreviation.localizedCaseInsensitiveContains(searchText) ||
            $0.location.localizedCaseInsensitiveContains(searchText)
        }
    }

    func load() async {
        isLoading = true; error = nil
        do { teams = try await NBAService.shared.fetchTeams() }
        catch { self.error = error.localizedDescription }
        isLoading = false
    }
}

struct TeamsView: View {
    @StateObject private var vm = TeamsViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.nbaBG.ignoresSafeArea()
                if vm.isLoading { LoadingView() }
                else if let err = vm.error { ErrorView(message: err, retry: { Task { await vm.load() } }) }
                else { content }
            }
            .navigationTitle("Teams")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $vm.searchText, prompt: "Search teams")
        }
        .task { await vm.load() }
    }

    private var content: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(vm.filtered, id: \.id) { team in
                    NavigationLink(destination: TeamDetailView(team: team)) {
                        TeamCard(team: team)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
        }
    }
}

struct TeamCard: View {
    let team: Team

    var body: some View {
        HStack(spacing: 10) {
            TeamLogoView(team: team, size: 42)
            VStack(alignment: .leading, spacing: 2) {
                Text(team.location)
                    .font(.caption2).foregroundColor(.nbaSecondary).lineLimit(1)
                Text(team.name)
                    .font(.system(size: 14, weight: .bold)).foregroundColor(.white).lineLimit(1)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption2).foregroundColor(.nbaSecondary)
        }
        .padding(12)
        .background(Color.nbaCard)
        .cornerRadius(14)
    }
}
