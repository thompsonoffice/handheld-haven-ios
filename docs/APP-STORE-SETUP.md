# App Store setup (not done yet)

Handheld Haven is prepared as a paid reference app. Nothing in this repository signs, uploads, or submits a build.

Planned listing, once an Apple Developer Program membership is active:

- Name: Handheld Haven
- Bundle ID: `com.thompsonoffice.handheldhaven`
- Seller: thompsonoffice
- Platform: iPhone and iPad, iOS 17 or later
- Category: Reference
- Price: $3.99 (set in App Store Connect, not inside the app)
- Privacy label: Data Not Collected
- Encryption: none (`ITSAppUsesNonExemptEncryption` is NO)
- Age rating: no unrestricted web access, no ads, no user-generated content

The app does not use manufacturer logos or product images. The About screen states that it is an independent guide and is not affiliated with any manufacturer. It has no store links, affiliate links, or ads.

## TestFlight upload stays off

`.github/workflows/testflight-upload.yml` is manual-only. Its job is skipped unless the repository variable `ENABLE_TESTFLIGHT_UPLOAD` is the string `true`. Leave that unset until all of the following exist:

1. An active Apple Developer Program membership.
2. An App Store Connect app record for `com.thompsonoffice.handheldhaven`.
3. Repository secrets `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8` (the contents of the App Store Connect API key), and `APPLE_TEAM_ID`.

Do not start that workflow before then. The iOS build-and-test workflow never signs or uploads.

## Content

`tools/build_content.py` reads `content/Handheld-Haven` and writes `HandheldHaven/Resources/haven-data.json`. It copies text. It does not add devices, prices, or specifications. CI regenerates the JSON and fails if the committed file drifts.
