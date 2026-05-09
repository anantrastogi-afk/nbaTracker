import Foundation

enum NBAError: Error, LocalizedError {
    case badData(String)
    case network(Error)
    case rateLimited

    var errorDescription: String? {
        switch self {
        case .badData(let m): return m
        case .network(let e): return e.localizedDescription
        case .rateLimited:    return "Too many requests — please wait and try again"
        }
    }
}

// MARK: - Cache

private struct CacheEntry { let data: Data; let expiry: Date; var valid: Bool { Date() < expiry } }

private final class Cache {
    static let shared = Cache()
    private var store: [String: CacheEntry] = [:]
    private let lock = NSLock()
    func get(_ k: String) -> Data? { lock.lock(); defer { lock.unlock() }; guard let e = store[k], e.valid else { store.removeValue(forKey: k); return nil }; return e.data }
    func set(_ k: String, data: Data, ttl: TimeInterval) { lock.lock(); defer { lock.unlock() }; store[k] = CacheEntry(data: data, expiry: Date().addingTimeInterval(ttl)) }
}

// MARK: - Service

final class NBAService {
    static let shared = NBAService()
    private let session = URLSession.shared
    private init() {}

    // MARK: Raw fetch with cache + 429 retry

    private func fetch(_ url: URL, ttl: TimeInterval) async throws -> [String: Any] {
        let key = url.absoluteString
        if let cached = Cache.shared.get(key),
           let json = try? JSONSerialization.jsonObject(with: cached) as? [String: Any] {
            return json
        }

        for attempt in 0..<3 {
            if attempt > 0 { try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attempt))) * 1_000_000_000) }
            let (data, response) = try await session.data(from: url)
            if let http = response as? HTTPURLResponse {
                if http.statusCode == 429 {
                    try await Task.sleep(nanoseconds: UInt64(5 * (attempt + 1)) * 1_000_000_000)
                    continue
                }
            }
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw NBAError.badData("Could not parse response from \(url.lastPathComponent)")
            }
            Cache.shared.set(key, data: data, ttl: ttl)
            return json
        }
        throw NBAError.rateLimited
    }

    // MARK: - Teams

    func fetchTeams() async throws -> [Team] {
        let url  = ESPN.url("/teams", params: ["limit": "30"])
        let json = try await fetch(url, ttl: 3600)
        let sports  = json["sports"]  as? [[String: Any]] ?? []
        let leagues = sports.first?["leagues"] as? [[String: Any]] ?? []
        let teams   = leagues.first?["teams"]  as? [[String: Any]] ?? []
        return teams.compactMap { Team.from($0["team"] as? [String: Any] ?? [:]) }
                    .sorted { $0.displayName < $1.displayName }
    }

    // MARK: - Scoreboard

    func fetchScoreboard() async throws -> [Game] {
        let url  = ESPN.url("/scoreboard")
        let json = try await fetch(url, ttl: 30)   // 30s — live scores
        let events = json["events"] as? [[String: Any]] ?? []
        return events.compactMap { Game.from($0) }
    }

    // MARK: - Standings

    func fetchStandings() async throws -> [Standing] {
        let url  = ESPN.url("/standings", base: ESPN.coreBase)
        let json = try await fetch(url, ttl: 300)
        let confs = json["children"] as? [[String: Any]] ?? []
        var result: [Standing] = []
        for conf in confs {
            let confName = conf["name"] as? String ?? ""
            let entries  = (conf["standings"] as? [String: Any])?["entries"] as? [[String: Any]] ?? []
            result += entries.compactMap { Standing.from(entry: $0, conference: confName) }
        }
        return result
    }

    // MARK: - Roster

    func fetchRoster(teamId: String) async throws -> [Player] {
        let url  = ESPN.url("/teams/\(teamId)/roster")
        let json = try await fetch(url, ttl: 1800)
        let athletes = json["athletes"] as? [[String: Any]] ?? []
        return athletes.compactMap { Player.from($0) }
    }

    // MARK: - Injuries

    func fetchInjuries() async throws -> [Injury] {
        let url  = ESPN.url("/injuries")
        let json = try await fetch(url, ttl: 300)
        let groups = json["injuries"] as? [[String: Any]] ?? []
        return groups.flatMap { Injury.from(teamGroup: $0) }
    }

    func fetchInjuries(teamAbbr: String) async throws -> [Injury] {
        let all = try await fetchInjuries()
        return all.filter { $0.teamName.localizedCaseInsensitiveContains(teamAbbr) }
    }

    // MARK: - News

    func fetchNews(limit: Int = 10) async throws -> [Article] {
        let url  = ESPN.url("/news", params: ["limit": "\(limit)"])
        let json = try await fetch(url, ttl: 120)
        let articles = json["articles"] as? [[String: Any]] ?? []
        return articles.compactMap { Article.from($0) }
    }

    func fetchTeamNews(teamId: String, limit: Int = 5) async throws -> [Article] {
        let url  = ESPN.url("/teams/\(teamId)/news", params: ["limit": "\(limit)"])
        let json = try await fetch(url, ttl: 120)
        let articles = json["articles"] as? [[String: Any]] ?? []
        return articles.compactMap { Article.from($0) }
    }

    // MARK: - Playoff games (postseason filter from scoreboard history)

    func fetchPlayoffGames() async throws -> [Game] {
        // ESPN scoreboard shows today's games; fetch with playoff date range
        let all = try await fetchScoreboard()
        // Also fetch a broader window using specific dates around playoff period
        return all.filter { $0.isPostseason }
    }
}
