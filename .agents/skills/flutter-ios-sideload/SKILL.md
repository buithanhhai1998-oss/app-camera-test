---
name: flutter-ios-sideload
description: Full development lifecycle, CI/CD, debugging, and sideload distribution for Flutter iOS applications built from Windows with Free Apple ID (SideStore and Sideloadly). Use when developing, debugging, configuring packages, building IPA workflows, or managing 7-day renewals on Windows.
---

# Flutter iOS Sideload Skill (Windows Workstation)

Guide and execute the end-to-end lifecycle of Flutter iOS applications developed entirely on Windows, compiled via GitHub Actions macOS runners, and sideloaded via SideStore or Sideloadly using a Free Personal Apple ID.

## Core Architectural Guardrails

1. **NO LOCAL iOS BUILDS ON WINDOWS**:
   - `flutter build ios` and `flutter build ipa` will fail immediately on Windows.
   - All iOS compilation happens on GitHub Actions `macos-14` (Apple Silicon M1/M2) runners.
2. **LOCAL TOOL ISOLATION**:
   - Tools, Flutter SDK, and debug helpers live in `D:\source\IOS\flutter` and `D:\source\IOS\tools\bin`.
   - Never modify Windows global system PATH or install to `C:\Program Files`.
   - Run `env.bat` (CMD) or `. .\env.ps1` (PowerShell) to load local PATH into the current terminal session.
3. **ZERO-COST SIDELOAD COMPLIANCE**:
   - Entitlements in `Runner.entitlements` must be an empty dictionary `<dict></dict>` for Release builds.
   - Prohibited entitlements on Free Apple ID: `aps-environment`, `com.apple.developer.applesignin`, `com.apple.developer.associated-domains`, `com.apple.security.application-groups`, StoreKit, iCloud, HealthKit, HomeKit, NFC.

---

## Package Compatibility Rules

| Package | Status | Action / Replacement |
|---|:---:|---|
| `firebase_messaging` | ❌ BANNED | APNs token rejected by Apple for Free accounts. Replace with `web_socket_channel` or `supabase_flutter` Realtime + `flutter_local_notifications`. |
| `sign_in_with_apple` | ❌ BANNED | Entitlement blocked. Replace with `google_sign_in` or Supabase / Firebase email-password auth. |
| `flutter_inapp_purchase` | ❌ BANNED | StoreKit blocked on sideloaded personal teams. |
| `flutter_secure_storage` | ✅ ALLOWED | Single-app Keychain mode ONLY. Do NOT configure keychain sharing or App Groups. |
| `sqflite`, `drift`, `isar`, `hive_flutter` | ✅ ALLOWED | Sandboxed SQLite/NoSQL works 100%. Data persists across 7-day SideStore renewals and Sideloadly updates (same Bundle ID). |
| `flutter_local_notifications` | ✅ ALLOWED | Uses UNUserNotificationCenter locally. 100% functional without APNs. |
| `local_auth` | ✅ ALLOWED | Face ID / Touch ID requires only `NSFaceIDUsageDescription` in Info.plist. |
| `flutter_map` | ✅ RECOMMENDED | Pure Dart OpenStreetMap. Avoids 150MB+ Google Maps native CocoaPods overhead on CI. |
| `sentry_flutter` | ✅ RECOMMENDED | In-app Dart error capturing without requiring Xcode symbolication on Mac. |

---

## Daily Development Workflows

### 1. Daily UI & Logic Testing (90% of Time)
Execute on Android Emulator using `device_preview`:
```cmd
cd app
flutter run
```
- Simulates iPhone dimensions, Safe Area, Dynamic Island, and notch.
- `ThemeData(platform: TargetPlatform.iOS)` activates Cupertino page transitions and bouncing scroll physics.
- Hot Reload (`r`) operates in < 1 second.

### 2. Physical iPhone Hot Reload from Windows (No Mac Required)
- **Wi-Fi Method**:
  1. Ensure PC and iPhone share the same Wi-Fi subnet.
  2. Launch Debug-mode IPA on iPhone.
  3. Run: `powershell tools/attach-wifi.ps1` and supply the Dart VM URL (`http://192.168.x.x:PORT/TOKEN=/`).
