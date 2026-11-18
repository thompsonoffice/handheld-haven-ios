import Combine
import Foundation

/// Favorites saved in UserDefaults on this device only.
final class FavoritesStore: ObservableObject {
    static let storageKey = "haven.favorites"
    @Published private(set) var keys: [String]
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        keys = defaults.stringArray(forKey: FavoritesStore.storageKey) ?? []
    }

    func contains(_ key: String) -> Bool { keys.contains(key) }

    func toggle(_ key: String) {
        if let index = keys.firstIndex(of: key) { keys.remove(at: index) } else { keys.append(key) }
        save()
    }

    func remove(_ key: String) {
        keys.removeAll { $0 == key }
        save()
    }

    func removeAll() {
        keys = []
        save()
    }

    private func save() { defaults.set(keys, forKey: FavoritesStore.storageKey) }
}

/// Recently viewed entries, newest first, saved on this device only.
final class RecentsStore: ObservableObject {
    static let storageKey = "haven.recents"
    static let limit = 25
    @Published private(set) var keys: [String]
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        keys = defaults.stringArray(forKey: RecentsStore.storageKey) ?? []
    }

    func record(_ key: String) {
        if keys.first == key { return }
        keys.removeAll { $0 == key }
        keys.insert(key, at: 0)
        if keys.count > RecentsStore.limit { keys.removeLast(keys.count - RecentsStore.limit) }
        save()
    }

    func remove(_ key: String) {
        keys.removeAll { $0 == key }
        save()
    }

    func removeAll() {
        keys = []
        save()
    }

    private func save() { defaults.set(keys, forKey: RecentsStore.storageKey) }
}

/// Two devices picked for side-by-side comparison, saved on this device only.
final class CompareStore: ObservableObject {
    static let storageKey = "haven.compare"
    static let capacity = 2
    @Published private(set) var ids: [String]
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        ids = Array((defaults.stringArray(forKey: CompareStore.storageKey) ?? []).prefix(CompareStore.capacity))
    }

    var isFull: Bool { ids.count >= CompareStore.capacity }
    func contains(_ id: String) -> Bool { ids.contains(id) }

    @discardableResult
    func add(_ id: String) -> Bool {
        guard !contains(id), !isFull else { return false }
        ids.append(id)
        save()
        return true
    }

    func remove(_ id: String) {
        ids.removeAll { $0 == id }
        save()
    }

    func removeAll() {
        ids = []
        save()
    }

    private func save() { defaults.set(ids, forKey: CompareStore.storageKey) }
}
