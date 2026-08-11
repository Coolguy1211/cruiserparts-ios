import SwiftUI

private let ink = Color(red: 0.145, green: 0.165, blue: 0.153)
private let olive = Color(red: 0.41, green: 0.47, blue: 0.025)
private let orange = Color(red: 0.78, green: 0.294, blue: 0.149)
private let cream = Color(red: 0.96, green: 0.953, blue: 0.918)

struct ContentView: View {
    @EnvironmentObject private var store: CatalogStore
    @State private var search = ""
    @State private var selectedSeries = "Fresh parts"
    private let chips = ["Fresh parts", "FJ80", "60 Series", "70 Series", "80 Series", "100 Series"]

    var body: some View {
        NavigationStack {
            ZStack { cream.ignoresSafeArea(); ScrollView { VStack(alignment: .leading, spacing: 18) {
                header; searchBar; chipBar; catalogSection; recommendationSection
            }.padding(.horizontal, 16).padding(.bottom, 28) } }
            .navigationDestination(for: Product.self) { ProductDetailView(product: $0) }
            .toolbar(.hidden, for: .navigationBar)
        }
        .tint(olive)
    }

    private var header: some View { HStack { VStack(alignment: .leading, spacing: 5) { Text("TOYOTA LAND CRUISER PARTS").font(.caption2.bold()).tracking(1.4).foregroundStyle(orange); Text("Build it.\nExplore more.").font(.system(size: 42, weight: .heavy, design: .rounded)).foregroundStyle(ink); Text("Live catalog results, saved builds, and fitment-friendly browsing.").font(.subheadline).foregroundStyle(.secondary) }; Spacer(); Image(systemName: "mountain.2.fill").font(.system(size: 42)).foregroundStyle(olive).padding(16).background(ink, in: RoundedRectangle(cornerRadius: 18)).glassEffect(.regular.tint(olive).interactive(), in: .rect(cornerRadius: 18)) } }
    private var searchBar: some View { HStack { Image(systemName: "magnifyingglass").foregroundStyle(.secondary); TextField("Search live parts, SKU, or keyword…", text: $search).submitLabel(.search).onSubmit { selectedSeries = ""; store.load(search) }; Button("Search") { selectedSeries = ""; store.load(search) }.buttonStyle(.borderedProminent).tint(orange) }.padding(8).glassEffect(.regular.tint(.white.opacity(0.72)), in: .rect(cornerRadius: 14)) }
    private var chipBar: some View { ScrollView(.horizontal, showsIndicators: false) { HStack { ForEach(chips, id: \.self) { chip in Button(chip) { selectedSeries = chip; search = chip == "Fresh parts" ? "" : chip; store.load(search) }.font(.caption.bold()).padding(.horizontal, 14).padding(.vertical, 10).foregroundStyle(selectedSeries == chip ? .white : ink).glassEffect(.regular.tint(selectedSeries == chip ? olive : .white).interactive(), in: Capsule()) } } } }
    private var catalogSection: some View { VStack(alignment: .leading, spacing: 10) { HStack { Text(selectedSeries.isEmpty ? "Search results" : selectedSeries == "Fresh parts" ? "Fresh from the shop" : "Live \(selectedSeries)").font(.title2.bold()).foregroundStyle(ink); Spacer(); Text("\(store.products.count) parts").font(.caption).foregroundStyle(.secondary) }; if store.isLoading { ProgressView().frame(maxWidth: .infinity, minHeight: 120) } else if let error = store.error { Text(error).font(.footnote).foregroundStyle(.secondary).padding() } else { LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) { ForEach(store.products) { ProductCard(product: $0).environmentObject(store) } } }; Text("Source: CruiserParts shop · \(store.sourceLabel)").font(.caption2).foregroundStyle(.secondary) } }
    private var recommendationSection: some View { VStack(alignment: .leading, spacing: 10) { HStack { Text("Recommended for you").font(.title2.bold()).foregroundStyle(ink); Spacer(); Text(store.saved.isEmpty ? "A starting point" : "Based on your saved parts").font(.caption).foregroundStyle(.secondary) }; LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) { ForEach(store.recommendations) { ProductCard(product: $0, recommended: true).environmentObject(store) } } } }
}

struct ProductCard: View {
    @EnvironmentObject private var store: CatalogStore
    let product: Product; var recommended = false
    var body: some View { NavigationLink(value: product) { VStack(alignment: .leading, spacing: 8) { AsyncImage(url: CatalogClient.shared.imageURL(product.image)) { phase in if let image = phase.image { image.resizable().scaledToFit() } else { Image(systemName: "shippingbox.fill").font(.largeTitle).foregroundStyle(olive.opacity(0.5)) } }.frame(maxWidth: .infinity).frame(height: 115).glassEffect(.regular.tint(.white.opacity(0.55)), in: .rect(cornerRadius: 12)); Text(recommended ? "RECOMMENDED" : "LIVE CATALOG").font(.caption2.bold()).foregroundStyle(olive); Text(product.name).font(.headline).foregroundStyle(ink).lineLimit(2).multilineTextAlignment(.leading); Text(product.price.isEmpty ? "See current price" : product.price).font(.subheadline.bold()).foregroundStyle(ink); Button(store.isSaved(product) ? "Saved" : "+ Save") { store.toggleSaved(product) }.font(.caption.bold()).buttonStyle(.bordered).tint(store.isSaved(product) ? olive : orange) } }.buttonStyle(.plain).padding(10).glassEffect(.regular.tint(.white.opacity(0.48)).interactive(), in: .rect(cornerRadius: 15)).overlay(RoundedRectangle(cornerRadius: 15).stroke(recommended ? olive.opacity(0.35) : Color.white.opacity(0.38))) }
}
