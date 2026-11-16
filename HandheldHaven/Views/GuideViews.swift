import SwiftUI

struct GuideDetailView: View {
    let guide: Guide
    @EnvironmentObject private var recents: RecentsStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Text(guide.title)
                    .font(.largeTitle.weight(.bold))
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityHeading(.h1)
                FavoriteButton(key: FavoriteKey.guide(guide.id), name: guide.title)
                ShareTextButton(title: guide.title, text: exportText)
                if !guide.intro.isEmpty {
                    BodyText(guide.intro)
                }
                ForEach(guide.sections) { section in
                    DetailSection(section.heading) {
                        BodyText(section.body.isEmpty ? notStatedInEntry : section.body)
                    }
                }
            }
            .padding()
            .readableColumn()
        }
        .wrappingNavigationTitle(guide.title)
        .onAppear { recents.record(FavoriteKey.guide(guide.id)) }
    }

    private var exportText: String {
        var lines = [guide.title, "", guide.intro]
        for section in guide.sections {
            lines.append("")
            lines.append(section.heading)
            lines.append(section.body)
        }
        return lines.joined(separator: "\n")
    }
}

struct GlossaryView: View {
    @EnvironmentObject private var store: HavenStore
    @State private var query = ""

    var body: some View {
        let terms = store.glossaryTerms(matching: query)
        List {
            Section {
                Text("Glossary")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color(.label))
                    .accessibilityHeading(.h1)
                if !store.data.glossaryIntro.isEmpty {
                    Text(store.data.glossaryIntro)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color(.label))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Text("\(terms.count) \(terms.count == 1 ? "term" : "terms")")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color(.label))
                    .accessibilityHeading(.h2)
                ForEach(terms) { term in
                    NavigationLink(value: Route.glossaryTerm(term.id)) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(term.term).font(.body.weight(.semibold)).foregroundStyle(Color(.label))
                            SecondaryLine(text: term.definition)
                        }
                        .padding(.vertical, 2)
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
        .havenListChrome()
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Find a term")
        .autocorrectionDisabled()
    }
}

struct GlossaryTermView: View {
    let term: GlossaryTerm
    @EnvironmentObject private var store: HavenStore
    @EnvironmentObject private var recents: RecentsStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(term.term)
                    .font(.largeTitle.weight(.bold))
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityHeading(.h1)
                FavoriteButton(key: FavoriteKey.term(term.id), name: term.term)
                BodyText(term.definition)
                if let target = store.term(term.seeAlso) {
                    NavigationLink(value: Route.glossaryTerm(target.id)) {
                        Text("See \(target.term)")
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .accessibilityHint("Opens the glossary entry for \(target.term).")
                }
            }
            .padding()
            .readableColumn()
        }
        .wrappingNavigationTitle(term.term)
        .onAppear { recents.record(FavoriteKey.term(term.id)) }
    }
}

struct SourcesView: View {
    @EnvironmentObject private var store: HavenStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Text("SOURCES")
                    .font(.largeTitle.weight(.bold))
                    .accessibilityHeading(.h1)
                BodyText(store.data.sourcesIntro)
                BodyText("Addresses are shown as text. This app does not open them and does not link to stores.")
                ForEach(store.data.sourceGroups) { group in
                    DetailSection(group.title) {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(group.urls.enumerated()), id: \.offset) { index, url in
                                Text("\(index + 1). \(url)")
                                    .font(.body)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .textSelection(.enabled)
                            }
                        }
                    }
                }
            }
            .padding()
            .readableColumn()
        }
        .havenScreenTitle("Sources")
        .inlineTitle()
    }
}
