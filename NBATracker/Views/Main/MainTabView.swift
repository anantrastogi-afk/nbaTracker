import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            ScoreboardView()
                .tabItem { Label("Scoreboard", systemImage: "basketball.fill") }
                .tag(0)

            StandingsView()
                .tabItem { Label("Standings", systemImage: "list.number") }
                .tag(1)

            TeamsView()
                .tabItem { Label("Teams", systemImage: "shield.fill") }
                .tag(2)

            PlayersView()
                .tabItem { Label("Players", systemImage: "person.fill") }
                .tag(3)

            PlayoffsView()
                .tabItem { Label("Playoffs", systemImage: "trophy.fill") }
                .tag(4)
        }
        .tint(.nbaGold)
        .onAppear { configureTabBarAppearance() }
    }

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.nbaCard)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
