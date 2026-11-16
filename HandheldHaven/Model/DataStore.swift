import Combine
import Foundation

/// Read-only store for the bundled Handheld Haven text. Search, comparison, and
/// export use only strings parsed from that text.
final class HavenStore: ObservableObject {
    let data: HavenData
    let chapters: [Chapter]
    let devices: [Device]
    let guides: [Guide]
    let glossary: [GlossaryTerm]
    private let deviceByID: [String: Device]
    private let chapterByID: [String: Chapter]
    private let guideByID: [String: Guide]
    private let termByID: [String: GlossaryTerm]
    private let deviceIndex: [String: String]
    private let guideIndex: [String: String]
    private let termIndex: [String: String]

    /// Guides in the order a reader meets them: the buying and setup chapters,
    /// then the front matter from the book.
    static let browseGuideIDs = ["buyers-guide", "screen-reader", "history", "readme", "index"]

    init(data: HavenData) {
        self.data = data
        chapters = data.chapters
        devices = data.devices
        guides = data.guides
        glossary = data.glossary
        deviceByID = Dictionary(data.devices.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        chapterByID = Dictionary(data.chapters.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        guideByID = Dictionary(data.guides.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        termByID = Dictionary(data.glossary.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })

        var devicesFolded: [String: String] = [:]
        for device in data.devices {
            let chapter = data.chapters.first { $0.id == device.chapterID }?.title ?? ""
            devicesFolded[device.id] = HavenStore.fold(chapter + "\n" + HavenStore.plainText(for: device))
        }
        deviceIndex = devicesFolded
        guideIndex = Dictionary(data.guides.map { guide in
            let body = ([guide.title, guide.intro] + guide.sections.flatMap { [$0.heading, $0.body] }).joined(separator: "\n")
            return (guide.id, HavenStore.fold(body))
        }, uniquingKeysWith: { a, _ in a })
        termIndex = Dictionary(data.glossary.map { term in
            (term.id, HavenStore.fold(term.term + "\n" + term.definition))
        }, uniquingKeysWith: { a, _ in a })
    }

    static func loadBundled(bundle: Bundle = .main) throws -> HavenStore {
        guard let url = bundle.url(forResource: "haven-data", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        let raw = try Data(contentsOf: url)
        return HavenStore(data: try JSONDecoder().decode(HavenData.self, from: raw))
    }

    func chapter(_ id: String) -> Chapter? { chapterByID[id] }
    func device(_ id: String) -> Device? { deviceByID[id] }
    func guide(_ id: String) -> Guide? { guideByID[id] }
    func term(_ id: String) -> GlossaryTerm? { termByID[id] }

    func device(named name: String) -> Device? { devices.first { $0.name == name } }

    func devices(in chapter: Chapter) -> [Device] {
        chapter.deviceIDs.compactMap { deviceByID[$0] }
    }

    var browseGuides: [Guide] {
        HavenStore.browseGuideIDs.compactMap { guideByID[$0] }
    }

    func chapterTitle(for device: Device) -> String {
        chapterByID[device.chapterID]?.title ?? device.chapterID
    }

    func title(forKey key: String) -> String? {
        guard let parsed = FavoriteKey.parse(key) else { return nil }
        switch parsed.kind {
        case .device: return device(parsed.id)?.name
        case .guide: return guide(parsed.id)?.title
        case .term: return term(parsed.id)?.term
        }
    }

    /// Labeled lines that appear in the entry. Empty optional lines are omitted.
    func labeledFacts(for device: Device) -> [Fact] {
        var facts = [
            Fact(label: "Maker", value: device.maker),
            Fact(label: "Released", value: device.released),
            Fact(label: "Launch price", value: device.launchPrice),
        ]
        if !device.alsoKnownAs.isEmpty {
            facts.append(Fact(label: "Also known as", value: device.alsoKnownAs))
        }
        facts.append(contentsOf: device.extraHeader.filter { !$0.label.isEmpty })
        facts.append(contentsOf: device.hardware.filter { !$0.label.isEmpty })
        return facts
    }

    /// One row per labeled fact present on at least one device. A device with no
    /// such line gets `notStatedInEntry` rather than a value copied from the other.
    func comparisonRows(for devices: [Device]) -> [ComparisonRow] {
        guard !devices.isEmpty else { return [] }
        let tables = devices.map { device -> [String: String] in
            Dictionary(labeledFacts(for: device).map { ($0.label, $0.value) }, uniquingKeysWith: { first, _ in first })
        }
        var labels: [String] = []
        for device in devices {
            for fact in labeledFacts(for: device) where !labels.contains(fact.label) {
                labels.append(fact.label)
            }
        }
        return labels.map { label in
            ComparisonRow(label: label, values: tables.map { $0[label] ?? notStatedInEntry })
        }
    }

    static func plainText(for device: Device) -> String {
        var lines: [String] = ["ENTRY: \(device.name)"]
        if !device.alsoKnownAs.isEmpty { lines.append("Also known as: \(device.alsoKnownAs)") }
        lines.append("Maker: \(device.maker)")
        lines.append("Released: \(device.released)")
        lines.append("Launch price: \(device.launchPrice)")
        for fact in device.extraHeader where !fact.label.isEmpty {
            lines.append("\(fact.label): \(fact.value)")
        }
        func block(_ heading: String, _ body: String) {
            lines.append("")
            lines.append(heading)
            if !body.isEmpty { lines.append(body) }
        }
        block("WHAT IT CAN DO", device.overview)
        lines.append("")
        lines.append("HARDWARE")
        for fact in device.hardware {
            if fact.label.isEmpty { lines.append(fact.value) }
            else { lines.append("\(fact.label): \(fact.value)") }
        }
        block("CONTROLS AND BUTTON LAYOUT", device.controls)
        block("HOW IT FEELS", device.howItFeels)
        block("BLIND USABILITY", device.blindUsability)
        block("GAME COMPATIBILITY", device.gameCompatibility)
        block("UNCERTAIN", device.uncertain)
        for section in device.extraSections {
            block(section.heading, section.body)
        }
        lines.append("")
        lines.append("SOURCES")
        lines.append(contentsOf: device.sources)
        return lines.joined(separator: "\n")
    }

    static func fileName(_ title: String) -> String {
        let forbidden = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        let cleaned = title.unicodeScalars.map { forbidden.contains($0) ? "-" : Character($0) }
        let base = String(cleaned).trimmingCharacters(in: .whitespacesAndNewlines)
        let name = base.isEmpty ? "Handheld Haven" : base
        return name.hasSuffix(".txt") ? name : name + ".txt"
    }

    // MARK: Search

    static func fold(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: Locale(identifier: "en_US"))
    }

    static func terms(_ query: String) -> [String] {
        fold(query).split(whereSeparator: { $0 == " " || $0 == "\n" || $0 == "\t" }).map(String.init)
    }

    func search(_ query: String, scope: SearchScope = .all) -> [SearchHit] {
        let words = HavenStore.terms(query)
        guard !words.isEmpty else { return [] }
        let foldedQuery = HavenStore.fold(query.trimmingCharacters(in: .whitespacesAndNewlines))
        var hits: [(rank: Int, kind: Int, index: Int, hit: SearchHit)] = []

        func rank(of title: String) -> Int {
            let name = HavenStore.fold(title)
            if name == foldedQuery { return 0 }
            if name.hasPrefix(foldedQuery) { return 1 }
            if words.allSatisfy({ name.contains($0) }) { return 2 }
            return 3
        }

        if scope == .all || scope == .devices {
            for (index, device) in devices.enumerated() {
                guard let hay = deviceIndex[device.id], words.allSatisfy({ hay.contains($0) }) else { continue }
                hits.append((rank(of: device.name), 0, index, .device(device.id)))
            }
        }
        if scope == .all || scope == .glossary {
            for (index, term) in glossary.enumerated() {
                guard let hay = termIndex[term.id], words.allSatisfy({ hay.contains($0) }) else { continue }
                hits.append((rank(of: term.term), 1, index, .term(term.id)))
            }
        }
        if scope == .all || scope == .guides {
            for (index, guide) in guides.enumerated() {
                guard let hay = guideIndex[guide.id], words.allSatisfy({ hay.contains($0) }) else { continue }
                hits.append((rank(of: guide.title), 2, index, .guide(guide.id)))
            }
        }
        return hits.sorted { lhs, rhs in
            if lhs.rank != rhs.rank { return lhs.rank < rhs.rank }
            if lhs.kind != rhs.kind { return lhs.kind < rhs.kind }
            return lhs.index < rhs.index
        }.map(\.hit)
    }

    func glossaryTerms(matching query: String) -> [GlossaryTerm] {
        let words = HavenStore.terms(query)
        guard !words.isEmpty else { return glossary }
        return glossary.filter { term in
            guard let hay = termIndex[term.id] else { return false }
            return words.allSatisfy { hay.contains($0) }
        }
    }
}
