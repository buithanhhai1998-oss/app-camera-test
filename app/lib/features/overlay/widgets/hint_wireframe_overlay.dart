import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

/// Renders visual wireframe guide boxes indicating where secret touch zones are.
/// Active only when [showHints] is true (toggled by 3-finger tap).
class HintWireframeOverlay extends StatelessWidget {
  final bool showHints;
  final bool isRecording;
  final Duration elapsedDuration;
  final double opacity;
  final VoidCallback? onIncreaseOpacity;
  final VoidCallback? onDecreaseOpacity;
  final VoidCallback? onTogglePeekOpacity;

  const HintWireframeOverlay({
    super.key,
    required this.showHints,
    required this.isRecording,
    required this.elapsedDuration,
    this.opacity = 1.0,
    this.onIncreaseOpacity,
    this.onDecreaseOpacity,
    this.onTogglePeekOpacity,
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
              ),
            ),

            // Center Status & 3-Finger Dismiss Hint (Informational only, ignore touch)
            Positioned(
              bottom: 40,
              left: 40,
              right: 40,
              child: IgnorePointer(
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
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white12,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Che phủ: ${(opacity * 100).toInt()}%',
                                style: const TextStyle(color: Colors.tealAccent, fontSize: 11),
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
            ),

            // Bottom-Left Zone: Opacity Adjustment & Peek Mode (Interactive buttons)
            Positioned(
              bottom: 0,
              left: 0,
              width: zoneWidth * 1.15,
              height: zoneHeight * 1.15,
              child: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.tealAccent.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.tealAccent, width: 1.5),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Độ mờ che Cam (Opacity)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.tealAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Decrease opacity button (-) -> makes more transparent so camera is visible
                        InkWell(
                          key: const Key('btn_decrease_opacity'),
                          onTap: onDecreaseOpacity,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.tealAccent),
                            ),
                            child: const Icon(Icons.remove, color: Colors.tealAccent, size: 16),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            '${(opacity * 100).toInt()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Increase opacity button (+) -> makes more opaque / covered
                        InkWell(
                          key: const Key('btn_increase_opacity'),
                          onTap: onIncreaseOpacity,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.tealAccent),
                            ),
                            child: const Icon(Icons.add, color: Colors.tealAccent, size: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    InkWell(
                      key: const Key('btn_toggle_peek'),
                      onTap: onTogglePeekOpacity,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.6)),
                        ),
                        child: Text(
                          opacity >= 0.7 ? 'Nhìn xuyên (Peek)' : 'Che kín (100%)',
                          style: const TextStyle(color: Colors.tealAccent, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
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
