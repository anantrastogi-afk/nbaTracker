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
        case .decodingError:       return "Unexpected data from server"
        case .rateLimited:         return "Too many requests — please wait a moment and try again"
        case .serverError(let c):  return "Server error (\(c))"
        }
    }
}

// MARK: - Simple in-memory cache

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
        guard let entry = store[key], entry.isValid else { store.removeValue(forKey: key); return nil }
        return entry.data
    }

    func set(_ key: String, data: Data, ttl: TimeInterval) {
        lock.lock(); defer { lock.unlock() }
        store[key] = CacheEntry(data: data, expiry: Date().addingTimeInterval(ttl))
    }

    func invalidate(_ prefix: String) {
        lock.lock(); defer { lock.unlock() }
        store = store.filter { !$0.key.hasPrefix(prefix) }
    }
}

// MARK: - TTL constants (seconds)

private enum TTL {
    static let teams:    TimeInterval = 3600   // 1 hour  — rarely changes
    static let players:  TimeInterval = 1800   // 30 min
    static let games:    TimeInterval = 60     // 1 min   — scores update live
    static let standings: TimeInterval = 300   // 5 min
    static let averages: TimeInterval = 1800   // 30 min
}

// MARK: - Service

final class NBAService {
    static let shared = NBAService()
    private init() {
        // Configure URLSession cache to back the in-memory layer
        let config = URLSessionConfiguration.default
        config.urlCache = URLCache(memoryCapacity: 10_000_000, diskCapacity: 50_000_000)
        session = URLSession(configuration: config)
    }

    private var session: URLSession!

    // MARK: Core request with cache + retry

    private func request<T: Decodable>(
        _ path: String,
        params: [String: String] = [:],
        ttl: TimeInterval,
        retries: Int = 3
    ) async throws -> T {
        var components = URLComponents(string: "\(NBAConfig.baseURL)\(path)")!
        components.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        guard let url = components.url else { throw NBAError.invalidURL }

        let cacheKey = url.absoluteString

        // Return cached data if still valid
        if let cached = ResponseCache.shared.get(cacheKey) {
            return try decode(cached)
        }

        var lastError: Error = NBAError.serverError(0)

        for attempt in 0..<retries {
            if attempt > 0 {
                // Exponential backoff: 2s, 4s
                let delay = UInt64(pow(2.0, Double(attempt))) * 1_000_000_000
                try await Task.sleep(nanoseconds: delay)
            }

            var req = URLRequest(url: url)
            req.setValue(NBAConfig.apiKey, forHTTPHeaderField: "Authorization")
            req.timeoutInterval = 15

            let data: Data
            let response: URLResponse
            do {
                (data, response) = try await session.data(for: req)
            } catch {
                lastError = NBAError.networkError(error)
                continue
            }

            guard let http = response as? HTTPURLResponse else {
                lastError = NBAError.serverError(0); continue
            }

            if http.statusCode == 429 {
                // Rate limited — always retry with longer wait
                let wait = UInt64(5 * (attempt + 1)) * 1_000_000_000
                try await Task.sleep(nanoseconds: wait)
                lastError = NBAError.rateLimited
                continue
            }

            guard (200...299).contains(http.statusCode) else {
                throw NBAError.serverError(http.statusCode)
            }

            // Store in cache before decoding
            ResponseCache.shared.set(cacheKey, data: data, ttl: ttl)
            return try decode(data)
        }

        throw lastError
    }

    private func decode<T: Decodable>(_ data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw NBAError.decodingError(error)
        }
    }

    // MARK: Teams

    func fetchTeams() async throws -> [Team] {
        let res: TeamsResponse = try await request("/teams", params: ["per_page": "30"], ttl: TTL.teams)
        return res.data.sorted { $0.fullName < $1.fullName }
    }

    // MARK: Players

    func fetchPlayers(teamId: Int, page: Int = 1) async throws -> PlayersResponse {
        return try await request("/players", params: [
            "team_ids[]": "\(teamId)",
            "per_page": "50",
            "page": "\(page)"
        ], ttl: TTL.players)
    }

    func searchPlayers(query: String) async throws -> [Player] {
        let res: PlayersResponse = try await request("/players", params: [
            "search": query,
            "per_page": "25"
        ], ttl: TTL.players)
        return res.data
    }

    // MARK: Games

    func fetchTodaysGames() async throws -> [Game] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        let res: GamesResponse = try await request("/games", params: [
            "dates[]": today,
            "per_page": "15"
        ], ttl: TTL.games)
        return res.data
    }

    func fetchRecentGames(teamId: Int) async throws -> [Game] {
        let res: GamesResponse = try await request("/games", params: [
            "team_ids[]": "\(teamId)",
            "seasons[]": "\(NBAConfig.currentSeason)",
            "per_page": "10",
            "page": "1"
        ], ttl: TTL.games)
        return res.data.sorted { $0.date > $1.date }
    }

    func fetchPlayoffGames() async throws -> [Game] {
        let res: GamesResponse = try await request("/games", params: [
            "postseason": "true",
            "seasons[]": "\(NBAConfig.currentSeason)",
            "per_page": "100"
        ], ttl: TTL.games)
        return res.data.sorted { $0.date < $1.date }
    }

    // MARK: Standings

    func fetchStandings() async throws -> [Standing] {
        let res: StandingsResponse = try await request("/standings", params: [
            "season": "\(NBAConfig.currentSeason)"
        ], ttl: TTL.standings)
        return res.data
    }

    // MARK: Season Averages

    func fetchSeasonAverages(playerIds: [Int]) async throws -> [SeasonAverage] {
        let res: SeasonAveragesResponse = try await request("/season_averages", params: [
            "season": "\(NBAConfig.currentSeason)",
            "player_ids[]": playerIds.map(String.init).joined(separator: ",")
        ], ttl: TTL.averages)
        return res.data
    }
}
