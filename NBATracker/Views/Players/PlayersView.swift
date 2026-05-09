import SwiftUI

@MainActor
final class PlayersViewModel: ObservableObject {
    @Published var teams: [Team] = []
    @Published var players: [Player] = []
    @Published var selectedTeam: Team? = nil
    @Published var isLoading = false
    @Published var error: String?

    func loadTeams() async {
        guard teams.isEmpty else { return }
        do { teams = try await NBAService.shared.fetchTeams() }
        catch { self.error = error.localizedDescription }
    }

    func loadPlayers(for team: Team) async {
        isLoading = true; error = nil; selectedTeam = team
        do { players = try await NBAService.shared.fetchRoster(teamId: team.id) }
        catch { self.error = error.localizedDescription }
        isLoading = false
    }
}

struct PlayersView: View {
    @StateObject private var vm = PlayersViewModel()
    @State private var showTeamPicker = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.nbaBG.ignoresSafeArea()
                VStack(spacing: 0) {
                    teamPickerBar
                    if vm.isLoading { LoadingView() }
                    else if let err = vm.error { ErrorView(message: err, retry: { }) }
                    else if vm.selectedTeam == nil { promptState }
                    else { playerGrid }
                }
            }
            .navigationTitle("Players")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showTeamPicker) {
                TeamPickerSheet(teams: vm.teams, selectedTeam: $vm.selectedTeam) { team in
                    Task { await vm.loadPlayers(for: team) }
                }
            }
        }
        .task { await vm.loadTeams() }
    }

    private var teamPickerBar: some View {
        Button {
            showTeamPicker = true
        } label: {
            HStack {
                if let t = vm.selectedTeam {
                    TeamLogoView(team: t, size: 28)
                    Text(t.displayName).font(.headline).foregroundColor(.white)
                } else {
                    Image(systemName: "shield.fill").foregroundColor(.nbaGold)
                    Text("Select a Team").font(.headline).foregroundColor(.nbaGold)
                }
                Spacer()
                Image(systemName: "chevron.down").font(.caption).foregroundColor(.nbaSecondary)
            }
            .padding(14)
            .background(Color.nbaCard)
            .cornerRadius(12)
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color.nbaBG)
    }

    private var promptState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.fill").font(.system(size: 50)).foregroundColor(.nbaGold)
            Text("Select a team above").font(.title3.bold()).foregroundColor(.white)
            Text("Browse the full roster with player photos").foregroundColor(.nbaSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var playerGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(vm.players, id: \.id) { player in
                    NavigationLink(destination: PlayerDetailView(player: player, team: vm.selectedTeam)) {
                        PlayerCard(player: player, team: vm.selectedTeam)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
        }
    }
}

struct TeamPickerSheet: View {
    let teams: [Team]
    @Binding var selectedTeam: Team?
    let onSelect: (Team) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.nbaBG.ignoresSafeArea()
                List(teams, id: \.id) { team in
                    Button {
                        selectedTeam = team
                        onSelect(team)
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            TeamLogoView(team: team, size: 36)
                            Text(team.displayName).foregroundColor(.white)
                            Spacer()
                            if selectedTeam?.id == team.id {
                                Image(systemName: "checkmark").foregroundColor(.nbaGold)
                            }
                        }
                    }
                    .listRowBackground(Color.nbaCard)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Select Team")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(.nbaGold)
                }
            }
        }
    }
}
