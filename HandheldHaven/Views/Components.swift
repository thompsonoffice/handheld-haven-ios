import SwiftUI

private struct HighContrastKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var havenHighContrast: Bool {
        get { self[HighContrastKey.self] }
        set { self[HighContrastKey.self] = newValue }
    }
}

extension View {
    func havenDestinations() -> some View {
        navigationDestination(for: Route.self) { route in
            RouteView(route: route)
        }
    }

    func inlineTitle() -> some View {
        navigationBarTitleDisplayMode(.inline)
    }

    /// Title drawn in the screen body, not in the UIKit navigation bar.
    /// A bar title stays about 20 points tall and fails the Dynamic Type audit.
    func havenScreenTitle(_ title: String) -> some View {
        safeAreaInset(edge: .top, spacing: 0) {
            Text(title)
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(Color(.label))
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal)
                .padding(.bottom, 8)
                .background(Color(.systemBackground))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(title)
                .accessibilityAddTraits(.isHeader)
                .accessibilityHeading(.h1)
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    /// Pushed pages already show their name as a heading in the content.
    func wrappingNavigationTitle(_: String) -> some View {
        navigationBarTitleDisplayMode(.inline)
    }

    /// Keeps lines at a readable length on iPad without clipping Dynamic Type.
    func readableColumn() -> some View {
        frame(maxWidth: 740, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Opaque label-colored lists. Grouped gray headers and tinted chevrons fail the contrast audit.
    func havenListChrome() -> some View {
        self
            .headerProminence(.increased)
            .tint(Color(.label))
            .scrollContentBackground(.hidden)
            .background(Color(.systemBackground))
    }
}

struct RouteView: View {
    let route: Route
    @EnvironmentObject private var store: HavenStore

    var body: some View {
        switch route {
        case .chapter(let id):
            if let chapter = store.chapter(id) { ChapterDetailView(chapter: chapter) } else { MissingEntryView() }
        case .device(let id):
            if let device = store.device(id) { DeviceDetailView(device: device) } else { MissingEntryView() }
        case .guide(let id):
            if let guide = store.guide(id) { GuideDetailView(guide: guide) } else { MissingEntryView() }
        case .glossary:
            GlossaryView()
        case .glossaryTerm(let id):
            if let term = store.term(id) { GlossaryTermView(term: term) } else { MissingEntryView() }
        case .sources:
            SourcesView()
        case .recents:
            RecentsView()
        case .settings:
            SettingsView()
        case .about:
            AboutView()
        case .privacy:
            PrivacyPolicyView()
        }
    }
}

struct MissingEntryView: View {
    var body: some View {
        Text("This entry is not in Handheld Haven.")
            .font(.body)
            .padding()
    }
}

struct SectionHeader: View {
    let title: String
    var level: AccessibilityHeadingLevel = .h2

    init(_ title: String, level: AccessibilityHeadingLevel = .h2) {
        self.title = title
        self.level = level
    }

    var body: some View {
        Text(title)
            .font(.title3.weight(.bold))
            .foregroundStyle(Color(.label))
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityHeading(level)
            .textCase(nil)
    }
}

struct DetailSection<Content: View>: View {
    let title: String
    var level: AccessibilityHeadingLevel = .h2
    let content: Content

    init(_ title: String, level: AccessibilityHeadingLevel = .h2, @ViewBuilder content: () -> Content) {
        self.title = title
        self.level = level
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title2.weight(.bold))
                .foregroundStyle(Color(.label))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityHeading(level)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct BodyText: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.body)
            .foregroundStyle(Color(.label))
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SecondaryLine: View {
    let text: String
    @Environment(\.havenHighContrast) private var highContrast

    var body: some View {
        Text(text)
            .font(highContrast ? .subheadline.weight(.semibold) : .subheadline)
            .foregroundStyle(Color(.label))
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// Label above value so large Dynamic Type sizes wrap instead of truncating.
struct LabeledFact: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.subheadline.weight(.semibold)).foregroundStyle(Color(.label))
            Text(value).font(.body).foregroundStyle(Color(.label)).fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

struct FavoriteMark: View {
    var body: some View {
        Image(systemName: "star.fill")
            .font(.body)
            .accessibilityLabel("Favorite")
    }
}

struct FavoriteButton: View {
    let key: String
    let name: String
    @EnvironmentObject private var favorites: FavoritesStore

    var body: some View {
        let isOn = favorites.contains(key)
        Button {
            favorites.toggle(key)
        } label: {
            Label("Favorite", systemImage: isOn ? "star.fill" : "star")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .tint(Color(.label))
        .accessibilityLabel("Favorite")
        .accessibilityAddTraits(isOn ? .isSelected : [])
        .accessibilityHint(isOn ? "Removes \(name) from Favorites." : "Adds \(name) to Favorites.")
    }
}

struct CompareButton: View {
    let device: Device
    @EnvironmentObject private var compare: CompareStore

    var body: some View {
        let isIn = compare.contains(device.id)
        Button {
            if isIn {
                compare.remove(device.id)
            } else {
                compare.add(device.id)
            }
            let message = isIn
                ? "Removed \(device.name) from Compare."
                : "Added \(device.name) to Compare. \(compare.ids.count) of \(CompareStore.capacity) picked."
            AccessibilityNotification.Announcement(message).post()
        } label: {
            Label(isIn ? "Remove from Compare" : "Add to Compare",
                  systemImage: isIn ? "minus.circle" : "plus.circle")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .tint(Color(.label))
        .disabled(!isIn && compare.isFull)
        .accessibilityHint(!isIn && compare.isFull
            ? "Compare already has two devices. Remove one in the Compare tab first."
            : (isIn ? "Takes \(device.name) out of the comparison." : "Puts \(device.name) in the Compare tab, next to one other device."))
    }
}

struct ShareTextButton: View {
    let title: String
    let text: String

    var body: some View {
        ShareLink(item: TextFileExport(fileName: HavenStore.fileName(title), text: text),
                  preview: SharePreview("\(title), plain text")) {
            Label("Share as TXT", systemImage: "square.and.arrow.up")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .tint(Color(.label))
        .accessibilityHint("Shares or saves this entry as a plain text file.")
    }
}

struct DeviceRow: View {
    let device: Device
    @EnvironmentObject private var store: HavenStore
    @EnvironmentObject private var favorites: FavoritesStore

    var body: some View {
        NavigationLink(value: Route.device(device.id)) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(device.name).font(.body.weight(.semibold)).foregroundStyle(Color(.label))
                    if device.thin {
                        Text("THIN ENTRY")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color(.label))
                    }
                    if favorites.contains(FavoriteKey.device(device.id)) {
                        FavoriteMark()
                    }
                }
                SecondaryLine(text: [device.maker, device.released].filter { !$0.isEmpty }.joined(separator: ". "))
            }
            .padding(.vertical, 2)
            .accessibilityElement(children: .combine)
        }
        .listRowBackground(Color(.systemBackground))
    }
}

struct ChapterRow: View {
    let chapter: Chapter
    @EnvironmentObject private var store: HavenStore

    var body: some View {
        let count = chapter.deviceIDs.count
        NavigationLink(value: Route.chapter(chapter.id)) {
            VStack(alignment: .leading, spacing: 3) {
                Text(chapter.title).font(.body.weight(.semibold)).foregroundStyle(Color(.label))
                SecondaryLine(text: "\(count) \(count == 1 ? "entry" : "entries")")
            }
            .padding(.vertical, 2)
            .accessibilityElement(children: .combine)
        }
        .listRowBackground(Color(.systemBackground))
    }
}

struct GuideRow: View {
    let guide: Guide
    @EnvironmentObject private var favorites: FavoritesStore

    var body: some View {
        NavigationLink(value: Route.guide(guide.id)) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(guide.title).font(.body.weight(.semibold)).foregroundStyle(Color(.label))
                    if favorites.contains(FavoriteKey.guide(guide.id)) {
                        FavoriteMark()
                    }
                }
                if let line = guide.intro.split(separator: "\n").first {
                    SecondaryLine(text: String(line))
                }
            }
            .padding(.vertical, 2)
            .accessibilityElement(children: .combine)
        }
        .listRowBackground(Color(.systemBackground))
    }
}

struct SavedItemRow: View {
    let key: String
    @EnvironmentObject private var store: HavenStore

    var body: some View {
        if let parsed = FavoriteKey.parse(key) {
            switch parsed.kind {
            case .device:
                if let device = store.device(parsed.id) {
                    DeviceRow(device: device)
                }
            case .guide:
                if let guide = store.guide(parsed.id) {
                    GuideRow(guide: guide)
                }
            case .term:
                if let term = store.term(parsed.id) {
                    NavigationLink(value: Route.glossaryTerm(term.id)) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(term.term).font(.body.weight(.semibold))
                            SecondaryLine(text: term.definition)
                        }
                        .padding(.vertical, 2)
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
    }
}
