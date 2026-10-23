import 'dart:io';
import 'package:flutter/material.dart';
import '../domain/overlay_state.dart';
import 'hint_wireframe_overlay.dart';
import 'secret_touch_zone_layer.dart';

/// Full-screen disguised camera interface stacking camera preview under a decoy wallpaper.
class CamouflagedStackWidget extends StatelessWidget {
  final Widget cameraPreview;
  final CameraOverlayState overlayState;
  final bool isRecording;
  final Duration elapsedDuration;
  final VoidCallback onStopDoubleTap;
  final VoidCallback onUnlockLongPress;
  final VoidCallback onSwitchLensDoubleTap;
  final VoidCallback onThreeFingerTap;

  const CamouflagedStackWidget({
    super.key,
    required this.cameraPreview,
    required this.overlayState,
    required this.isRecording,
    required this.elapsedDuration,
    required this.onStopDoubleTap,
    required this.onUnlockLongPress,
    required this.onSwitchLensDoubleTap,
    required this.onThreeFingerTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Layer 1 (Bottom): Live Camera Preview
            cameraPreview,

            // Layer 2: Decoy Mask (Wallpaper / Camouflage Image)
            Opacity(
              opacity: overlayState.opacity,
              child: _buildDecoyWallpaper(),
            ),

            // Layer 3: Visual Hints (Only visible when 3-finger tap enables it)
            HintWireframeOverlay(
              showHints: overlayState.showSecretHints,
              isRecording: isRecording,
              elapsedDuration: elapsedDuration,
            ),

            // Layer 4 (Top): Secret Gesture Detection Zones
            SecretTouchZoneLayer(
              onStopDoubleTap: onStopDoubleTap,
              onUnlockLongPress: onUnlockLongPress,
              onSwitchLensDoubleTap: onSwitchLensDoubleTap,
              onThreeFingerTap: onThreeFingerTap,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecoyWallpaper() {
    final path = overlayState.imagePath;
    if (path != null && path.isNotEmpty) {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: overlayState.fitMode,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => _buildFallbackWallpaper(),
        );
      }
    }
    return _buildFallbackWallpaper();
  }

  /// Elegant default lockscreen / notepad simulation when no custom photo is chosen.
  Widget _buildFallbackWallpaper() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0F2027),
            Color(0xFF203A43),
            Color(0xFF2C5364),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            StreamBuilder<DateTime>(
              stream: Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now()),
              builder: (context, snapshot) {
                final now = snapshot.data ?? DateTime.now();
                final hour = now.hour.toString().padLeft(2, '0');
                final min = now.minute.toString().padLeft(2, '0');
                return Column(
                  children: [
                    Text(
                      '$hour:$min',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 68,
                        fontWeight: FontWeight.w200,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_weekday(now.weekday)}, ${now.day} thg ${now.month}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                );
              },
            ),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: Text(
                'Vuốt lên để mở khóa',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _weekday(int d) {
    switch (d) {
      case DateTime.monday:
        return 'Thứ Hai';
      case DateTime.tuesday:
        return 'Thứ Ba';
      case DateTime.wednesday:
        return 'Thứ Tư';
      case DateTime.thursday:
        return 'Thứ Năm';
      case DateTime.friday:
        return 'Thứ Sáu';
      case DateTime.saturday:
        return 'Thứ Bảy';
      default:
        return 'Chủ Nhật';
    }
  }
}
