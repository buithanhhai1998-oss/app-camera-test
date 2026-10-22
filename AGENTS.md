# Flutter iOS Sideload — AI Development Rules
# Workspace: D:\source\IOS (Windows-only developer, Free Apple ID, SideStore / Sideloadly)

## ═══════════════════════════════════════════════════════════
## 1. PLATFORM CONSTRAINTS (HARD RULES)
## ═══════════════════════════════════════════════════════════
- `flutter build ios` and `flutter build ipa` REQUIRE macOS host with Xcode. NEVER suggest or attempt running them on Windows.
- All iOS compilation happens on GitHub Actions runner `macos-14` (Apple Silicon M1/M2).
- Local Windows verification is STRICTLY limited to:
  - `flutter analyze`
  - `flutter test`
  - `flutter run -d <android_emulator_or_device>`
  - `flutter build apk` (for functional UI and logic testing)
- NEVER recommend iOS Simulator to a Windows developer. Use Android Emulator with `device_preview` package configured with `ThemeData(platform: TargetPlatform.iOS)` for Cupertino styling.
- Local tools must live in `D:\source\IOS\tools\bin` and local Flutter in `D:\source\IOS\flutter`. DO NOT alter global system PATH or install into `C:\Program Files`.
- Always verify line endings: Git repository must enforce `core.autocrlf = input` or `.gitattributes` with `eol=lf` to prevent syntax errors on macOS CI runners.

## ═══════════════════════════════════════════════════════════
## 2. FORBIDDEN PACKAGES (Free Apple ID Sideload)
## ═══════════════════════════════════════════════════════════
The following packages are STRICTLY PROHIBITED in `app/pubspec.yaml` because Apple restricts their required entitlements to $99/year paid developer accounts:

1. `firebase_messaging`:
   - Reason: Requires `aps-environment` (APNs). Free accounts reject APNs device tokens. `getToken()` returns null or throws.
   - Replacement: `web_socket_channel` or `supabase_flutter` Realtime for active streaming, plus `flutter_local_notifications` for local alerts.
2. `sign_in_with_apple`:
   - Reason: Requires `com.apple.developer.applesignin` entitlement. Free accounts cannot provision this capability; crashes at runtime.
   - Replacement: `google_sign_in` or Supabase / Firebase email-password and OAuth web authentication.
3. `flutter_inapp_purchase` / `in_app_purchase`:
   - Reason: StoreKit capabilities are not provisioned for sideloaded personal bundles.
4. Any iCloud plugin (`flutter_icloud_sync` etc.):
   - Reason: `com.apple.developer.icloud-container-identifiers` is blocked on personal teams.
5. Any HomeKit / HealthKit / NFC plugins:
   - Reason: Hardware entitlements are blocked on Free Apple accounts.

## ═══════════════════════════════════════════════════════════
## 3. SAFE PACKAGE WHITELIST
## ═══════════════════════════════════════════════════════════
- Local Storage: `sqflite`, `drift`, `isar`, `hive_flutter`, `shared_preferences`, `path_provider`. (All persist in sandbox across renewals).
- Secure Storage: `flutter_secure_storage` (Single-app mode ONLY. DO NOT enable keychain sharing or App Groups).
- Networking: `http`, `dio`, `web_socket_channel`, `supabase_flutter`.
- Notifications: `flutter_local_notifications` (Uses `UNUserNotificationCenter`, 100% functional without APNs).
- Biometrics: `local_auth` (Face ID / Touch ID requires only `NSFaceIDUsageDescription` in `Info.plist`).
- Media & Hardware: `camera`, `image_picker`, `file_picker`, `geolocator` (Require only `Info.plist` usage descriptions).
- Maps: `flutter_map` (OpenStreetMap, pure Dart, recommended) instead of `google_maps_flutter` (adds 150MB+ CocoaPods overhead to CI).
- Crash Tracking: `sentry_flutter` or in-app `runZonedGuarded` logging (since native `.ips` symbolication requires Xcode on Mac).

