import SwiftUI

struct BrowseView: View {
    @EnvironmentObject private var store: HavenStore
    @EnvironmentObject private var recents: RecentsStore

    var body: some View {
        NavigationStack {
            List {
                if !recents.keys.isEmpty {
                    Section {
                        ForEach(recents.keys.prefix(5), id: \.self) { key in
                            SavedItemRow(key: key)
                        }
                        NavigationLink(value: Route.recents) {
                            Text("All recently viewed")
                        }
                    } header: {
                        SectionHeader("Recently Viewed")
                    }
                }
                Section {
                    ForEach(store.browseGuides) { guide in
                        GuideRow(guide: guide)
                    }
                    NavigationLink(value: Route.glossary) {
                        Label("Glossary", systemImage: "book.closed")
                    }
                    NavigationLink(value: Route.sources) {
                        Label("Sources", systemImage: "text.alignleft")
                    }
                } header: {
                    SectionHeader("Guides")
                } footer: {
                    Text("Independent guide. Not affiliated with any device manufacturer.")
                }
                Section {
                    ForEach(store.chapters) { chapter in
                        ChapterRow(chapter: chapter)
                    }
                } header: {
                    SectionHeader("Chapters")
                }
            }
            .navigationTitle("Browse")
            .havenDestinations()
        }
    }
}

struct ChapterDetailView: View {
    let chapter: Chapter
    @EnvironmentObject private var store: HavenStore

    var body: some View {
        List {
            Section {
                BodyText(chapter.intro)
            } header: {
                SectionHeader("About this chapter")
            }
            Section {
                ForEach(store.devices(in: chapter)) { device in
                    DeviceRow(device: device)
                }
            } header: {
                SectionHeader("Entries")
            }
        }
        .wrappingNavigationTitle(chapter.title)
    }
}

struct RecentsView: View {
    @EnvironmentObject private var recents: RecentsStore

    var body: some View {
        List {
            if recents.keys.isEmpty {
                Text("Devices, guides, and glossary terms you open will be listed here, newest first.")
                    .font(.body)
            }
            ForEach(recents.keys, id: \.self) { key in
                SavedItemRow(key: key)
                    .swipeActions {
                        Button(role: .destructive) { recents.remove(key) } label: {
                            Label("Remove", systemImage: "clock.badge.xmark")
                        }
                    }
                    .accessibilityAction(named: "Remove from Recently Viewed") { recents.remove(key) }
            }
        }
        .navigationTitle("Recently Viewed")
    }
}
