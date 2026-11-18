import Foundation

enum PrivacyPolicy {
    static let effectiveDate = "November 16, 2026"

    struct Paragraph: Identifiable {
        var heading: String
        var body: String
        var id: String { heading }
    }

    static let paragraphs: [Paragraph] = [
        Paragraph(
            heading: "Summary",
            body: "Handheld Haven does not collect, store, share, or sell any personal information. The developer receives no data from the app."
        ),
        Paragraph(
            heading: "Works offline",
            body: "The guide is included in the app. Handheld Haven makes no network requests and works with no internet connection. Source addresses from the book are shown as text so you can read them. The app does not open them."
        ),
        Paragraph(
            heading: "No accounts, ads, or tracking",
            body: "There are no accounts, sign-ins, analytics, advertising, tracking, or third-party software development kits."
        ),
        Paragraph(
            heading: "What stays on your device",
            body: "Favorites, recently viewed entries, comparison picks, text size, and the high contrast switch are saved only on this device. They are never sent to the developer or anyone else. Deleting the app deletes them. They may be included in your own device backups, which Apple handles under its privacy policy."
        ),
        Paragraph(
            heading: "Sharing",
            body: "When you choose Share as TXT, the text goes only where you send it."
        ),
        Paragraph(
            heading: "Children",
            body: "Handheld Haven collects no data from anyone, including children."
        ),
        Paragraph(
            heading: "Changes",
            body: "If this policy changes, the new version will appear in the app with a new effective date."
        ),
        Paragraph(
            heading: "App Store privacy label",
            body: "Data Not Collected."
        ),
    ]
}

enum AboutCopy {
    static let affiliation = "Handheld Haven is an independent guide to handheld PCs, UMPCs, and small Windows devices. It is not affiliated with, endorsed by, or sponsored by any manufacturer named in the text, including GPD, AYANEO, One-Netbook, OneXPlayer, Lenovo, MSI, ASUS, Microsoft, Dell, Valve, Sony, Samsung, Toshiba, HP, Acer, Zotac, Fujitsu, OQO, and Viliv. Product names are trademarks of their owners and are used only to identify devices the source text describes. This app shows no manufacturer logos and no product images."
    static let noCommerce = "This app does not sell devices. It has no store links, no affiliate links, and no ads."
}
