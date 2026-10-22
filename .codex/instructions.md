# OpenAI Codex Instructions: Flutter iOS Sideload (Windows)

Target Environment: Windows 11 workstation, Free Apple ID developer, Sideloading distribution via SideStore & Sideloadly.

## Instructions:
1. All iOS compilation must be offloaded to GitHub Actions (`macos-14`). Never attempt or suggest executing `flutter build ios` on Windows.
2. Local tool execution must use the session wrapper `.\env.bat` or `. .\env.ps1`. Do not install tools to global system directories.
3. Package filtering:
   - REJECT: `firebase_messaging`, `sign_in_with_apple`, `flutter_inapp_purchase`, iCloud, HomeKit, HealthKit, NFC plugins.
   - ACCEPT: `sqflite`, `drift`, `isar`, `hive_flutter`, `shared_preferences`, `flutter_secure_storage` (single-app only), `web_socket_channel`, `supabase_flutter`, `flutter_local_notifications`, `local_auth`, `flutter_map`, `sentry_flutter`.
4. Entitlements: `app/ios/Runner/Runner.entitlements` must be `<dict></dict>` for Release builds.
5. Info.plist: Every accessed hardware permission must have an explicit non-empty description.
6. Debugging: Use `tools/attach-wifi.ps1` or `tools/attach-usb.ps1` for Hot Reload directly onto physical iPhones from Windows.
