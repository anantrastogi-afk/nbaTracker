import SwiftUI

@main
struct NBATrackerApp: App {
    @StateObject private var favorites = FavoritesStore()

    init() {
        configureNavigationBar()
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(favorites)
                .preferredColorScheme(.dark)
        }
    }

    private func configureNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.nbaBG)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }
}
