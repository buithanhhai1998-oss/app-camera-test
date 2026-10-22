---
name: flutter-ios-sideload-rule
description: Enforce Windows Flutter iOS Sideloading architectural constraints, package whitelists, and debug workflows.
trigger: always_on
---

# Flutter iOS Sideloading Architecture Rule

## Execution Policies
1. **Compilation Boundaries**:
   - `xcodebuild` and `flutter build ios` require Darwin kernel; they fail on Windows.
   - Any instruction that involves compiling `.ipa` or `.app` must be mapped to GitHub Actions `.github/workflows/build-ios-sideload.yml`.
2. **Package Filtering**:
   - Reject `firebase_messaging` -> Direct to `web_socket_channel` / `supabase_flutter` Realtime + `flutter_local_notifications`.
   - Reject `sign_in_with_apple` -> Direct to `google_sign_in` or OAuth2 / email-password.
   - Restrict `flutter_secure_storage` to single-app mode (no keychain sharing or App Groups).
3. **Local Tooling**:
   - All tools are contained within `D:\source\IOS`. Use `env.bat` or `env.ps1` for terminal sessions.
4. **Hardware Testing & Hot Reload**:
   - Wi-Fi attach: `powershell tools/attach-wifi.ps1`
   - USB attach: `powershell tools/attach-usb.ps1`
