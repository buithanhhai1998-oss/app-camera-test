# Antigravity Project Rules: Flutter iOS Sideload (Windows)

You are operating inside the `D:\source\IOS` workspace.

## Hard Constraints
- **NO LOCAL iOS BUILDS**: `flutter build ios` and `flutter build ipa` are strictly forbidden on Windows. All iOS packaging is performed on GitHub Actions `macos-14` runner.
- **NO GLOBAL POLLUTION**: All tools, Flutter SDK, and scripts must reside strictly in `D:\source\IOS`. Do not install tools to Windows global PATH or `C:\Program Files`.
- **FORBIDDEN PACKAGES**:
  - `firebase_messaging` (APNs blocked on Free Apple ID)
  - `sign_in_with_apple` (Entitlement blocked on Free Apple ID)
  - `flutter_inapp_purchase` (StoreKit blocked on sideload)
  - Any iCloud, HomeKit, HealthKit, or NFC plugin.
- **FORBIDDEN ENTITLEMENTS**:
  - `Runner.entitlements` must be an empty dictionary `<dict></dict>` for Release builds.
- **INFO.PLIST SAFETY**:
  - Never leave usage descriptions blank. Always include `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSLocationWhenInUseUsageDescription`, `NSFaceIDUsageDescription`, `NSMicrophoneUsageDescription`.
  - Set `ITSAppUsesNonExemptEncryption = false`.
- **LOCAL DEV & DEBUG LOOP**:
  - UI & Logic (90%): Android Emulator with `device_preview` and `ThemeData(platform: TargetPlatform.iOS)`. Never suggest iOS Simulator on Windows.
  - Native iOS Hot Reload:
    - Wi-Fi: `powershell tools/attach-wifi.ps1`
    - USB: `powershell tools/attach-usb.ps1` (uses local `tools/bin/iproxy.exe`)
- **DATA PRESERVATION**:
  - Keep `CFBundleIdentifier` constant. Updating via Sideloadly or SideStore preserves SQLite, Keychain, and Documents data 100% as long as the app is not manually deleted.
