import Foundation

struct Product: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let price: String
    let image: String
    let sourceImage: String?
    let url: String?

    enum CodingKeys: String, CodingKey { case id, name, description, price, image, sourceImage = "source_image", url }
}

struct SearchResponse: Codable {
    let source: String
    let query: String
    let products: [Product]
    let cachedAt: Int?
    let cache: String?
    enum CodingKeys: String, CodingKey { case source, query, products, cachedAt = "cached_at", cache }
}
