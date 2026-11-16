import SwiftUI

enum TextSizeOption: String, CaseIterable, Identifiable {
    case system, xSmall, small, medium, large, xLarge, xxLarge, xxxLarge,
         accessibility1, accessibility2, accessibility3, accessibility4, accessibility5

    static let storageKey = "haven.textSize"
    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "Use system setting"
        case .xSmall: return "Extra small"
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large (system default)"
        case .xLarge: return "Extra large"
        case .xxLarge: return "Extra extra large"
        case .xxxLarge: return "Extra extra extra large"
        case .accessibility1: return "Accessibility size 1"
        case .accessibility2: return "Accessibility size 2"
        case .accessibility3: return "Accessibility size 3"
        case .accessibility4: return "Accessibility size 4"
        case .accessibility5: return "Accessibility size 5, largest"
        }
    }

    var dynamicTypeSize: DynamicTypeSize? {
        switch self {
        case .system: return nil
        case .xSmall: return .xSmall
        case .small: return .small
        case .medium: return .medium
        case .large: return .large
        case .xLarge: return .xLarge
        case .xxLarge: return .xxLarge
        case .xxxLarge: return .xxxLarge
        case .accessibility1: return .accessibility1
        case .accessibility2: return .accessibility2
        case .accessibility3: return .accessibility3
        case .accessibility4: return .accessibility4
        case .accessibility5: return .accessibility5
        }
    }
}

enum HighContrastSetting {
    static let storageKey = "haven.highContrast"
}

struct SettingsView: View {
    @AppStorage(TextSizeOption.storageKey) private var textSize: TextSizeOption = .system
    @AppStorage(HighContrastSetting.storageKey) private var highContrast = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var systemContrast
    @EnvironmentObject private var favorites: FavoritesStore
    @EnvironmentObject private var recents: RecentsStore
    @EnvironmentObject private var compare: CompareStore
    @State private var confirmFavorites = false

    var body: some View {
        Form {
            Section {
                Picker("Text size", selection: $textSize) {
                    ForEach(TextSizeOption.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
                .pickerStyle(.navigationLink)
                Text("Sample: A handheld with a built-in keyboard gives you every screen reader command.")
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
            } header: {
                SectionHeader("Text")
            } footer: {
                Text("Every screen uses Dynamic Type. Use system setting follows Settings, Accessibility, Display and Text Size, on iPhone and iPad.")
                    .foregroundStyle(Color(.label))
            }

            Section {
                Toggle("High contrast", isOn: $highContrast)
                LabeledFact(
                    label: "Increase Contrast",
                    value: systemContrast == .increased ? "On in system settings" : "Off in system settings"
                )
                LabeledFact(
                    label: "Reduce Motion",
                    value: reduceMotion ? "On. Handheld Haven adds no extra animation." : "Off. Handheld Haven adds no extra animation."
                )
            } header: {
                SectionHeader("Contrast and motion")
            } footer: {
                Text("High contrast makes supporting text semibold and follows the system Increase Contrast setting when that is on. Text stays in the label color so it does not depend on gray. Reduce Motion is read from the system. Navigation uses the system motion setting.")
                    .foregroundStyle(Color(.label))
            }

            Section {
                Button("Clear Recently Viewed (\(recents.keys.count))", role: .destructive) { recents.removeAll() }
                    .disabled(recents.keys.isEmpty)
                Button("Clear Comparison (\(compare.ids.count))", role: .destructive) { compare.removeAll() }
                    .disabled(compare.ids.isEmpty)
                Button("Remove All Favorites (\(favorites.keys.count))", role: .destructive) { confirmFavorites = true }
                    .disabled(favorites.keys.isEmpty)
            } header: {
                SectionHeader("Saved on this device")
            } footer: {
                Text("Favorites, recently viewed entries, comparison picks, text size, and high contrast stay on this device. Nothing is sent anywhere.")
                    .foregroundStyle(Color(.label))
            }
        }
        .havenListChrome()
        .havenScreenTitle("Settings")
        .confirmationDialog("Remove all \(favorites.keys.count) favorites?", isPresented: $confirmFavorites, titleVisibility: .visible) {
            Button("Remove All Favorites", role: .destructive) { favorites.removeAll() }
            Button("Cancel", role: .cancel) {}
        }
    }
}
