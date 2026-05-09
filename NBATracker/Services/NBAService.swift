import Foundation

enum NBAError: Error, LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case rateLimited
    case serverError(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:          return "Invalid URL"
        case .networkError(let e): return e.localizedDescription
        case .decodingError(let e): return "Unexpected data: \(e.localizedDescription)"
        case .rateLimited:         return "Too many requests — please wait a moment and try again"
        case .serverError(let c):  return "Server error (\(c))"
        }
    }
}

// MARK: - Cache

private struct CacheEntry {
    let data: Data
    let expiry: Date
    var isValid: Bool { Date() < expiry }
}

private final class ResponseCache {
    static let shared = ResponseCache()
    private var store: [String: CacheEntry] = [:]
    private let lock = NSLock()

    func get(_ key: String) -> Data? {
        lock.lock(); defer { lock.unlock() }
        guard let e = store[key], e.isValid else { store.removeValue(forKey: key); return nil }
        return e.data
    }

    func set(_ key: String, data: Data, ttl: TimeInterval) {
        lock.lock(); defer { lock.unlock() }
        store[key] = CacheEntry(data: data, expiry: Date().addingTimeInterval(ttl))
    }
}

private enum TTL {
    static let teams:    TimeInterval = 3600
    static let players:  TimeInterval = 1800
    static let games:    TimeInterval = 60
    static let standings: TimeInterval = 300
}

// MARK: - Service

final class NBAService {
    static let shared = NBAService()
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.urlCache = URLCache(memoryCapacity: 10_000_000, diskCapacity: 50_000_000)
        session = URLSession(configuration: config)
    }

    // MARK: Core request

    private func request<T: Decodable>(
        _ path: String,
        params: [(String, String)] = [],
        ttl: TimeInterval,
        retries: Int = 3
    ) async throws -> T {
        var components = URLComponents(string: "\(NBAConfig.baseURL)\(path)")!
        components.queryItems = params.map { URLQueryItem(name: $0.0, value: $0.1) }
        guard let url = components.url else { throw NBAError.invalidURL }

        let cacheKey = url.absoluteString
        if let cached = ResponseCache.shared.get(cacheKey) {
            return try decode(cached)
        }

        var lastError: Error = NBAError.serverError(0)

        for attempt in 0..<retries {
            if attempt > 0 {
                try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attempt))) * 1_000_000_000)
            }

            var req = URLRequest(url: url)
            req.setValue(NBAConfig.apiKey, forHTTPHeaderField: "Authorization")
            req.timeoutInterval = 15

            let data: Data
            let response: URLResponse
            do { (data, response) = try await session.data(for: req) }
            catch { lastError = NBAError.networkError(error); continue }

            guard let http = response as? HTTPURLResponse else { continue }

            if http.statusCode == 429 {
                try await Task.sleep(nanoseconds: UInt64(5 * (attempt + 1)) * 1_000_000_000)
                lastError = NBAError.rateLimited
                continue
            }

            guard (200...299).contains(http.statusCode) else {
                throw NBAError.serverError(http.statusCode)
            }

            ResponseCache.shared.set(cacheKey, data: data, ttl: ttl)
            return try decode(data)
        }
        throw lastError
    }

    private func decode<T: Decodable>(_ data: Data) throws -> T {
        do { return try JSONDecoder().decode(T.self, from: data) }
        catch { throw NBAError.decodingError(error) }
    }

    // MARK: Teams

    func fetchTeams() async throws -> [Team] {
        let res: TeamsResponse = try await request(
            "/teams", params: [("per_page", "30")], ttl: TTL.teams
        )
        return res.data.sorted { $0.fullName < $1.fullName }
    }

    // MARK: Players

    func fetchPlayers(teamId: Int, cursor: Int? = nil) async throws -> PlayersResponse {
        var params = [("team_ids[]", "\(teamId)"), ("per_page", "50")]
        if let c = cursor { params.append(("cursor", "\(c)")) }
        return try await request("/players", params: params, ttl: TTL.players)
    }

    func searchPlayers(query: String) async throws -> [Player] {
        let res: PlayersResponse = try await request(
            "/players",
            params: [("search", query), ("per_page", "25")],
            ttl: TTL.players
        )
        return res.data
    }

    // MARK: Games

    func fetchTodaysGames() async throws -> [Game] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        let res: GamesResponse = try await request(
            "/games",
            params: [("dates[]", today), ("per_page", "15")],
            ttl: TTL.games
        )
        return res.data
    }

    func fetchRecentGames(teamId: Int) async throws -> [Game] {
        let res: GamesResponse = try await request(
            "/games",
            params: [
                ("team_ids[]", "\(teamId)"),
                ("seasons[]", "\(NBAConfig.currentSeason)"),
                ("per_page", "10")
            ],
            ttl: TTL.games
        )
        return res.data.sorted { $0.date > $1.date }
    }

    func fetchPlayoffGames() async throws -> [Game] {
        let res: GamesResponse = try await request(
            "/games",
            params: [
                ("postseason", "true"),
                ("seasons[]", "\(NBAConfig.currentSeason)"),
                ("per_page", "100")
            ],
            ttl: TTL.games
        )
        return res.data.sorted { $0.date < $1.date }
    }

    // MARK: Standings (computed from game results — /standings needs paid plan)

    func fetchStandings() async throws -> [Standing] {
        var allGames: [Game] = []
        var cursor: Int? = nil

        // Fetch regular season games page by page (cursor-based)
        repeat {
            var params: [(String, String)] = [
                ("seasons[]", "\(NBAConfig.currentSeason)"),
                ("postseason", "false"),
                ("per_page", "100")
            ]
            if let c = cursor { params.append(("cursor", "\(c)")) }

            let res: GamesResponse = try await request("/games", params: params, ttl: TTL.standings)
            let finished = res.data.filter { $0.isFinal }
            allGames.append(contentsOf: finished)
            cursor = res.meta.nextCursor

            // Small pause to respect rate limits between pages
            if cursor != nil { try await Task.sleep(nanoseconds: 200_000_000) }
        } while cursor != nil

        return computeStandings(from: allGames)
    }

    private func computeStandings(from games: [Game]) -> [Standing] {
        var records: [Int: Standing] = [:]

        for game in games {
            guard game.isFinal else { continue }
            let homeWon = game.homeTeamScore > game.visitorTeamScore

            // Home team
            var home = records[game.homeTeam.id] ?? Standing(team: game.homeTeam, wins: 0, losses: 0)
            home.wins   += homeWon ? 1 : 0
            home.losses += homeWon ? 0 : 1
            records[game.homeTeam.id] = home

            // Away team
            var away = records[game.visitorTeam.id] ?? Standing(team: game.visitorTeam, wins: 0, losses: 0)
            away.wins   += homeWon ? 0 : 1
            away.losses += homeWon ? 1 : 0
            records[game.visitorTeam.id] = away
        }

        var standings = Array(records.values).sorted { $0.winPct > $1.winPct }

        // Assign conference rank
        let conferences = ["East", "West"]
        for conf in conferences {
            let confStandings = standings.filter { $0.team.conference == conf }
                                         .sorted { $0.winPct > $1.winPct }
            for (rank, s) in confStandings.enumerated() {
                if let idx = standings.firstIndex(where: { $0.id == s.id }) {
                    standings[idx].conferenceRank = rank + 1
                }
            }
        }
        return standings
    }
}
