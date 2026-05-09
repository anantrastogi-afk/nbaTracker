import SwiftUI

@MainActor
final class TeamsViewModel: ObservableObject {
    @Published var teams: [Team] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var searchText = ""

    var filtered: [Team] {
        guard !searchText.isEmpty else { return teams }
        return teams.filter {
            $0.fullName.localizedCaseInsensitiveContains(searchText) ||
            $0.abbreviation.localizedCaseInsensitiveContains(searchText) ||
            $0.city.localizedCaseInsensitiveContains(searchText)
        }
    }

    var east: [Team] { filtered.filter { $0.conference == "East" } }
    var west: [Team] { filtered.filter { $0.conference == "West" } }

    func load() async {
        isLoading = true
        error = nil
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
            LazyVStack(alignment: .leading, spacing: 0) {
                if !vm.east.isEmpty {
                    SectionHeader(title: "Eastern Conference")
                        .padding(.top)
                    conferenceGrid(teams: vm.east)
                }
                if !vm.west.isEmpty {
                    SectionHeader(title: "Western Conference")
                        .padding(.top, 24)
                    conferenceGrid(teams: vm.west)
                }
            }
            .padding(.bottom)
        }
    }

    private func conferenceGrid(teams: [Team]) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(teams) { team in
                NavigationLink(destination: TeamDetailView(team: team)) {
                    TeamCard(team: team)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
}

struct TeamCard: View {
    let team: Team

    var body: some View {
        HStack(spacing: 12) {
            TeamLogoView(team: team, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(team.city)
                    .font(.caption)
                    .foregroundColor(.nbaSecondary)
                    .lineLimit(1)
                Text(team.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.nbaSecondary)
        }
        .padding(12)
        .background(Color.nbaCard)
        .cornerRadius(14)
    }
}
