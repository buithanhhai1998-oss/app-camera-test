import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

/// Renders visual wireframe guide boxes indicating where secret touch zones are.
/// Active only when [showHints] is true (toggled by 3-finger tap).
class HintWireframeOverlay extends StatelessWidget {
  final bool showHints;
  final bool isRecording;
  final Duration elapsedDuration;

  const HintWireframeOverlay({
    super.key,
    required this.showHints,
    required this.isRecording,
    required this.elapsedDuration,
  });

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (!showHints) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;

        final zoneWidth = screenWidth * AppConstants.stopZoneWidthRatio;
        final zoneHeight = screenHeight * AppConstants.stopZoneHeightRatio;

        return Stack(
          children: [
            // Top-Left Zone: Unlock Vault (Long Press 2s)
            Positioned(
              top: 0,
              left: 0,
              width: zoneWidth,
              height: zoneHeight,
              child: _buildZoneBox(
                color: Colors.amberAccent,
                icon: Icons.lock_open,
                label: 'Giữ 2s mở Khóa / Cài đặt\n(Hold 2s Unlock)',
                alignment: Alignment.topLeft,
              ),
            ),

            // Top-Right Zone: Stop & Save (Double Tap)
            Positioned(
              top: 0,
              right: 0,
              width: zoneWidth,
              height: zoneHeight,
              child: _buildZoneBox(
                color: Colors.redAccent,
                icon: Icons.stop_circle_outlined,
                label: 'Nhấp đúp Dừng & Lưu\n(Double Tap Stop)',
                alignment: Alignment.topRight,
              ),
            ),

            // Bottom-Right Zone: Switch Lens (Double Tap)
            Positioned(
              bottom: 0,
              right: 0,
              width: zoneWidth,
              height: zoneHeight,
              child: _buildZoneBox(
                color: Colors.cyanAccent,
                icon: Icons.flip_camera_ios_outlined,
                label: 'Nhấp đúp Đổi Cam\n(Double Tap Flip)',
                alignment: Alignment.bottomRight,
              ),
            ),

            // Center Status & 3-Finger Dismiss Hint
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isRecording ? Colors.redAccent : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isRecording
                                ? 'REC ${_formatDuration(elapsedDuration)}'
                                : 'STANDBY',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Chạm 3 ngón tay để ẩn hoàn toàn các viền này',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildZoneBox({
    required Color color,
    required IconData icon,
    required String label,
    required Alignment alignment,
  }) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
