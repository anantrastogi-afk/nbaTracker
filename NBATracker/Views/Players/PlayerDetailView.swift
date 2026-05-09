import SwiftUI

// MARK: - ViewModel

@MainActor
final class PlayerDetailViewModel: ObservableObject {
    @Published var news: [Article] = []
    @Published var isLoadingNews = true

    let player: Player

    init(player: Player) { self.player = player }

    func load() async {
        isLoadingNews = true
        do {
            news = try await NBAService.shared.fetchPlayerNews(
                playerId: player.id,
                playerName: player.fullName
            )
        } catch {}
        isLoadingNews = false
    }
}

// MARK: - View

struct PlayerDetailView: View {
    let player: Player
    let team: Team?
    @StateObject private var vm: PlayerDetailViewModel

    init(player: Player, team: Team?) {
        self.player = player
        self.team   = team
        _vm = StateObject(wrappedValue: PlayerDetailViewModel(player: player))
    }

    var body: some View {
        ZStack {
            Color.nbaBG.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    profileHeader
                    infoGrid
                    if player.isInjured { injuryBanner }
                    newsSection
                }
                .padding(.bottom, 30)
            }
        }
        .navigationTitle(player.fullName)
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.load() }
    }

    // MARK: - Profile header

    private var profileHeader: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: team?.color ?? "1D428A").opacity(0.35), Color.nbaBG],
                startPoint: .top, endPoint: .bottom
            )
            VStack(spacing: 14) {
                PlayerHeadshotView(player: player, size: 110)
                Text(player.fullName).font(.title2.bold()).foregroundColor(.white)
                HStack(spacing: 12) {
                    badge(player.position, color: .nbaGold)
                    Text("#\(player.jersey)").font(.caption.bold()).foregroundColor(.white)
                    if let team {
                        HStack(spacing: 4) {
                            TeamLogoView(team: team, size: 20)
                            Text(team.abbreviation).font(.caption.bold()).foregroundColor(.white)
                        }
                    }
                }
            }
            .padding(.vertical, 28)
        }
    }

    // MARK: - Info grid

    private var infoGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Profile")
                .padding(.horizontal)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 1) {
                infoCell("Height",  player.displayHeight)
                infoCell("Weight",  player.displayWeight)
                if let age = player.age { infoCell("Age", "\(age)") }
                if let college = player.college, !college.isEmpty { infoCell("College", college) }
                if let city = player.birthCity, let country = player.birthCountry {
                    infoCell("Hometown", "\(city), \(country)")
                } else if let country = player.birthCountry {
                    infoCell("Country", country)
                }
            }
            .background(Color.nbaCard).cornerRadius(14).padding(.horizontal)
        }
    }

    private func infoCell(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption).foregroundColor(.nbaSecondary)
            Text(value).font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.nbaCard)
    }

    // MARK: - Injury banner

    private var injuryBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "cross.fill")
                .font(.system(size: 16))
                .foregroundColor(.nbaRed)
                .frame(width: 36, height: 36)
                .background(Color.nbaRed.opacity(0.15))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(player.injuryStatus ?? "Injured")
                    .font(.subheadline.bold()).foregroundColor(.nbaRed)
                if let detail = player.injuryDetail, !detail.isEmpty {
                    Text(detail).font(.caption).foregroundColor(.nbaSecondary).lineLimit(3)
                }
            }
            Spacer()
        }
        .padding(14)
        .background(Color.nbaRed.opacity(0.08))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.nbaRed.opacity(0.3), lineWidth: 1))
        .padding(.horizontal)
    }

    // MARK: - News / Recovery news

    private var newsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: player.isInjured ? "Recovery News" : "Player News")
                .padding(.horizontal)
                .padding(.top, 4)

            if vm.isLoadingNews {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Loading news…")
                        .font(.subheadline)
                        .foregroundColor(.nbaSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)

            } else if vm.news.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: player.isInjured ? "bandage" : "newspaper")
                        .font(.system(size: 32))
                        .foregroundColor(.nbaSecondary)
                    Text(player.isInjured
                         ? "No recovery news found"
                         : "No recent news found")
                        .font(.subheadline)
                        .foregroundColor(.nbaSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)

            } else {
                LazyVStack(spacing: 10) {
                    ForEach(vm.news, id: \.id) { article in
                        ArticleRow(article: article)
                            .padding(.horizontal)
                    }
                }
                .padding(.top, 10)
                .padding(.bottom, 10)
            }
        }
    }

    // MARK: - Helpers

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption.bold()).foregroundColor(color)
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(color.opacity(0.15)).cornerRadius(8)
    }
}
