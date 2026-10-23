import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/camera/presentation/camera_screen.dart';

/// Root Application Widget.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Camera',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const CameraScreen(),
    );
  }
}
