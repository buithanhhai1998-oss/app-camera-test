---
name: flutter-clean-code
description: Enforce Clean Architecture, Local-First data persistence, state management patterns, and robust coding standards for Flutter applications. Use when writing, refactoring, or reviewing Flutter widgets, models, repositories, local databases, or async business logic.
---

# Flutter Clean Architecture & Coding Standards

Guide the design, structure, and implementation of Flutter applications with an emphasis on **Clean Architecture, Local-First persistence, and clean separation of concerns**.

## 1. Architectural Layers (Clean Separation)

Structure the code under `lib/` following clear boundaries:

```
lib/
├── core/                  # Shared utilities, constants, theme, error handling
│   ├── errors/            # Failure and Exception classes
│   ├── network/           # Dio / HTTP client wrapper
│   └── utils/             # Formatters, helpers
├── data/                  # Data Layer: Data sources, Models, Repositories impl
│   ├── datasources/       # Local (SQLite/Hive) & Remote (API/WebSocket)
│   ├── models/            # JSON serialization models (immutable)
│   └── repositories/      # Repository implementations
├── domain/                # Domain Layer: Entities, Repository interfaces, Use Cases
│   ├── entities/          # Pure Dart business objects
│   └── repositories/      # Abstract repository contracts
└── presentation/          # Presentation Layer: Widgets, Screens, State Controllers
    ├── controllers/       # State Notifiers / BLoCs / Cubits / Providers
    ├── screens/           # Full screen views
    └── widgets/           # Reusable UI components
```

## 2. Local-First Persistence Pattern

Because sideloaded iOS apps may operate offline and must preserve user data across 7-day re-sign cycles:
1. **Source of Truth**: Local SQLite (`sqflite` / `drift`) is the primary source of truth.
2. **Read Flow**: UI always observes/reads from the local database or reactive stream.
3. **Write Flow**: Write to local DB first -> update UI -> attempt background remote sync -> update sync status flag.
4. **Data Isolation**: Never hardcode file paths. Always use `path_provider` (`getApplicationDocumentsDirectory()`) to resolve directories within the iOS app sandbox.
5. **Secure Storage**: Use `flutter_secure_storage` exclusively for tokens, API keys, and sensitive auth data in single-app mode (never enable keychain sharing).

## 3. State Management Best Practices
- **Separation**: Never place database queries, HTTP requests, or business logic inside `StatefulWidget.build()` or `initState()`.
- **State Flow**:
  - `InitialState` -> `LoadingState` -> `LoadedState(data)` / `ErrorState(message)`.
- **Immutability**: Use immutable state classes (e.g. `freezed` or standard immutable Dart classes with `copyWith()`).
- **Disposal**: Always override `dispose()` to close `StreamController`, `TextEditingController`, `AnimationController`, `ScrollController`, and cancel `StreamSubscription`.

## 4. UI & Cupertino Responsiveness
- **iOS Adaptation**: Wrap top-level apps in `DevicePreview` during development to simulate iPhone screens and Safe Areas.
- **Adaptive Controls**: Use adaptive or Cupertino widgets when targeting iOS (`CupertinoActivityIndicator`, Cupertino page transitions).
- **Safe Area**: Always wrap scaffold bodies in `SafeArea` to prevent content clipping behind Dynamic Island, notch, or Home Indicator bar.
- **Scroll Physics**: Use `BouncingScrollPhysics()` on iOS to adhere to platform feel.

## 5. Error Handling & Guardrails
- **Uncaught Error Boundary**: Always wrap `main()` in `runZonedGuarded` and set `FlutterError.onError`:
  ```dart
  void main() {
    runZonedGuarded(() async {
      WidgetsFlutterBinding.ensureInitialized();
      runApp(const MyApp());
    }, (error, stack) {
      debugPrint('[FATAL] $error');
      // Forward to Sentry or local logger
    });
  }
  ```
- **Async Safety**: Always verify `if (!mounted) return;` after `await` in `StatefulWidget` callbacks before invoking `setState()` or `Navigator`.
