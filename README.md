# Handheld Haven for iPhone and iPad

A native SwiftUI app (iOS 17 or later) of Handheld Haven, an accessible encyclopedia of handheld PCs, UMPCs, and small Windows computers. The guide is bundled in the app. It works offline, collects no data, and has no ads or store links.

The text in `content/Handheld-Haven` is the only source of devices and specifications. `tools/build_content.py` copies that text into `HandheldHaven/Resources/haven-data.json`. It does not add devices, prices, or specs.

Planned listing: App Store, $3.99, category Reference, privacy label **Data Not Collected**. The price is not shown as a purchase link in the app. Signing and TestFlight upload are not set up. See `docs/APP-STORE-SETUP.md`.

## Features

- **Browse** by chapter (GPD, AYANEO, OneXPlayer, Lenovo Legion, MSI Claw, Surface, Dell Venue, Origami UMPCs, and the other families in the book) and by each `ENTRY:`.
- **Guides**: blind buyer's guide, screen reader setup, and history and eras, plus the book's readme and index.
- **Glossary** with term lookup, including "See" references such as Full screen experience to Xbox mode.
- **Full-text search** across devices, guides, and glossary. Every word must match. Case and accents are ignored.
- **Favorites** and **recently viewed**, stored on the device.
- **Compare** two devices, side by side on iPad and stacked under each fact heading on iPhone. Values are the labeled lines from the entries. A missing line reads "Not stated in this entry."
- **About** states that this is an independent guide and is not affiliated with any manufacturer. There are no manufacturer logos or product images.

## Accessibility

- Section titles use VoiceOver heading levels, so the headings rotor can move through a device, a guide, or a comparison.
- Rows are one VoiceOver element. Buttons have text labels. Favorite reports Selected. Compare announces how many devices are picked.
- Text uses Dynamic Type styles, with a setting for the system size or any of the 12 larger sizes through Accessibility 5.
- High contrast keeps text in the primary color and makes supporting text semibold. The system Increase Contrast setting turns that on as well.
- The app adds no motion of its own and follows the system Reduce Motion setting.
- Share as TXT writes the entry's own text. Source addresses are shown as text and are not opened.

## Project layout

- `project.yml`: XcodeGen spec for the app, unit tests, and UI tests. The generated `.xcodeproj` is not committed.
- `HandheldHaven/`: SwiftUI sources, `Resources/haven-data.json`, the icon, and `PrivacyInfo.xcprivacy` (no data collected).
- `HandheldHavenTests/`: data integrity against the plain text, search, comparison, and saved state.
- `HandheldHavenUITests/`: main flows and `performAccessibilityAudit()`.
- `.github/workflows/ios-ci.yml`: simulator build and tests on a macOS runner. No signing.
- `.github/workflows/testflight-upload.yml`: signing and upload, skipped until App Store Connect secrets exist.
- `docs/PRIVACY-POLICY.md`: privacy policy text.

## Not verified here

VoiceOver on a physical iPhone or iPad, signing, TestFlight, and App Review have not been done. The simulator audit catches many issues and does not replace a pass with VoiceOver.
