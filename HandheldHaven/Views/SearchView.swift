import SwiftUI

struct SearchView: View {
    @EnvironmentObject private var store: HavenStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var query = ""
    @State private var scope: SearchScope = .all
    @State private var announce: Task<Void, Never>?

    var body: some View {
        let hits = store.search(query, scope: scope)
        NavigationStack {
            List {
                if !HavenStore.terms(query).isEmpty {
                    Section {
                        Text(countLabel(hits.count))
                            .font(.body)
                            .accessibilityIdentifier("resultCount")
                        ForEach(hits) { hit in
                            switch hit {
                            case .device(let id):
                                if let device = store.device(id) { DeviceRow(device: device) }
                            case .guide(let id):
                                if let guide = store.guide(id) { GuideRow(guide: guide) }
                            case .term(let id):
                                if let term = store.term(id) {
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
                    } header: {
                        SectionHeader("Results")
                    }
                } else {
                    Section {
                        Text("Search devices, the buyer's guide, screen reader setup, history, and the glossary. Every word must match.")
                            .font(.body)
                    } header: {
                        SectionHeader("Search")
                    }
                }
            }
            .havenListChrome()
            .havenScreenTitle("Search")
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Find")
            .autocorrectionDisabled()
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Picker("Show", selection: $scope) {
                        ForEach(SearchScope.allCases) { item in
                            Text(item.title).tag(item)
                        }
                    }
                    .pickerStyle(.menu)
                    .accessibilityHint("Filters search results.")
                }
            }
            .havenDestinations()
            .onChange(of: query) { _, _ in scheduleAnnouncement(hits.count) }
            .onChange(of: scope) { _, _ in scheduleAnnouncement(store.search(query, scope: scope).count) }
        }
    }

    private func countLabel(_ count: Int) -> String {
        count == 1 ? "1 result" : "\(count) results"
    }

    private func scheduleAnnouncement(_ count: Int) {
        announce?.cancel()
        guard !HavenStore.terms(query).isEmpty else { return }
        announce = Task {
            if !reduceMotion {
                try? await Task.sleep(for: .milliseconds(600))
            }
            guard !Task.isCancelled else { return }
            AccessibilityNotification.Announcement(countLabel(count)).post()
        }
    }
}
