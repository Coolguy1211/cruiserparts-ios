import Foundation

actor CatalogClient {
    static let shared = CatalogClient()
    private let baseURL = URL(string: "http://192.168.0.172:8787")!
    private let decoder = JSONDecoder()

    func search(_ query: String) async throws -> SearchResponse {
        var components = URLComponents(url: baseURL.appendingPathComponent("api/search"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "q", value: query)]
        var request = URLRequest(url: components.url!)
        request.cachePolicy = .reloadRevalidatingCacheData
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else { throw URLError(.badServerResponse) }
        return try decoder.decode(SearchResponse.self, from: data)
    }

    nonisolated func imageURL(_ path: String) -> URL? {
        if path.hasPrefix("http") { return URL(string: path) }
        return URL(string: path, relativeTo: baseURL)
    }
}

@MainActor
final class CatalogStore: ObservableObject {
    @Published var products: [Product] = []
    @Published var recommendations: [Product] = []
    @Published var saved: [Product] = []
    @Published var query = ""
    @Published var isLoading = false
    @Published var error: String?
    @Published var sourceLabel = ""

    private var cache: [String: [Product]] = [:]
    private let savedKey = "cruiserparts.saved.v1"

    init() { loadSaved(); load() }

    func load(_ query: String = "") {
        self.query = query
        if let cached = cache[query] { products = cached; updateRecommendations(); sourceLabel = "Browser cache"; return }
        isLoading = true; error = nil
        Task {
            do {
                let response = try await CatalogClient.shared.search(query)
                products = response.products; cache[query] = response.products
                sourceLabel = response.cache == "hit" ? "Server cache" : "Live shop"
                updateRecommendations(); isLoading = false
            } catch { error = "The live catalog is unavailable. Check that the CruiserParts LAN adapter is running."; isLoading = false }
        }
    }

    func toggleSaved(_ product: Product) {
        if let index = saved.firstIndex(of: product) { saved.remove(at: index) } else { saved.append(product) }
        persistSaved(); updateRecommendations()
    }

    func isSaved(_ product: Product) -> Bool { saved.contains(product) }

    private func loadSaved() {
        if let data = UserDefaults.standard.data(forKey: savedKey), let value = try? JSONDecoder().decode([Product].self, from: data) { saved = value }
    }
    private func persistSaved() { if let data = try? JSONEncoder().encode(saved) { UserDefaults.standard.set(data, forKey: savedKey) } }
    private func updateRecommendations() {
        let tokens = (saved.map { $0.name + " " + $0.description }.joined(separator: " ") + " " + query).lowercased().split { !$0.isLetter && !$0.isNumber }.filter { $0.count > 2 }
        recommendations = products.filter { !saved.contains($0) }.map { p in
            let text = (p.name + " " + p.description).lowercased(); let score = tokens.reduce(0) { $0 + (text.contains($1) ? 1 : 0) }
            return (p, score)
        }.sorted { $0.1 > $1.1 }.prefix(4).map(\.0)
        if recommendations.isEmpty { recommendations = Array(products.prefix(4)) }
    }
}
