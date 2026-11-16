import SwiftUI

@main
struct HandheldHavenApp: App {
    @StateObject private var favorites: FavoritesStore
    @StateObject private var recents: RecentsStore
    @StateObject private var compare: CompareStore
    private let defaults: UserDefaults
    private let loaded: Result<HavenStore, Error>

    init() {
        let defaults = HandheldHavenApp.makeDefaults()
        self.defaults = defaults
        _favorites = StateObject(wrappedValue: FavoritesStore(defaults: defaults))
        _recents = StateObject(wrappedValue: RecentsStore(defaults: defaults))
        _compare = StateObject(wrappedValue: CompareStore(defaults: defaults))
        loaded = Result { try HavenStore.loadBundled() }
    }

    /// UI tests launch with -HandheldHavenUITesting so they start from an empty store.
    private static func makeDefaults() -> UserDefaults {
        guard ProcessInfo.processInfo.arguments.contains("-HandheldHavenUITesting"),
              let suite = UserDefaults(suiteName: "HandheldHavenUITesting") else { return .standard }
        suite.removePersistentDomain(forName: "HandheldHavenUITesting")
        return suite
    }

    var body: some Scene {
        WindowGroup {
            switch loaded {
            case .success(let store):
                RootView()
                    .environmentObject(store)
                    .environmentObject(favorites)
                    .environmentObject(recents)
                    .environmentObject(compare)
                    .defaultAppStorage(defaults)
            case .failure(let error):
                Text("Handheld Haven could not load its guide. \(error.localizedDescription)")
                    .padding()
            }
        }
    }
}

/// Applies text size, high contrast, and Reduce Motion for the whole app.
struct RootView: View {
    @AppStorage(TextSizeOption.storageKey) private var textSize: TextSizeOption = .system
    @AppStorage(HighContrastSetting.storageKey) private var highContrast = false
    @Environment(\.colorSchemeContrast) private var systemContrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let root = ContentView()
            .environment(\.havenHighContrast, highContrast || systemContrast == .increased)
            .transaction { transaction in
                if reduceMotion { transaction.disablesAnimations = true }
            }
        if let size = textSize.dynamicTypeSize {
            root.dynamicTypeSize(size)
        } else {
            root
        }
    }
}
