# CLAUDE.md — Flutter iOS Sideloading Workspace (Windows)

This document provides guidelines and commands for Claude Code when working in `D:\source\IOS`.

## Project Overview
A production Flutter iOS application developed strictly on a Windows workstation, built via GitHub Actions (`macos-14`), and deployed to physical iOS devices via Sideloading (SideStore / Sideloadly) using a Free Personal Apple ID.

## Local Environment & Session Commands
- Local tools and Flutter SDK reside in `D:\source\IOS\flutter` and `D:\source\IOS\tools\bin`.
- NEVER suggest modifying global Windows PATH or installing into `C:\Program Files`.
- To start a session with local Flutter in PATH:
  - CMD: `env.bat`
  - PowerShell: `. .\env.ps1`
- Static analysis & tests (Local Windows):
  - `cd app && flutter analyze`
  - `cd app && flutter test`
  - `cd app && flutter run -d <android-device>` (with `device_preview` for iOS UI simulation)
- iPhone Native Debugging (No Mac / Xcode):
  - Wi-Fi attach: `powershell tools/attach-wifi.ps1`
  - USB attach: `powershell tools/attach-usb.ps1`
  - Extract crash reports: `powershell tools/extract-crash-logs.ps1`

## Prohibited Actions & Strict Constraints
- NEVER run `flutter build ios` or `flutter build ipa` on Windows. All iOS builds MUST run via GitHub Actions.
- NEVER suggest running iOS Simulator on Windows.
- NEVER add the following packages to `pubspec.yaml`:
  - `firebase_messaging` (APNs blocked on Free Apple ID)
  - `sign_in_with_apple` (Entitlement blocked on Free Apple ID)
  - `flutter_inapp_purchase` (StoreKit unavailable)
  - Any iCloud, HomeKit, HealthKit, or NFC plugin.
- NEVER add restricted entitlements to `app/ios/Runner/Runner.entitlements`. Keep it as an empty dictionary `<dict></dict>` for Release builds.
- NEVER leave `NS...UsageDescription` strings blank in `app/ios/Runner/Info.plist`.

## Architecture & Whitelisted Patterns
- State & Storage: Local-First with `sqflite`, `drift`, `isar`, `hive_flutter`, or `shared_preferences`. Data is preserved across SideStore renewals and Sideloadly updates (same Bundle ID).
- Secure Storage: `flutter_secure_storage` in single-app mode only. Do NOT enable keychain sharing or App Groups.
- Real-time & Push: WebSocket (`web_socket_channel`) or `supabase_flutter` Realtime + `flutter_local_notifications` (replaces APNs).
- Authentication: `google_sign_in` or Supabase/Firebase email-password / OAuth.
- Mapping: `flutter_map` (OpenStreetMap) preferred over `google_maps_flutter` (avoids 150MB CocoaPods binary on CI).
- Crash Tracking: `sentry_flutter` or in-app `runZonedGuarded` logging.

## CI/CD Workflow
- Workflow: `.github/workflows/build-ios-sideload.yml`
- Runs on `macos-14` (Apple Silicon).
- Builds unsigned release (`flutter build ios --release --no-codesign`).
- Assembles `Payload/Runner.app` into `Runner.ipa`.
- Updates `altsource/apps.json` for SideStore self-hosted distribution on release tags.
