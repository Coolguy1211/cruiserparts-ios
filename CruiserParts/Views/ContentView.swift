import SwiftUI

private let ink = Color.primary
private let accent = Color.blue

struct ContentView: View {
    @EnvironmentObject private var store: CatalogStore
    @State private var selectedTab = 0
    @State private var search = ""
    @State private var selectedSeries = "Fresh parts"
    private let chips = ["Fresh parts", "FJ80", "60 Series", "70 Series", "80 Series", "100 Series", "200 Series"]

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack { homePage }.tabItem { Label("Home", systemImage: "house.fill") }.tag(0)
            NavigationStack { modelsPage }.tabItem { Label("Models", systemImage: "car.fill") }.tag(1)
            NavigationStack { storePage }.tabItem { Label("Store", systemImage: "bag.fill") }.tag(2)
            NavigationStack { libraryPage }.tabItem { Label("Library", systemImage: "books.vertical.fill") }.tag(3)
            NavigationStack { searchPage }.tabItem { Label("Search", systemImage: "magnifyingglass") }.tag(4)
        }
        .tint(accent)
        .preferredColorScheme(.dark)
    }

    private var homePage: some View { ScrollView { VStack(alignment: .leading, spacing: 22) { hero; searchBar; chipBar; catalogSection; recommendationSection }.padding(.horizontal, 16).padding(.bottom, 28) }.navigationTitle("CruiserParts").navigationBarTitleDisplayMode(.large) }
    private var hero: some View { HStack(alignment: .bottom) { VStack(alignment: .leading, spacing: 7) { Text("TOYOTA LAND CRUISER PARTS").font(.caption2.bold()).tracking(1.4).foregroundStyle(.secondary); Text("Build it.\nExplore more.").font(.system(size: 43, weight: .heavy, design: .rounded)); Text("Live catalog browsing, saved builds, and fitment-friendly discovery.").font(.subheadline).foregroundStyle(.secondary) }; Spacer(); Image(systemName: "mountain.2.fill").font(.system(size: 35)).padding(18).glassEffect(.regular.interactive(), in: .rect(cornerRadius: 22)) } }
    private var searchBar: some View { HStack { Image(systemName: "magnifyingglass").foregroundStyle(.secondary); TextField("Search parts or SKU", text: $search).submitLabel(.search).onSubmit { selectedSeries = ""; store.load(search) }; Button("Search") { selectedSeries = ""; store.load(search) }.buttonStyle(.glassProminent) }.padding(10).glassEffect(.regular.interactive(), in: .rect(cornerRadius: 18)) }
    private var chipBar: some View { ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 10) { ForEach(chips, id: \.self) { chip in Button(chip) { selectedSeries = chip; search = chip == "Fresh parts" ? "" : chip; store.load(search) }.font(.caption.bold()).padding(.horizontal, 14).padding(.vertical, 10).foregroundStyle(selectedSeries == chip ? .primary : .secondary).glassEffect(.regular.tint(selectedSeries == chip ? .white.opacity(0.2) : .clear).interactive(), in: Capsule()) } } } }
    private var catalogSection: some View { VStack(alignment: .leading, spacing: 12) { HStack { Text(selectedSeries.isEmpty ? "Search results" : selectedSeries == "Fresh parts" ? "Fresh from the shop" : "Live \(selectedSeries)").font(.title2.bold()); Spacer(); Text("\(store.products.count) parts").font(.caption).foregroundStyle(.secondary) }; if store.isLoading { ProgressView().frame(maxWidth: .infinity, minHeight: 120) } else if let error = store.error { Text(error).font(.footnote).foregroundStyle(.secondary).padding() } else { GlassEffectContainer(spacing: 12) { LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) { ForEach(store.products) { ProductCard(product: $0).environmentObject(store) } } } }; Text("Source: CruiserParts shop · \(store.sourceLabel)").font(.caption2).foregroundStyle(.secondary) } }
    private var recommendationSection: some View { VStack(alignment: .leading, spacing: 12) { HStack { Text("Recommended for you").font(.title2.bold()); Spacer(); Text(store.saved.isEmpty ? "A starting point" : "Based on your library").font(.caption).foregroundStyle(.secondary) }; GlassEffectContainer(spacing: 12) { LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) { ForEach(store.recommendations) { ProductCard(product: $0, recommended: true).environmentObject(store) } } } } }

    private var modelsPage: some View { List { Section("Browse by model") { ForEach(chips.dropFirst(), id: \.self) { model in Button { selectedTab = 0; selectedSeries = model; search = model; store.load(model) } label: { Label(model, systemImage: "car.fill") } } }.listRowBackground(Color.clear); Section("Fitment") { Text("Choose a series to load live parts from CruiserParts. Each model search stays inside the app.").foregroundStyle(.secondary) } }.scrollContentBackground(.hidden).navigationTitle("Models") }
    private var storePage: some View { ScrollView { VStack(alignment: .leading, spacing: 18) { Text("Shop CruiserParts").font(.largeTitle.bold()); Text("Live parts, cached images, and a faster native browsing experience.").foregroundStyle(.secondary); StoreTile(title: "Fresh inventory", icon: "sparkles", text: "Browse the latest public catalog items."); StoreTile(title: "Fitment help", icon: "checkmark.seal.fill", text: "Save a part, then ask for help before ordering."); StoreTile(title: "Built for your garage", icon: "wrench.and.screwdriver.fill", text: "Keep a personal library of parts you’re comparing.") }.padding(16) }.navigationTitle("Store") }
    private var libraryPage: some View { List { if store.saved.isEmpty { ContentUnavailableView("Your Library is Empty", systemImage: "books.vertical", description: Text("Save parts from Home or Search to build your personal list.")) } else { ForEach(store.saved) { product in NavigationLink(value: product) { HStack { AsyncImage(url: CatalogClient.shared.imageURL(product.image)) { $0.resizable().scaledToFit() } .frame(width: 62, height: 52); VStack(alignment: .leading) { Text(product.name).lineLimit(2); Text(product.price).font(.caption).foregroundStyle(.secondary) } } } }.onDelete { offsets in offsets.map { store.saved[$0] }.forEach(store.toggleSaved) } } }.scrollContentBackground(.hidden).navigationTitle("Library").navigationDestination(for: Product.self) { ProductDetailView(product: $0) } }
    private var searchPage: some View { VStack(spacing: 18) { TextField("Search all CruiserParts", text: $search).textFieldStyle(.roundedBorder).font(.title3).padding(.horizontal).onSubmit { selectedSeries = ""; store.load(search) }; Button { selectedTab = 0; store.load(search) } label: { Label("Search live catalog", systemImage: "magnifyingglass").frame(maxWidth: .infinity) }.buttonStyle(.glassProminent).padding(.horizontal); Spacer() }.padding(.top, 24).navigationTitle("Search") }
}

