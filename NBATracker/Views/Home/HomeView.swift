import SwiftUI

struct HomeView: View {
    @EnvironmentObject var favorites: FavoritesStore
    @EnvironmentObject var router: AppRouter

    var body: some View {
        NavigationStack {
            ZStack {
                Color.nbaBG.ignoresSafeArea()
                if favorites.followedTeams.isEmpty {
                    emptyState
                } else {
                    content
                }
            }
            .navigationTitle("My Teams")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { HamburgerButton() }
            }
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                SectionHeader(title: "Following \(favorites.followedTeams.count) team\(favorites.followedTeams.count == 1 ? "" : "s")")

                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 14
                ) {
                    ForEach(favorites.followedTeams, id: \.id) { team in
                        NavigationLink(destination: TeamDetailView(team: team)) {
                            FavoriteTeamCard(team: team)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.bottom, 30)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.nbaGold, Color.nbaGold.opacity(0.2))

            Text("No favorite teams yet")
                .font(.title3.bold())
                .foregroundColor(.white)

            Text("Tap the star on any team's page\nto follow them here.")
                .font(.subheadline)
                .foregroundColor(.nbaSecondary)
                .multilineTextAlignment(.center)

            Button {
                router.navigate(to: .teams)
            } label: {
                Label("Browse Teams", systemImage: "shield.fill")
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.nbaGold)
                    .cornerRadius(12)
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 40)
    }
}

struct FavoriteTeamCard: View {
    let team: Team

    var body: some View {
        VStack(spacing: 0) {
            // Colored header with team logo
            ZStack {
                LinearGradient(
                    colors: [
                        Color(hex: team.color).opacity(0.55),
                        Color(hex: team.color).opacity(0.15)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                TeamLogoView(team: team, size: 72)
                    .padding(.vertical, 18)
            }

            // Name footer
            VStack(spacing: 3) {
                Text(team.location)
                    .font(.caption2)
                    .foregroundColor(.nbaSecondary)
                    .lineLimit(1)
                Text(team.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(Color.nbaCard)
        }
        .background(Color.nbaCard)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: team.color).opacity(0.35), lineWidth: 1)
        )
    }
}
