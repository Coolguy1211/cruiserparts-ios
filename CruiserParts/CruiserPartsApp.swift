import SwiftUI

@main
struct CruiserPartsApp: App {
    @StateObject private var store = CatalogStore()
    var body: some Scene { WindowGroup { ContentView().environmentObject(store) } }
}
