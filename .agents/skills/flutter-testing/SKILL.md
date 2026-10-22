---
name: flutter-testing
description: Comprehensive testing guidelines for Flutter applications on Windows without requiring macOS or physical iOS devices. Covers unit testing, widget testing, mocking native iOS platform channels (SQLite, Keychain, Biometrics), test coverage, and test execution. Use when writing, debugging, or running Flutter tests.
---

# Flutter Testing & Verification Guide (Windows Workstation)

Guide the implementation of robust automated tests for Flutter applications. Emphasize testing business logic, state management, and UI rendering **locally on Windows without requiring Xcode or physical Apple hardware**.

## 1. Test Pyramid & Scope

1. **Unit Tests (`test/unit/`)**: Test pure Dart domain entities, use cases, models serialization, and repository logic. Fast, zero-dependency.
2. **Widget Tests (`test/widgets/`)**: Test UI rendering, user interactions (tap, scroll, enter text), responsive layouts, and state transitions using `testWidgets`.
3. **Integration / Architecture Tests (`test/integration/`)**: Test full feature flows with mock data sources.

## 2. Mocking Native iOS Platform Channels

On Windows, native iOS plugins (`local_auth`, `sqflite`, `flutter_secure_storage`, `flutter_local_notifications`) do not have native iOS runtimes. **Mock their interfaces or channel responses** using `mocktail` or `mockito`:

### Mocking `sqflite` (In-memory testing)
Use `sqflite_common_ffi` for executing real SQLite queries inside desktop unit tests without requiring device simulators:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('Database inserts and queries correctly', () async {
    final db = await openDatabase(inMemoryDatabasePath, version: 1, onCreate: (db, v) async {
      await db.execute('CREATE TABLE items (id INTEGER PRIMARY KEY, name TEXT)');
    });
    await db.insert('items', {'id': 1, 'name': 'Test'});
    final result = await db.query('items');
    expect(result.first['name'], 'Test');
    await db.close();
  });
}
```

### Mocking `flutter_secure_storage`
Override the platform interface with an in-memory mock:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MockSecureStorage extends FlutterSecureStorage {
  final Map<String, String> _data = {};

  @override
  Future<void> write({required String key, required String? value, ...}) async {
    if (value != null) _data[key] = value;
  }

  @override
  Future<String?> read({required String key, ...}) async => _data[key];

  @override
  Future<void> delete({required String key, ...}) async => _data.remove(key);
}
```

### Mocking `local_auth` (Biometrics)
Mock `LocalAuthentication` so tests pass deterministically without physical Face ID hardware:
```dart
import 'package:mocktail/mocktail.dart';
import 'package:local_auth/local_auth.dart';

class MockLocalAuthentication extends Mock implements LocalAuthentication {}

void main() {
  test('Authentication succeeds when biometrics match', () async {
    final auth = MockLocalAuthentication();
    when(() => auth.canCheckBiometrics).thenAnswer((_) async => true);
    when(() => auth.authenticate(
      localizedReason: any(named: 'localizedReason'),
      options: any(named: 'options'),
    )).thenAnswer((_) async => true);

    final success = await auth.authenticate(localizedReason: 'Test');
    expect(success, isTrue);
  });
}
```

## 3. Widget Testing Best Practices
- **Wrapper**: Always wrap the tested widget in `MaterialApp` or `CupertinoApp` with a `Scaffold` and `Directionality`.
- **Finding Elements**: Prefer `find.byKey()`, `find.byType()`, and `find.text()`.
- **Pumping Frames**:
  - `tester.pump()`: Triggers a single frame rebuild.
  - `tester.pumpAndSettle()`: Repeatedly pumps frames until there are no scheduled frame requests (e.g. animations settle). Beware of infinite animations (`CircularProgressIndicator`), use `pump(Duration)` instead.
- **Async Interactions**: Always `await tester.tap(...)` and then `await tester.pumpAndSettle()`.

## 4. Test Execution on Windows

Run tests via the localized session script:
```powershell
# Open local environment session
. .\env.ps1
Set-Location app

# Run all unit and widget tests
flutter test

# Run tests with code coverage report
flutter test --coverage

# Run a specific test file
flutter test test/widgets/home_screen_test.dart
```

Ensure all tests pass with 0 failures before pushing code to GitHub for CI/CD compilation.
