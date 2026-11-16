import Foundation

/// Shown when a comparison row has no labeled line in that device's entry.
/// This is interface language. It is not stored as a device fact.
let notStatedInEntry = "Not stated in this entry."

struct HavenData: Codable {
    var version: Int
    var title: String
    var deviceCount: Int
    var chapters: [Chapter]
    var devices: [Device]
    var guides: [Guide]
    var glossaryIntro: String
    var glossary: [GlossaryTerm]
    var sourcesIntro: String
    var sourceGroups: [SourceGroup]
}

struct Chapter: Codable, Identifiable, Hashable {
    var id: String
    var title: String
    var fileName: String
    var intro: String
    var deviceIDs: [String]
}

/// A labeled line copied from the source, such as "Processor: Intel Atom x7-Z8700...".
struct Fact: Codable, Hashable, Identifiable {
    var label: String
    var value: String
    var id: String { label + "\u{1f}" + value }
}

struct TextSection: Codable, Hashable, Identifiable {
    var heading: String
    var body: String
    var id: String { heading }
}

struct Device: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var chapterID: String
    var fileName: String
    var alsoKnownAs: String
    var maker: String
    var released: String
    var launchPrice: String
    var extraHeader: [Fact]
    var thin: Bool
    var overview: String
    var hardware: [Fact]
    var controls: String
    var howItFeels: String
    var blindUsability: String
    var gameCompatibility: String
    var uncertain: String
    var sources: [String]
    var extraSections: [TextSection]
}

struct Guide: Codable, Identifiable, Hashable {
    var id: String
    var title: String
    var fileName: String
    var intro: String
    var sections: [TextSection]
}

struct GlossaryTerm: Codable, Identifiable, Hashable {
    var id: String
    var term: String
    var definition: String
    /// Glossary term id when the definition is "See TERM." Empty otherwise.
    var seeAlso: String
}

struct SourceGroup: Codable, Identifiable, Hashable {
    var id: String
    var title: String
    var urls: [String]
}

struct ComparisonRow: Hashable, Identifiable {
    var label: String
    var values: [String]
    var id: String { label }
    var differs: Bool { Set(values).count > 1 }
}

enum SearchScope: String, CaseIterable, Identifiable {
    case all, devices, guides, glossary
    var id: String { rawValue }
    var title: String {
        switch self {
        case .all: return "All"
        case .devices: return "Devices"
        case .guides: return "Guides"
        case .glossary: return "Glossary"
        }
    }
}

enum SearchHit: Hashable, Identifiable {
    case device(String)
    case guide(String)
    case term(String)

    var id: String {
        switch self {
        case .device(let value): return "dev:" + value
        case .guide(let value): return "guide:" + value
        case .term(let value): return "term:" + value
        }
    }
}

enum Route: Hashable {
    case chapter(String)
    case device(String)
    case guide(String)
    case glossary
    case glossaryTerm(String)
    case sources
    case recents
    case settings
    case about
    case privacy
}

enum FavoriteKey {
    static func device(_ id: String) -> String { "dev:" + id }
    static func guide(_ id: String) -> String { "guide:" + id }
    static func term(_ id: String) -> String { "term:" + id }

    enum Kind { case device, guide, term }

    static func parse(_ key: String) -> (kind: Kind, id: String)? {
        if key.hasPrefix("dev:") { return (.device, String(key.dropFirst(4))) }
        if key.hasPrefix("guide:") { return (.guide, String(key.dropFirst(6))) }
        if key.hasPrefix("term:") { return (.term, String(key.dropFirst(5))) }
        return nil
    }
}

extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
