import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject private var favorites: FavoritesStore

    var body: some View {
        NavigationStack {
            List {
                if favorites.keys.isEmpty {
                    Section {
                        Text("No favorites yet. Use the Favorite button on a device, guide, or glossary term.")
                            .font(.body)
                    } header: {
                        SectionHeader("Favorites")
                    }
                } else {
                    Section {
                        ForEach(favorites.keys, id: \.self) { key in
                            SavedItemRow(key: key)
                                .swipeActions {
                                    Button(role: .destructive) { favorites.remove(key) } label: {
                                        Label("Remove", systemImage: "star.slash")
                                    }
                                }
                                .accessibilityAction(named: "Remove Favorite") { favorites.remove(key) }
                        }
                    } header: {
                        SectionHeader("\(favorites.keys.count) \(favorites.keys.count == 1 ? "favorite" : "favorites")")
                    }
                }
            }
            .havenScreenTitle("Favorites")
            .havenListChrome()
            .havenDestinations()
        }
    }
}
