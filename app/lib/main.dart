import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:local_auth/local_auth.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

final FlutterLocalNotificationsPlugin _notificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize local notifications safely
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const InitializationSettings initializationSettings =
        InitializationSettings(
      iOS: initializationSettingsDarwin,
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _notificationsPlugin.initialize(initializationSettings);

    runApp(
      DevicePreview(
        enabled: !kReleaseMode && !kIsWeb,
        builder: (context) => const SideloadApp(),
      ),
    );
  }, (error, stack) {
    debugPrint('[UNCAUGHT ERROR] $error');
    debugPrint(stack.toString());
  });
}

class SideloadApp extends StatelessWidget {
  const SideloadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sideload iOS App',
      debugShowCheckedModeBanner: false,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      theme: ThemeData(
        platform: TargetPlatform.iOS,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _secureStorage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();

  String _statusMessage = 'System Ready';
  int _counter = 0;
  Database? _database;

  @override
  void initState() {
    super.initState();
    _initDatabase();
    _loadSecureCounter();
  }

  Future<void> _initDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = p.join(dbPath, 'sideload_demo.db');
      _database = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          await db.execute(
            'CREATE TABLE records (id INTEGER PRIMARY KEY, title TEXT, created_at TEXT)',
          );
        },
      );
      final count = Sqflite.firstIntValue(
        await _database!.rawQuery('SELECT COUNT(*) FROM records'),
      );
      setState(() {
        _statusMessage = 'SQLite connected: $count records stored.';
      });
    } catch (e) {
      setState(() => _statusMessage = 'SQLite Error: $e');
    }
  }

  Future<void> _loadSecureCounter() async {
    final value = await _secureStorage.read(key: 'launch_counter');
    final parsed = int.tryParse(value ?? '0') ?? 0;
    setState(() => _counter = parsed);
  }

  Future<void> _incrementSecureCounter() async {
    final next = _counter + 1;
    await _secureStorage.write(key: 'launch_counter', value: next.toString());
    if (_database != null) {
      await _database!.insert('records', {
        'title': 'Action #$next',
        'created_at': DateTime.now().toIso8601String(),
      });
    }
    setState(() {
      _counter = next;
      _statusMessage = 'Saved record #$next to SQLite and Keychain.';
    });
  }

  Future<void> _testBiometrics() async {
    try {
      final canAuth = await _localAuth.canCheckBiometrics;
      if (!canAuth) {
        setState(() => _statusMessage = 'Biometrics not available on this device.');
        return;
      }
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Test Face ID / Touch ID verification',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      setState(() {
        _statusMessage = authenticated
            ? '✅ Face ID / Touch ID Verified!'
            : '❌ Biometrics cancelled.';
      });
    } catch (e) {
      setState(() => _statusMessage = 'Biometric Error: $e');
    }
  }

  Future<void> _triggerLocalNotification() async {
    const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const NotificationDetails details = NotificationDetails(
      iOS: darwinDetails,
      android: AndroidNotificationDetails('default', 'Default Channel'),
    );
    await _notificationsPlugin.show(
      0,
      'Sideload Alert',
      'Local notifications work 100% without APNs!',
      details,
    );
    setState(() => _statusMessage = 'Local Notification Dispatched.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter iOS on Windows'),
        backgroundColor: CupertinoColors.systemBackground,
        elevation: 0.5,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: CupertinoColors.secondarySystemBackground,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Target Status',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text('Platform: ${defaultTargetPlatform.name}'),
                      Text('Keychain Action Count: $_counter'),
                      const SizedBox(height: 8),
                      Text(
                        _statusMessage,
                        style: const TextStyle(color: Colors.blueAccent),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Write to SQLite + Keychain'),
                onPressed: _incrementSecureCounter,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.fingerprint),
                label: const Text('Test Face ID / Touch ID'),
                onPressed: _testBiometrics,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.notifications_active),
                label: const Text('Trigger Local Notification (No APNs)'),
                onPressed: _triggerLocalNotification,
              ),
              const Spacer(),
              const Center(
                child: Text(
                  'Data is preserved across 7-day SideStore renewals.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
