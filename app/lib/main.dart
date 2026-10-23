import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:device_preview/device_preview.dart';
import 'app.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    runApp(
      ProviderScope(
        child: DevicePreview(
          enabled: !kReleaseMode && kDebugMode && false, // Can toggle true for interactive device preview
          builder: (context) => const App(),
        ),
      ),
    );
  }, (error, stack) {
    debugPrint('[UNCAUGHT ERROR] $error');
    debugPrint(stack.toString());
  });
}
