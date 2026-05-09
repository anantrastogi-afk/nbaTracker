import SwiftUI

@MainActor
final class TeamDetailViewModel: ObservableObject {
    @Published var players: [Player] = []
    @Published var injuries: [Injury] = []
    @Published var news: [Article] = []
    @Published var isLoading = false
    @Published var selectedTab = 0
    let team: Team

    init(team: Team) { self.team = team }

    func load() async {
        isLoading = true
        async let roster   = NBAService.shared.fetchRoster(teamId: team.id)
        async let allInj   = NBAService.shared.fetchInjuries()
        async let articles = NBAService.shared.fetchTeamNews(teamId: team.id)
        do {
            let (p, allI, n) = try await (roster, allInj, articles)
            players  = p.sorted { $0.fullName < $1.fullName }
            injuries = allI.filter { $0.teamName == team.displayName }
            news     = n
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
                    if vm.isLoading { LoadingView().frame(height: 200) }
                    else {
                        Group {
                            switch vm.selectedTab {
                            case 0: rosterSection
                            case 1: injurySection
                            default: newsSection
                            }
                        }
                        .animation(.easeInOut(duration: 0.2), value: vm.selectedTab)
                    }
                }
            }
        }
        .navigationTitle(vm.team.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.load() }
    }

    private var teamHeader: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: vm.team.color).opacity(0.4), Color.nbaBG],
                startPoint: .top, endPoint: .bottom
            )
            VStack(spacing: 12) {
                TeamLogoView(team: vm.team, size: 90)
                Text(vm.team.displayName)
                    .font(.title2.bold()).foregroundColor(.white)
            }
            .padding(.vertical, 28)
        }
    }

    private var tabPicker: some View {
        Picker("", selection: $vm.selectedTab) {
            Text("Roster").tag(0)
            Text("Injuries \(vm.injuries.isEmpty ? "" : "(\(vm.injuries.count))")").tag(1)
            Text("News").tag(2)
        }
        .pickerStyle(.segmented).padding().background(Color.nbaBG)
    }

    private var rosterSection: some View {
        LazyVStack(spacing: 1) {
            ForEach(vm.players, id: \.id) { player in
                NavigationLink(destination: PlayerDetailView(player: player, team: vm.team)) {
                    PlayerRow(player: player)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .background(Color.nbaCard).cornerRadius(16).padding(.horizontal).padding(.top, 8)
    }

    private var injurySection: some View {
        Group {
            if vm.injuries.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.shield.fill").font(.system(size: 40)).foregroundColor(.green)
                    Text("No reported injuries").foregroundColor(.nbaSecondary)
                }
                .frame(maxWidth: .infinity).padding(.top, 60)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(vm.injuries, id: \.id) { injury in
                        InjuryRow(injury: injury).padding(.horizontal)
                    }
                }
                .padding(.top, 8)
            }
        }
    }

    private var newsSection: some View {
        LazyVStack(spacing: 10) {
            if vm.news.isEmpty {
                Text("No recent news").foregroundColor(.nbaSecondary).padding(.top, 40)
            } else {
                ForEach(vm.news, id: \.id) { article in
                    ArticleRow(article: article).padding(.horizontal)
                }
            }
        }
        .padding(.top, 8)
    }
}

struct PlayerRow: View {
    let player: Player
    var body: some View {
        HStack(spacing: 12) {
            PlayerHeadshotView(player: player, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(player.fullName)
                    .font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                HStack(spacing: 8) {
                    Text("#\(player.jersey)").font(.caption2).foregroundColor(.nbaSecondary)
                    Text(player.position).font(.caption2).foregroundColor(.nbaSecondary)
                    if player.isInjured {
                        Text(player.injuryStatus ?? "")
                            .font(.caption2.bold())
                            .foregroundColor(.nbaRed)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(Color.nbaRed.opacity(0.15))
                            .cornerRadius(4)
                    }
                }
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption2).foregroundColor(.nbaSecondary)
        }
        .padding(.horizontal, 14).padding(.vertical, 10).background(Color.nbaCard)
    }
}

struct InjuryRow: View {
    let injury: Injury
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "cross.fill")
                .font(.system(size: 14))
                .foregroundColor(injury.statusColor)
                .frame(width: 32, height: 32)
                .background(injury.statusColor.opacity(0.15))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(injury.athleteName).font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                Text(injury.displayComment).font(.caption).foregroundColor(.nbaSecondary).lineLimit(2)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(injury.status)
                    .font(.caption.bold()).foregroundColor(injury.statusColor)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(injury.statusColor.opacity(0.15)).cornerRadius(6)
                if !injury.date.isEmpty {
                    Text(injury.date).font(.caption2).foregroundColor(.nbaSecondary)
                }
            }
        }
        .padding(14).background(Color.nbaCard).cornerRadius(14)
    }
}
