import Foundation

enum NBAError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case serverError(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:              return "Invalid URL"
        case .networkError(let e):     return e.localizedDescription
        case .decodingError(let e):    return "Data error: \(e.localizedDescription)"
        case .serverError(let code):   return "Server error \(code)"
        }
    }
}

final class NBAService {
    static let shared = NBAService()
    private init() {}

    private func request<T: Decodable>(_ path: String, params: [String: String] = [:]) async throws -> T {
        var components = URLComponents(string: "\(NBAConfig.baseURL)\(path)")!
        if !params.isEmpty {
            components.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let url = components.url else { throw NBAError.invalidURL }

        var req = URLRequest(url: url)
        req.setValue(NBAConfig.apiKey, forHTTPHeaderField: "Authorization")
        req.timeoutInterval = 15

        let (data, response): (Data, URLResponse)
        do { (data, response) = try await URLSession.shared.data(for: req) }
        catch { throw NBAError.networkError(error) }

        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw NBAError.serverError(http.statusCode)
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NBAError.decodingError(error)
        }
    }

    // MARK: Teams
    func fetchTeams() async throws -> [Team] {
        let response: TeamsResponse = try await request("/teams", params: ["per_page": "30"])
        return response.data.sorted { $0.fullName < $1.fullName }
    }

    // MARK: Players
    func fetchPlayers(teamId: Int, page: Int = 1) async throws -> PlayersResponse {
        return try await request("/players", params: [
            "team_ids[]": "\(teamId)",
            "per_page": "50",
            "page": "\(page)"
        ])
    }

    func searchPlayers(query: String) async throws -> [Player] {
        let response: PlayersResponse = try await request("/players", params: [
            "search": query,
            "per_page": "25"
        ])
        return response.data
    }

    // MARK: Games
    func fetchTodaysGames() async throws -> [Game] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        let response: GamesResponse = try await request("/games", params: [
            "dates[]": today,
            "per_page": "15"
        ])
        return response.data
    }

    func fetchRecentGames(teamId: Int) async throws -> [Game] {
        let response: GamesResponse = try await request("/games", params: [
            "team_ids[]": "\(teamId)",
            "seasons[]": "\(NBAConfig.currentSeason)",
            "per_page": "10",
            "page": "1"
        ])
        return response.data.sorted { $0.date > $1.date }
    }

    func fetchPlayoffGames() async throws -> [Game] {
        let response: GamesResponse = try await request("/games", params: [
            "postseason": "true",
            "seasons[]": "\(NBAConfig.currentSeason)",
            "per_page": "100"
        ])
        return response.data.sorted { $0.date < $1.date }
    }

    // MARK: Standings
    func fetchStandings() async throws -> [Standing] {
        let response: StandingsResponse = try await request("/standings", params: [
            "season": "\(NBAConfig.currentSeason)"
        ])
        return response.data
    }

    // MARK: Season Averages
    func fetchSeasonAverages(playerIds: [Int]) async throws -> [SeasonAverage] {
        let idsParam = playerIds.map { "\($0)" }.joined(separator: ",")
        let response: SeasonAveragesResponse = try await request("/season_averages", params: [
            "season": "\(NBAConfig.currentSeason)",
            "player_ids[]": idsParam
        ])
        return response.data
    }
}
