import XCTest
@testable import HandheldHaven

final class UserStateTests: XCTestCase {
    private var suiteName = ""
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "HavenTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func testFavoritesToggleAndPersist() {
        let favorites = FavoritesStore(defaults: defaults)
        favorites.toggle("dev:gpd-win-original")
        favorites.toggle("guide:history")
        XCTAssertTrue(favorites.contains("dev:gpd-win-original"))
        favorites.toggle("dev:gpd-win-original")
        XCTAssertFalse(favorites.contains("dev:gpd-win-original"))
        XCTAssertEqual(FavoritesStore(defaults: defaults).keys, ["guide:history"])
        favorites.removeAll()
        XCTAssertTrue(FavoritesStore(defaults: defaults).keys.isEmpty)
    }

    func testRecentsNewestFirstWithoutDuplicates() {
        let recents = RecentsStore(defaults: defaults)
        recents.record("dev:a")
        recents.record("dev:b")
        recents.record("dev:a")
        XCTAssertEqual(recents.keys, ["dev:a", "dev:b"])
        XCTAssertEqual(RecentsStore(defaults: defaults).keys, ["dev:a", "dev:b"])
    }

    func testRecentsAreCapped() {
        let recents = RecentsStore(defaults: defaults)
        for index in 0..<(RecentsStore.limit + 10) { recents.record("dev:\(index)") }
        XCTAssertEqual(recents.keys.count, RecentsStore.limit)
        XCTAssertEqual(recents.keys.first, "dev:\(RecentsStore.limit + 9)")
    }

    func testCompareHoldsTwoDevices() {
        let compare = CompareStore(defaults: defaults)
        XCTAssertTrue(compare.add("a"))
        XCTAssertFalse(compare.add("a"))
        XCTAssertTrue(compare.add("b"))
        XCTAssertTrue(compare.isFull)
        XCTAssertFalse(compare.add("c"))
        XCTAssertEqual(compare.ids, ["a", "b"])
        compare.remove("b")
        XCTAssertEqual(CompareStore(defaults: defaults).ids, ["a"])
        compare.removeAll()
        XCTAssertTrue(compare.ids.isEmpty)
    }

    func testTextSizeOptions() {
        XCTAssertNil(TextSizeOption.system.dynamicTypeSize)
        XCTAssertEqual(TextSizeOption.accessibility5.dynamicTypeSize, .accessibility5)
        XCTAssertEqual(TextSizeOption.allCases.count, 13)
        XCTAssertEqual(TextSizeOption.large.title, "Large (system default)")
    }
}
