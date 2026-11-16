import SwiftUI

struct CompareView: View {
    @EnvironmentObject private var store: HavenStore
    @EnvironmentObject private var compare: CompareStore
    @Environment(\.horizontalSizeClass) private var sizeClass
    @AppStorage("haven.compare.differencesOnly") private var differencesOnly = false
    @State private var showingPicker = false

    var body: some View {
        let picked = compare.ids.compactMap { store.device($0) }
        let rows = store.comparisonRows(for: picked)
        let shown = differencesOnly ? rows.filter(\.differs) : rows
        NavigationStack {
            List {
                Section {
                    if picked.isEmpty {
                        Text("Pick two devices to compare labeled facts from their entries. Use Add Device, or Add to Compare on a device page. Only lines written in the text are shown.")
                            .font(.body)
                    }
                    ForEach(Array(picked.enumerated()), id: \.element.id) { index, device in
                        NavigationLink(value: Route.device(device.id)) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Device \(index + 1): \(device.name)")
                                    .font(.body.weight(.semibold))
                                SecondaryLine(text: device.maker)
                            }
                            .accessibilityElement(children: .combine)
                        }
                        .swipeActions {
                            Button(role: .destructive) { compare.remove(device.id) } label: {
                                Label("Remove", systemImage: "minus.circle")
                            }
                        }
                        .accessibilityAction(named: "Remove from Compare") { compare.remove(device.id) }
                    }
                    if !compare.isFull {
                        Button {
                            showingPicker = true
                        } label: {
                            Label("Add Device", systemImage: "plus.circle")
                        }
                        .accessibilityHint("\(compare.ids.count) of \(CompareStore.capacity) devices picked.")
                    }
                    if !picked.isEmpty {
                        Button("Clear Comparison", role: .destructive) { compare.removeAll() }
                    }
                } header: {
                    SectionHeader("Devices (\(picked.count) of \(CompareStore.capacity))")
                }

                if picked.count == 2 {
                    Section {
                        Toggle("Show only differences", isOn: $differencesOnly)
                    } footer: {
                        Text("\(shown.count) of \(rows.count) labeled facts shown. A blank line in one entry reads: \(notStatedInEntry)")
                    }
                    ForEach(shown) { row in
                        Section {
                            Text(row.label)
                                .font(.title3.weight(.bold))
                                .fixedSize(horizontal: false, vertical: true)
                                .accessibilityHeading(.h2)
                            factPair(devices: picked, values: row.values)
                        }
                    }
                } else if picked.count == 1 {
                    Text("Add one more device to see the comparison.")
                        .font(.body)
                }
            }
            .navigationTitle("Compare")
            .havenDestinations()
            .sheet(isPresented: $showingPicker) {
                ComparePickerView()
            }
        }
    }

    /// On iPhone the two values stack. On a wide iPad they sit side by side.
    /// VoiceOver still reads the fact heading, then device 1, then device 2.
    @ViewBuilder
    private func factPair(devices: [Device], values: [String]) -> some View {
        if sizeClass == .regular {
            HStack(alignment: .top, spacing: 16) {
                ForEach(Array(zip(devices, values).enumerated()), id: \.offset) { _, pair in
                    LabeledFact(label: pair.0.name, value: pair.1)
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(zip(devices, values).enumerated()), id: \.offset) { _, pair in
                    LabeledFact(label: pair.0.name, value: pair.1)
                }
            }
        }
    }
}

struct ComparePickerView: View {
    @EnvironmentObject private var store: HavenStore
    @EnvironmentObject private var compare: CompareStore
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    var body: some View {
        let words = HavenStore.terms(query)
        let results = (words.isEmpty ? store.devices : store.search(query, scope: .devices).compactMap { hit -> Device? in
            if case .device(let id) = hit { return store.device(id) }
            return nil
        }).filter { !compare.contains($0.id) }
        NavigationStack {
            List {
                Section {
                    ForEach(results) { device in
                        Button {
                            compare.add(device.id)
                            AccessibilityNotification.Announcement("Added \(device.name) to Compare.").post()
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(device.name).font(.body.weight(.semibold))
                                SecondaryLine(text: device.maker)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityElement(children: .combine)
                        }
                        .foregroundStyle(.primary)
                    }
                } header: {
                    SectionHeader("\(results.count) devices")
                }
            }
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Find a device to add")
            .autocorrectionDisabled()
            .navigationTitle("Add Device")
            .inlineTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