private struct StoreTile: View { let title: String; let icon: String; let text: String; var body: some View { HStack(spacing: 16) { Image(systemName: icon).font(.title2).frame(width: 38, height: 38).glassEffect(.regular, in: .circle); VStack(alignment: .leading) { Text(title).font(.headline); Text(text).font(.subheadline).foregroundStyle(.secondary) }; Spacer() }.padding(16).glassEffect(.regular.interactive(), in: .rect(cornerRadius: 20)) } }

struct ProductCard: View {
    @EnvironmentObject private var store: CatalogStore
    let product: Product; var recommended = false
    var body: some View { NavigationLink(value: product) { VStack(alignment: .leading, spacing: 8) { AsyncImage(url: CatalogClient.shared.imageURL(product.image)) { phase in if let image = phase.image { image.resizable().scaledToFit() } else { Image(systemName: "shippingbox.fill").font(.largeTitle).foregroundStyle(.secondary) } }.frame(maxWidth: .infinity).frame(height: 115).glassEffect(.regular, in: .rect(cornerRadius: 14)); Text(recommended ? "RECOMMENDED" : "LIVE CATALOG").font(.caption2.bold()).foregroundStyle(.secondary); Text(product.name).font(.headline).lineLimit(2).multilineTextAlignment(.leading); Text(product.price.isEmpty ? "See current price" : product.price).font(.subheadline.bold()); Button(store.isSaved(product) ? "Saved" : "+ Save") { store.toggleSaved(product) }.font(.caption.bold()).buttonStyle(.glass).tint(store.isSaved(product) ? .blue : .primary) } }.buttonStyle(.plain).padding(12).glassEffect(.regular.interactive(), in: .rect(cornerRadius: 20)) }
}
