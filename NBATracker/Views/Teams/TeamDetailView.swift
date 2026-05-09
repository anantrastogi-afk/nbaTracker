import SwiftUI

@MainActor
final class TeamDetailViewModel: ObservableObject {
    @Published var players: [Player] = []
    @Published var recentGames: [Game] = []
    @Published var isLoading = false
    @Published var selectedTab = 0

    let team: Team

    init(team: Team) { self.team = team }

    func load() async {
        isLoading = true
        async let playersRes = NBAService.shared.fetchPlayers(teamId: team.id)
        async let gamesRes   = NBAService.shared.fetchRecentGames(teamId: team.id)
        do {
            let (p, g) = try await (playersRes, gamesRes)
            players     = p.data.sorted { $0.lastName < $1.lastName }
            recentGames = g
        } catch { }
        isLoading = false
    }
}

struct TeamDetailView: View {
    @StateObject private var vm: TeamDetailViewModel
    init(team: Team) { _vm = StateObject(wrappedValue: TeamDetailViewModel(team: team)) }

    var body: some View {
        ZStack {
            Color.nbaBG.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    teamHeader
                    tabPicker
                    switch vm.selectedTab {
                    case 0: rosterSection
                    case 1: recentGamesSection
                    default: injurySection
                    }
                }
            }
        }
        .navigationTitle(vm.team.fullName)
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.load() }
    }

    private var teamHeader: some View {
        ZStack {
            Color(hex: vm.team.primaryColor).opacity(0.15)
            VStack(spacing: 12) {
                TeamLogoView(team: vm.team, size: 90)
                Text(vm.team.fullName)
                    .font(.title2.bold())
                    .foregroundColor(.white)
                HStack(spacing: 20) {
                    Label(vm.team.conference, systemImage: "map")
                    Label(vm.team.division, systemImage: "square.grid.2x2")
                }
                .font(.caption)
                .foregroundColor(.nbaSecondary)
            }
            .padding(.vertical, 24)
        }
    }

    private var tabPicker: some View {
        Picker("", selection: $vm.selectedTab) {
            Text("Roster").tag(0)
            Text("Recent Games").tag(1)
            Text("Injuries").tag(2)
        }
        .pickerStyle(.segmented)
        .padding()
        .background(Color.nbaBG)
    }

    private var rosterSection: some View {
        Group {
            if vm.isLoading { LoadingView().frame(height: 300) }
            else {
                LazyVStack(spacing: 1) {
                    ForEach(vm.players) { player in
                        NavigationLink(destination: PlayerDetailView(player: player)) {
                            PlayerRow(player: player)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .background(Color.nbaCard)
                .cornerRadius(16)
                .padding(.horizontal)
            }
        }
    }

    private var recentGamesSection: some View {
        LazyVStack(spacing: 12) {
            ForEach(vm.recentGames) { game in
                GameCard(game: game).padding(.horizontal)
            }
        }
        .padding(.top, 8)
    }

    private var injurySection: some View {
        let teamInjuries = Injury.mockData.filter { $0.team == vm.team.abbreviation }
        return LazyVStack(spacing: 10) {
            if teamInjuries.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.green)
                    Text("No reported injuries")
                        .foregroundColor(.nbaSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
            } else {
                ForEach(teamInjuries) { injury in
                    InjuryRow(injury: injury)
                        .padding(.horizontal)
                }
            }
        }
        .padding(.top, 8)
    }
}

struct PlayerRow: View {
    let player: Player

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.nbaGold.opacity(0.2))
                    .frame(width: 40, height: 40)
                Text(player.initials)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.nbaGold)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(player.fullName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                HStack(spacing: 8) {
                    if let jersey = player.jerseyNumber {
                        Text("#\(jersey)")
                            .font(.caption2)
                            .foregroundColor(.nbaSecondary)
                    }
                    Text(player.positionDisplay)
                        .font(.caption2)
                        .foregroundColor(.nbaSecondary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundColor(.nbaSecondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.nbaCard)
    }
}

struct InjuryRow: View {
    let injury: Injury

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "cross.fill")
                .font(.system(size: 16))
                .foregroundColor(Color(hex: injury.status.color))
                .frame(width: 32, height: 32)
                .background(Color(hex: injury.status.color).opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(injury.playerName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Text(injury.description)
                    .font(.caption)
                    .foregroundColor(.nbaSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(injury.status.rawValue)
                    .font(.caption.bold())
                    .foregroundColor(Color(hex: injury.status.color))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(hex: injury.status.color).opacity(0.15))
                    .cornerRadius(6)
                Text(injury.updatedDate)
                    .font(.caption2)
                    .foregroundColor(.nbaSecondary)
            }
        }
        .padding(14)
        .background(Color.nbaCard)
        .cornerRadius(14)
    }
}
