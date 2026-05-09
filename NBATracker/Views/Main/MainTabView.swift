import SwiftUI

// MARK: - App section enum

enum AppSection: String, CaseIterable {
    case home       = "Home"
    case scoreboard = "Scoreboard"
    case standings  = "Standings"
    case teams      = "Teams"
    case players    = "Players"
    case playoffs   = "Playoffs"

    var icon: String {
        switch self {
        case .home:       return "house.fill"
        case .scoreboard: return "basketball.fill"
        case .standings:  return "list.number"
        case .teams:      return "shield.fill"
        case .players:    return "person.fill"
        case .playoffs:   return "trophy.fill"
        }
    }
}

// MARK: - Router (drawer state + section switching)

final class AppRouter: ObservableObject {
    @Published var selectedSection: AppSection = .home
    @Published var isDrawerOpen = false

    func navigate(to section: AppSection) {
        withAnimation(.easeInOut(duration: 0.22)) {
            selectedSection = section
            isDrawerOpen = false
        }
    }

    func toggleDrawer() {
        withAnimation(.easeInOut(duration: 0.25)) { isDrawerOpen.toggle() }
    }

    func closeDrawer() {
        withAnimation(.easeInOut(duration: 0.25)) { isDrawerOpen = false }
    }
}

// MARK: - Reusable hamburger button

struct HamburgerButton: View {
    @EnvironmentObject var router: AppRouter

    var body: some View {
        Button { router.toggleDrawer() } label: {
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Root view

struct MainTabView: View {
    @StateObject private var router = AppRouter()

    var body: some View {
        ZStack(alignment: .leading) {
            // Main content
            currentSection
                .environmentObject(router)

            // Tap-outside-to-close overlay
            if router.isDrawerOpen {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .onTapGesture { router.closeDrawer() }
                    .transition(.opacity)
            }

            // Side drawer
            if router.isDrawerOpen {
                SideDrawer()
                    .frame(width: 285)
                    .shadow(color: .black.opacity(0.5), radius: 20, x: 6, y: 0)
                    .transition(.move(edge: .leading))
                    .zIndex(1)
            }
        }
        .environmentObject(router)
    }

    @ViewBuilder
    private var currentSection: some View {
        switch router.selectedSection {
        case .home:       HomeView()
        case .scoreboard: ScoreboardView()
        case .standings:  StandingsView()
        case .teams:      TeamsView()
        case .players:    PlayersView()
        case .playoffs:   PlayoffsView()
        }
    }
}

// MARK: - Side drawer

struct SideDrawer: View {
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var favorites: FavoritesStore

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color(red: 0.06, green: 0.07, blue: 0.15)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                drawerHeader
                goldDivider
                menuItems
                Spacer()
                drawerFooter
            }
        }
    }

    // ── Header ────────────────────────────────────────────────────────────────
    private var drawerHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "basketball.fill")
                .font(.system(size: 38))
                .foregroundColor(.nbaGold)

            Text("NBA Tracker")
                .font(.system(size: 22, weight: .black))
                .foregroundColor(.white)

            Text("2025–26 Season")
                .font(.caption)
                .foregroundColor(.nbaSecondary)
        }
        .padding(.horizontal, 22)
        .padding(.top, 64)
        .padding(.bottom, 22)
    }

    private var goldDivider: some View {
        Rectangle()
            .fill(Color.nbaGold.opacity(0.25))
            .frame(height: 1)
            .padding(.horizontal, 22)
    }

    // ── Menu items ────────────────────────────────────────────────────────────
    private var menuItems: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(AppSection.allCases, id: \.self) { section in
                DrawerRow(section: section,
                          isSelected: router.selectedSection == section,
                          badge: section == .home ? favorites.followedTeams.count : 0) {
                    router.navigate(to: section)
                }
            }
        }
        .padding(.top, 14)
    }

    // ── Footer ────────────────────────────────────────────────────────────────
    private var drawerFooter: some View {
        Text("NBA Tracker · v1.0")
            .font(.caption2)
            .foregroundColor(.nbaSecondary.opacity(0.5))
            .padding(.horizontal, 22)
            .padding(.bottom, 32)
    }
}

// MARK: - Drawer row

struct DrawerRow: View {
    let section: AppSection
    let isSelected: Bool
    let badge: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Left accent bar
                Rectangle()
                    .fill(isSelected ? Color.nbaGold : Color.clear)
                    .frame(width: 3)
                    .padding(.vertical, 6)

                // Icon
                Image(systemName: section.icon)
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? .nbaGold : .nbaSecondary)
                    .frame(width: 22)

                // Label
                Text(section.rawValue)
                    .font(.system(size: 16, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? .white : .nbaSecondary)

                Spacer()

                // Badge (followed team count on Home)
                if badge > 0 {
                    Text("\(badge)")
                        .font(.caption2.bold())
                        .foregroundColor(.black)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.nbaGold)
                        .clipShape(Capsule())
                        .padding(.trailing, 16)
                }
            }
            .frame(height: 50)
            .background(
                isSelected
                    ? Color.nbaGold.opacity(0.10)
                    : Color.clear
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