- **USB Method**:
  1. Connect iPhone via USB cable (Ensure iTunes standalone AMDS driver is active).
  2. Run: `powershell tools/attach-usb.ps1` (launches local `tools/bin/iproxy.exe` forwarding port 8181).
- **Hot Reload Operations**:
  - Press `r` for Hot Reload, `R` for Hot Restart.
  - Open Chrome to `http://127.0.0.1:9100` for Flutter DevTools (Widget Inspector, Memory, CPU).

---

## CI/CD Pipeline (GitHub Actions)

### Build Script Sequence
Workflow located at `.github/workflows/build-ios-sideload.yml`:
1. Runner: `macos-14` (Apple Silicon M1/M2).
2. Steps:
   - Accept Xcode license: `sudo xcodebuild -license accept`
   - Select Xcode: `setup-xcode` (Xcode 16.x)
   - Setup Flutter: `subosito/flutter-action@v2` (Pin 3.24.5)
   - Cache CocoaPods (`app/ios/Podfile.lock`) and Pub (`app/pubspec.lock`)
   - `flutter pub get`
   - `flutter build ios --config-only --no-codesign` (Generates `Generated.xcconfig` before CocoaPods runs)
   - Sanitize `Runner.entitlements` to empty `<dict></dict>`
   - `cd ios && pod install --repo-update` (with `COCOAPODS_DISABLE_STATS=true`)
   - `flutter build ios --release --no-codesign`
   - Assemble IPA: `mkdir -p Payload && cp -R Runner.app Payload/ && zip -r -y Runner.ipa Payload`
   - Calculate SHA256 checksum
   - Upload artifact (7 days retention) and publish GitHub Release on tag (`v*.*.*`)
   - Update `altsource/apps.json` and push to `gh-pages` branch

---

## Sideload Installation & 7-Day Renewal

### Initial Installation via Sideloadly
1. Must use iTunes & iCloud standalone x64 from Apple (NEVER Microsoft Store version).
2. Sideloadly: Drag `Runner.ipa` -> Enter secondary burner Apple ID -> Start -> Enter 2FA.
3. On iPhone:
   - Enable `Settings > Privacy & Security > Developer Mode`.
   - Trust certificate: `Settings > General > VPN & Device Management > Trust`.

### Untethered 7-Day Renewal via SideStore
1. Sideload `SideStore.ipa` using Sideloadly.
2. Generate pairing file on Windows: `tools\bin\jitterbugpair.exe` -> copy `<UDID>.mobiledevicepairing` to iPhone.
3. In SideStore: Pair file -> Set Anisette server (`https://sidestore.io/anisette`).
4. Connect to SideStore WireGuard loopback VPN.
5. SideStore re-signs apps on-device every 7 days without a computer.
6. AltSource: Add `https://USERNAME.github.io/REPO/apps.json` in SideStore Sources for wireless one-tap updates.

---

## Troubleshooting Guide

| Issue | Root Cause | Solution |
|---|---|---|
| `Building for iOS is only supported on macOS` | Attempted local build on Windows | Push to GitHub to trigger `build-ios-sideload.yml`. |
| `Generated.xcconfig: No such file or directory` | `pod install` executed before Flutter prep | Run `flutter pub get` followed by `flutter build ios --config-only` before `pod install`. |
| `Signing for "Runner" requires a development team` | Xcode 14+ codesign check on pods | Podfile `post_install` must set `CODE_SIGNING_ALLOWED = 'NO'`. |
| `Provisioning profile does not include expected entitlements` | Restricted entitlement in plist | Empty `Runner.entitlements` to `<dict></dict>`. |
| Silent crash when opening camera/location | Missing usage description | Add non-empty `NSCameraUsageDescription` etc. in `Info.plist`. |
| `Device not found` in Sideloadly / iproxy | Microsoft Store iTunes installed | Uninstall MS Store iTunes, install Apple direct standalone x64. |
| `MAX_APP_ID_EXCEEDED` | Changed Bundle ID frequently | Keep constant `com.yourname.appname` (10 App IDs per 7 rolling days). |
