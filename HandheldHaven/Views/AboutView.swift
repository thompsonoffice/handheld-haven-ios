import SwiftUI

struct AboutView: View {
    @EnvironmentObject private var store: HavenStore

    private var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("About Handheld Haven")
                    .font(.largeTitle.weight(.bold))
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityHeading(.h1)
                DetailSection("Independent guide") {
                    BodyText(AboutCopy.affiliation)
                    BodyText(AboutCopy.noCommerce)
                }
                DetailSection("What is included") {
                    LabeledFact(label: "Devices", value: String(store.devices.count))
                    LabeledFact(label: "Chapters", value: String(store.chapters.count))
                    LabeledFact(label: "Guides", value: String(store.guides.count))
                    LabeledFact(label: "Glossary terms", value: String(store.glossary.count))
                    LabeledFact(label: "Source addresses", value: String(store.data.sourceGroups.reduce(0) { $0 + $1.urls.count }))
                }
                if let notes = store.guide("readme")?.sections.first(where: { $0.heading == "HONESTY NOTES" }) {
                    DetailSection(notes.heading) { BodyText(notes.body) }
                }
                if let what = store.guide("readme")?.sections.first(where: { $0.heading == "WHAT THIS IS" }) {
                    DetailSection(what.heading) { BodyText(what.body) }
                }
                DetailSection("Privacy") {
                    BodyText("Handheld Haven works offline and collects no data. Favorites, recently viewed entries, and comparisons stay on this device.")
                    NavigationLink("Read the privacy policy", value: Route.privacy)
                }
                LabeledFact(label: "By", value: "thompsonoffice")
                LabeledFact(label: "Version", value: version)
            }
            .padding()
            .readableColumn()
        }
        .havenScreenTitle("About")
        .inlineTitle()
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Handheld Haven Privacy Policy")
                    .font(.largeTitle.weight(.bold))
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityHeading(.h1)
                BodyText("Effective \(PrivacyPolicy.effectiveDate)")
                ForEach(PrivacyPolicy.paragraphs) { item in
                    DetailSection(item.heading) { BodyText(item.body) }
                }
            }
            .padding()
            .readableColumn()
        }
        .havenScreenTitle("Privacy Policy")
        .inlineTitle()
    }
}
