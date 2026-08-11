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

    nonisolated func logoURL() -> URL? { URL(string: "/api/logo", relativeTo: baseURL) }

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
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init() { loadSaved(); loadDiskCache(); load() }

    func load(_ query: String = "") {
        self.query = query
        if let cached = cache[query] { products = cached; updateRecommendations(); sourceLabel = "Local cache"; return }
        isLoading = true; error = nil
        Task {
            do {
                let response = try await CatalogClient.shared.search(query)
                products = response.products; cache[query] = response.products; persistProducts(response.products, for: query)
                sourceLabel = response.cache == "hit" ? "Server cache" : "Live shop"
                updateRecommendations(); isLoading = false
            } catch { self.error = "The live catalog is unavailable. Check that the CruiserParts LAN adapter is running."; isLoading = false }
        }
    }

    func toggleSaved(_ product: Product) {
        if let index = saved.firstIndex(of: product) { saved.remove(at: index) } else { saved.append(product) }
        persistSaved(); updateRecommendations()
    }

    func isSaved(_ product: Product) -> Bool { saved.contains(product) }

    private func diskURL(for query: String) -> URL {
        let safe = query.isEmpty ? "fresh" : query.lowercased().replacingOccurrences(of: "[^a-z0-9]+", with: "_", options: .regularExpression)
        let folder = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("CruiserPartsCatalog", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("\(safe).json")
    }

    private func loadDiskCache() {
        let folder = diskURL(for: "").deletingLastPathComponent()
        guard let files = try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil) else { return }
        for file in files where file.pathExtension == "json" {
            if let data = try? Data(contentsOf: file), let response = try? decoder.decode(SearchResponse.self, from: data) { cache[response.query] = response.products }
        }
    }

    private func persistProducts(_ products: [Product], for query: String) {
        let response = SearchResponse(source: "CruiserParts", query: query, products: products, cachedAt: Int(Date().timeIntervalSince1970), cache: "disk")
        if let data = try? encoder.encode(response) { try? data.write(to: diskURL(for: query), options: .atomic) }
    }

    private func loadSaved() {
        if let data = UserDefaults.standard.data(forKey: savedKey), let value = try? JSONDecoder().decode([Product].self, from: data) { saved = value }
    }
    private func persistSaved() { if let data = try? JSONEncoder().encode(saved) { UserDefaults.standard.set(data, forKey: savedKey) } }
    private func updateRecommendations() {
        let tokens = (saved.map { $0.name + " " + $0.description }.joined(separator: " ") + " " + query).lowercased().split { !$0.isLetter && !$0.isNumber }.filter { $0.count > 2 }
        recommendations = products.filter { !saved.contains($0) }.map { p in
            let text = (p.name + " " + p.description).lowercased(); let score = tokens.reduce(0) { $0 + (text.contains($1) ? 1 : 0) }
            return (p, score)
        }.sorted { $0.1 > $1.1 }.prefix(4).map { $0.0 }
        if recommendations.isEmpty { recommendations = Array(products.prefix(4)) }
    }
}
