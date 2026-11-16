import SwiftUI

struct DeviceDetailView: View {
    let device: Device
    @EnvironmentObject private var store: HavenStore
    @EnvironmentObject private var recents: RecentsStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(device.name)
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(Color(.label))
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityHeading(.h1)
                    SecondaryLine(text: store.chapterTitle(for: device))
                    if device.thin {
                        Text("THIN ENTRY")
                            .font(.headline)
                            .accessibilityLabel("Thin entry")
                    }
                }
                VStack(alignment: .leading, spacing: 10) {
                    FavoriteButton(key: FavoriteKey.device(device.id), name: device.name)
                    CompareButton(device: device)
                    ShareTextButton(title: device.name, text: exportText)
                }
                DetailSection("Entry") {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(store.labeledFacts(for: device).filter { headerLabels.contains($0.label) }) { fact in
                            LabeledFact(label: fact.label, value: fact.value)
                        }
                    }
                }
                prose("WHAT IT CAN DO", device.overview)
                DetailSection("HARDWARE") {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(device.hardware) { fact in
                            if fact.label.isEmpty {
                                BodyText(fact.value)
                            } else {
                                LabeledFact(label: fact.label, value: fact.value)
                            }
                        }
                    }
                }
                prose("CONTROLS AND BUTTON LAYOUT", device.controls)
                prose("HOW IT FEELS", device.howItFeels)
                prose("BLIND USABILITY", device.blindUsability)
                prose("GAME COMPATIBILITY", device.gameCompatibility)
                prose("UNCERTAIN", device.uncertain)
                ForEach(device.extraSections) { section in
                    prose(section.heading, section.body)
                }
                DetailSection("SOURCES") {
                    if device.sources.isEmpty {
                        BodyText(notStatedInEntry)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(device.sources.enumerated()), id: \.offset) { index, source in
                                Text("Source \(index + 1). \(source)")
                                    .font(.body)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .textSelection(.enabled)
                            }
                        }
                        .accessibilityElement(children: .contain)
                    }
                }
            }
            .padding()
            .readableColumn()
        }
        .background(Color(.systemBackground))
        .wrappingNavigationTitle(device.name)
        .onAppear { recents.record(FavoriteKey.device(device.id)) }
    }

    private var headerLabels: Set<String> {
        ["Maker", "Released", "Launch price", "Also known as"]
    }

    private var exportText: String {
        HavenStore.plainText(for: device) + "\n\n---\n" + AboutCopy.affiliation
    }

    @ViewBuilder
    private func prose(_ title: String, _ body: String) -> some View {
        DetailSection(title) {
            BodyText(body.isEmpty ? notStatedInEntry : body)
        }
    }
}
