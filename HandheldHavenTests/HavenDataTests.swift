import XCTest
@testable import HandheldHaven

/// The bundled guide matches the plain text: same devices, same lines, no added specs.
final class HavenDataTests: XCTestCase {
    private static let shared: HavenStore = {
        let bundle = Bundle(for: FavoritesStore.self)
        return try! HavenStore.loadBundled(bundle: bundle)
    }()
    private var store: HavenStore { Self.shared }

    private var contentRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("content/Handheld-Haven")
    }

    func testCountsMatchTheBook() {
        XCTAssertEqual(store.devices.count, 75)
        XCTAssertEqual(store.data.deviceCount, 75)
        XCTAssertEqual(store.chapters.count, 11)
        XCTAssertEqual(store.guides.count, 5)
        XCTAssertEqual(store.glossary.count, 34)
        XCTAssertEqual(store.data.sourceGroups.reduce(0) { $0 + $1.urls.count }, 121)
        XCTAssertEqual(store.chapters.map(\.deviceIDs).flatMap { $0 }.count, 75)
    }

    func testIDsAreUnique() {
        XCTAssertEqual(Set(store.devices.map(\.id)).count, store.devices.count)
        XCTAssertEqual(Set(store.chapters.map(\.id)).count, store.chapters.count)
        XCTAssertEqual(Set(store.glossary.map(\.id)).count, store.glossary.count)
        XCTAssertEqual(Set(store.guides.map(\.id)).count, store.guides.count)
    }

    func testEveryDeviceLineIsInItsOwnEntry() throws {
        for device in store.devices {
            let file = try String(contentsOf: contentRoot.appendingPathComponent(device.fileName), encoding: .utf8)
            let block = try entryBlock(named: device.name, in: file)
            XCTAssertTrue(block.contains("Maker: \(device.maker)"), device.name)
            XCTAssertTrue(block.contains("Released: \(device.released)"), device.name)
            XCTAssertTrue(block.contains("Launch price: \(device.launchPrice)"), device.name)
            if !device.alsoKnownAs.isEmpty {
                XCTAssertTrue(block.contains("Also known as: \(device.alsoKnownAs)"), device.name)
            }
            for field in [device.overview, device.controls, device.howItFeels, device.blindUsability, device.gameCompatibility, device.uncertain] {
                for line in field.split(separator: "\n") {
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    if trimmed.isEmpty { continue }
                    XCTAssertTrue(block.contains(trimmed), "\(device.name): \(trimmed.prefix(80))")
                }
            }
            XCTAssertEqual(device.hardware.count, 13, device.name)
            for fact in device.hardware {
                XCTAssertTrue(block.contains("\(fact.label): \(fact.value)"), "\(device.name) \(fact.label)")
            }
            for url in device.sources {
                XCTAssertTrue(block.contains(url), url)
                XCTAssertTrue(url.hasPrefix("https://"), url)
            }
            XCTAssertEqual(device.thin, block.contains("THIN ENTRY"), device.name)
        }
    }

    func testGuidesAndGlossaryAreCopied() throws {
        for guide in store.guides {
            let file = try String(contentsOf: contentRoot.appendingPathComponent(guide.fileName), encoding: .utf8)
            XCTAssertTrue(file.contains(guide.title), guide.id)
            for section in guide.sections {
                XCTAssertTrue(file.contains(section.heading), section.heading)
                for line in section.body.split(separator: "\n") {
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    if trimmed.isEmpty { continue }
                    XCTAssertTrue(file.contains(trimmed), "\(guide.id): \(trimmed.prefix(80))")
                }
            }
        }
        let glossary = try String(contentsOf: contentRoot.appendingPathComponent("05-glossary.txt"), encoding: .utf8)
        for term in store.glossary {
            XCTAssertTrue(glossary.contains("\(term.term): \(term.definition)"), term.term)
        }
        let narrator = try XCTUnwrap(store.glossary.first { $0.term == "NARRATOR" })
        XCTAssertTrue(narrator.definition.hasPrefix("The screen reader built into Windows."))
        let alias = try XCTUnwrap(store.glossary.first { $0.term == "FULL SCREEN EXPERIENCE" })
        XCTAssertEqual(store.term(alias.seeAlso)?.term, "XBOX MODE")
    }

    func testKnownEntryWasNotRewritten() throws {
        let win = try XCTUnwrap(store.device(named: "GPD Win (original)"))
        XCTAssertEqual(win.alsoKnownAs, "GPD Win 1")
        XCTAssertEqual(win.maker, "GamePad Digital (GPD), Shenzhen, China")
        let processor = try XCTUnwrap(win.hardware.first { $0.label == "Processor" })
        XCTAssertTrue(processor.value.hasPrefix("Intel Atom x7-Z8700"))
        XCTAssertEqual(store.devices(in: try XCTUnwrap(store.chapter("gpd-win-series"))).count, 8)
        XCTAssertNil(store.device(named: "Handheld Haven Phantom"))
    }

    func testSearchRequiresEveryWordAndIgnoresCase() throws {
        let kennan = store.search("Project Kennan")
        XCTAssertEqual(kennan.first, .device("rog-xbox-ally"))
        XCTAssertEqual(store.search("project kennan").map(\.id), kennan.map(\.id))
        XCTAssertTrue(store.search("zzzz-not-a-device qqqq").isEmpty)
        let both = store.search("Atom Z8700", scope: .devices)
        XCTAssertFalse(both.isEmpty)
        XCTAssertTrue(both.allSatisfy { hit in
            guard case .device(let id) = hit, let device = store.device(id) else { return false }
            let hay = HavenStore.fold(HavenStore.plainText(for: device))
            return hay.contains("atom") && hay.contains("z8700")
        })
        let narrator = store.search("Narrator", scope: .glossary)
        XCTAssertTrue(narrator.contains(.term("narrator")))
    }

    func testComparisonUsesOnlyEntryLines() throws {
        let win = try XCTUnwrap(store.device(named: "GPD Win (original)"))
        let win2 = try XCTUnwrap(store.device(named: "GPD Win 2"))
        let rows = store.comparisonRows(for: [win, win2])
        XCTAssertEqual(rows.map(\.values.count), Array(repeating: 2, count: rows.count))
        XCTAssertEqual(Set(rows.map(\.label)).count, rows.count)
        let processor = try XCTUnwrap(rows.first { $0.label == "Processor" })
        XCTAssertEqual(processor.values[0], win.hardware.first { $0.label == "Processor" }?.value)
        XCTAssertEqual(processor.values[1], win2.hardware.first { $0.label == "Processor" }?.value)
        XCTAssertNotEqual(processor.values[0], processor.values[1])
        let also = try XCTUnwrap(rows.first { $0.label == "Also known as" })
        XCTAssertEqual(also.values[0], "GPD Win 1")
        XCTAssertEqual(also.values[1], notStatedInEntry)
        XCTAssertTrue(win2.alsoKnownAs.isEmpty)
        let exported = HavenStore.plainText(for: win)
        XCTAssertTrue(exported.contains("ENTRY: GPD Win (original)"))
        XCTAssertTrue(exported.contains("Processor: \(processor.values[0])"))
        XCTAssertTrue(exported.contains("BLIND USABILITY"))
    }

    func testFileNamesAndSavedKeys() {
        XCTAssertEqual(HavenStore.fileName("GPD Win (original)"), "GPD Win (original).txt")
        XCTAssertEqual(HavenStore.fileName("A/B: C?"), "A-B- C-.txt")
        XCTAssertEqual(HavenStore.fileName(""), "Handheld Haven.txt")
        XCTAssertEqual(FavoriteKey.parse("dev:gpd-win-original")?.id, "gpd-win-original")
        XCTAssertEqual(FavoriteKey.parse("guide:history")?.kind == .guide, true)
        XCTAssertNil(FavoriteKey.parse("bogus"))
        XCTAssertEqual(store.title(forKey: "dev:gpd-win-original"), "GPD Win (original)")
        XCTAssertNil(store.title(forKey: "dev:does-not-exist"))
    }

    func testAboutAndPrivacyDoNotCollectData() throws {
        XCTAssertTrue(AboutCopy.affiliation.contains("not affiliated"))
        XCTAssertTrue(AboutCopy.noCommerce.contains("no store links"))
        let policy = PrivacyPolicy.paragraphs.map { $0.heading + $0.body }.joined()
        XCTAssertTrue(policy.contains("does not collect"))
        XCTAssertFalse(policy.contains("["))
        let manifest = try String(contentsOf: repoFile("HandheldHaven/PrivacyInfo.xcprivacy"), encoding: .utf8)
        XCTAssertTrue(manifest.contains("<key>NSPrivacyTracking</key>"))
        XCTAssertTrue(manifest.contains("<key>NSPrivacyCollectedDataTypes</key>\n\t<array/>"))
        XCTAssertFalse(manifest.contains("NSPrivacyCollectedDataTypePurpose"))
        let project = try String(contentsOf: repoFile("project.yml"), encoding: .utf8)
        XCTAssertTrue(project.contains("iOS: \"17.0\""))
        XCTAssertTrue(project.contains("TARGETED_DEVICE_FAMILY: \"1,2\""))
    }

    func testViewsDoNotOpenLinks() throws {
        let views = repoFile("HandheldHaven/Views")
        let files = try FileManager.default.contentsOfDirectory(at: views, includingPropertiesForKeys: nil)
        for file in files where file.pathExtension == "swift" {
            let text = try String(contentsOf: file, encoding: .utf8)
                .replacingOccurrences(of: "ShareLink(", with: "")
                .replacingOccurrences(of: "NavigationLink(", with: "")
            XCTAssertFalse(text.contains("Link("), file.lastPathComponent)
            XCTAssertFalse(text.contains("openURL"), file.lastPathComponent)
            XCTAssertFalse(text.contains("https://"), file.lastPathComponent)
            XCTAssertFalse(text.contains("amazon"), file.lastPathComponent)
        }
    }

    private func repoFile(_ relative: String) -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent(relative)
    }

    private func entryBlock(named name: String, in text: String) throws -> String {
        let marker = "ENTRY: \(name)"
        guard let start = text.range(of: marker) else {
            XCTFail("missing \(marker)")
            return ""
        }
        let rest = text[start.lowerBound...]
        if let next = rest.dropFirst(marker.count).range(of: "\nENTRY:") {
            return String(rest[..<next.lowerBound])
        }
        return String(rest)
    }
}