## ═══════════════════════════════════════════════════════════
## 4. ENTITLEMENTS & INFO.PLIST POLICIES
## ═══════════════════════════════════════════════════════════
- `app/ios/Runner/Runner.entitlements`:
  - Must remain an EMPTY dictionary `<dict></dict>` for Release builds.
  - Adding ANY capability entitlement (push, apple sign in, universal links, app groups) causes Sideloadly and SideStore to fail during profile generation.
  - Sideloadly and SideStore automatically inject the personal team application identifier at install time.
- `app/ios/Runner/Info.plist`:
  - MUST include descriptive non-empty strings for any accessed capability:
    - `NSCameraUsageDescription`
    - `NSPhotoLibraryUsageDescription`
    - `NSLocationWhenInUseUsageDescription`
    - `NSFaceIDUsageDescription`
    - `NSMicrophoneUsageDescription`
  - MUST set `ITSAppUsesNonExemptEncryption = false` to bypass export compliance dialogs.
  - Leaving any usage description key empty or missing when the plugin is invoked causes iOS to terminate the process with `SIGABRT` silently.

## ═══════════════════════════════════════════════════════════
## 5. CI/CD WORKFLOW (GitHub Actions)
## ═══════════════════════════════════════════════════════════
- Runner: `macos-14` (Apple Silicon M1/M2).
- Critical Step Execution Order:
  1. `sudo xcodebuild -license accept`
  2. `maxim-lobanov/setup-xcode@v1` (Xcode 16.x)
  3. `subosito/flutter-action@v2` (Pin stable e.g. 3.24.5)
  4. Cache pub (`app/pubspec.lock`) and CocoaPods (`app/ios/Podfile.lock`)
  5. `flutter pub get`
  6. `flutter build ios --config-only --no-codesign` (Generates `Generated.xcconfig` before CocoaPods runs)
  7. Sanitize `Runner.entitlements` to `<dict></dict>`
  8. `cd ios && pod install --repo-update` (with `COCOAPODS_DISABLE_STATS=true`)
  9. `flutter build ios --release --no-codesign`
  10. Package IPA manually: `mkdir -p Payload && cp -R Runner.app Payload/ && zip -r -y Runner.ipa Payload`
  11. Generate SHA256 checksum
  12. Upload artifact (retention 7 days) and publish to GitHub Release on version tag `v*`
- NEVER use `flutter build ipa` on CI without signing certificates; it will fail immediately.

## ═══════════════════════════════════════════════════════════
## 6. LOCAL DEV & DEBUG LOOP (Windows -> iPhone)
## ═══════════════════════════════════════════════════════════
- 90% of development: Run on Android Emulator with `device_preview`.
- Native iOS Verification:
  - Push commit or tag to trigger GitHub Actions build.
  - Download `Runner.ipa`.
  - Install to iPhone via Sideloadly (first time) or SideStore.
- Hot Reload without Xcode:
  - Wi-Fi: Launch Debug-mode IPA on iPhone. Copy Dart VM URL from console → `powershell tools/attach-wifi.ps1`.
  - USB: Connect cable → `powershell tools/attach-usb.ps1` (uses local `tools/bin/iproxy.exe` to forward port 8181).
  - Press `r` for Hot Reload, `R` for Hot Restart. Open DevTools in Chrome for widget tree and CPU/Memory profiling.

## ═══════════════════════════════════════════════════════════
## 7. SIDELOADING & DATA SAFETY
## ═══════════════════════════════════════════════════════════
- iTunes: Install the standalone 64-bit installer from Apple (NOT Microsoft Store). The Microsoft Store UWP version omits AMDS USB drivers required by Sideloadly and iproxy.
- Apple ID: ALWAYS use a secondary burner Apple ID with zero payment methods.
- Bundle ID: Keep `CFBundleIdentifier` constant (`com.yourname.appname`). NEVER change Bundle ID after initial installation or append version suffixes (`app.v2`), as each consumes one of the 10 rolling 7-day App ID slots on Apple Developer Portal.
- Data Persistence: Updating the app via Sideloadly or SideStore PRESERVES SQLite, SharedPreferences, and Documents directory data 100%, provided the app is not manually deleted from the home screen first.
- 7-Day Expiry: When a certificate expires, the app refuses to launch but data is NOT lost. Re-signing via SideStore or Sideloadly restores access immediately.
