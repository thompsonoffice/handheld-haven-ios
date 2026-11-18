import SwiftUI

enum AppTab: String, Hashable {
    case browse, search, favorites, compare, more
}

struct ContentView: View {
    @SceneStorage("haven.selectedTab") private var tab: AppTab = .browse
    @EnvironmentObject private var compare: CompareStore

    var body: some View {
        TabView(selection: $tab) {
            BrowseView()
                .tabItem { Label("Browse", systemImage: "books.vertical") }
                .tag(AppTab.browse)
            SearchView()
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
                .tag(AppTab.search)
            FavoritesView()
                .tabItem { Label("Favorites", systemImage: "star") }
                .tag(AppTab.favorites)
            CompareView()
                .tabItem { Label("Compare", systemImage: "rectangle.split.2x1") }
                .tag(AppTab.compare)
                .modifier(CountBadge(count: compare.ids.count))
            MoreView()
                .tabItem { Label("More", systemImage: "ellipsis.circle") }
                .tag(AppTab.more)
        }
    }
}

/// A tab badge only when there is something to announce. A zero badge is an empty
/// low-contrast element in the accessibility audit.
struct CountBadge: ViewModifier {
    let count: Int
    func body(content: Content) -> some View {
        if count > 0 {
            content.badge(count)
        } else {
            content
        }
    }
}

struct MoreView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink(value: Route.settings) {
                        Text("Settings").font(.body).foregroundStyle(Color(.label))
                    }
                    NavigationLink(value: Route.recents) {
                        Text("Recently Viewed").font(.body).foregroundStyle(Color(.label)).fixedSize(horizontal: false, vertical: true)
                    }
                    NavigationLink(value: Route.glossary) {
                        Text("Glossary").font(.body).foregroundStyle(Color(.label))
                    }
                    NavigationLink(value: Route.sources) {
                        Text("Sources").font(.body).foregroundStyle(Color(.label))
                    }
                } header: {
                    SectionHeader("In this guide")
                }
                Section {
                    NavigationLink(value: Route.about) {
                        Text("About Handheld Haven").font(.body).foregroundStyle(Color(.label)).fixedSize(horizontal: false, vertical: true)
                    }
                    NavigationLink(value: Route.privacy) {
                        Text("Privacy Policy").font(.body).foregroundStyle(Color(.label)).fixedSize(horizontal: false, vertical: true)
                    }
                } header: {
                    SectionHeader("About")
                }
            }
            .havenScreenTitle("More")
            .havenListChrome()
            .havenDestinations()
        }
    }
}
