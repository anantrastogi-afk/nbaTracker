import Foundation
import Combine

final class FavoritesStore: ObservableObject {
    @Published private(set) var followedTeams: [Team] = []

    private let key = "followedTeams_v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let saved = try? JSONDecoder().decode([Team].self, from: data) {
            followedTeams = saved
        }
    }

    func isFollowing(_ team: Team) -> Bool {
        followedTeams.contains(where: { $0.id == team.id })
    }

    func toggle(_ team: Team) {
        if isFollowing(team) {
            followedTeams.removeAll { $0.id == team.id }
        } else {
            followedTeams.append(team)
        }
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(followedTeams) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
