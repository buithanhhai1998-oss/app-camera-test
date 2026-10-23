import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

/// Invisible touch zone layer that captures secret gestures across the screen.
class SecretTouchZoneLayer extends StatefulWidget {
  final VoidCallback onStopDoubleTap;
  final VoidCallback onUnlockLongPress;
  final VoidCallback onSwitchLensDoubleTap;
  final VoidCallback onThreeFingerTap;
  final Widget? child;

  const SecretTouchZoneLayer({
    super.key,
    required this.onStopDoubleTap,
    required this.onUnlockLongPress,
    required this.onSwitchLensDoubleTap,
    required this.onThreeFingerTap,
    this.child,
  });

  @override
  State<SecretTouchZoneLayer> createState() => _SecretTouchZoneLayerState();
}

class _SecretTouchZoneLayerState extends State<SecretTouchZoneLayer> {
  final Set<int> _activePointers = {};
  bool _threeFingerTriggered = false;

  void _handlePointerDown(PointerDownEvent event) {
    _activePointers.add(event.pointer);
    if (_activePointers.length >= 3 && !_threeFingerTriggered) {
      _threeFingerTriggered = true;
      widget.onThreeFingerTap();
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    _activePointers.remove(event.pointer);
    if (_activePointers.isEmpty) {
      _threeFingerTriggered = false;
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _activePointers.remove(event.pointer);
    if (_activePointers.isEmpty) {
      _threeFingerTriggered = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handlePointerDown,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerCancel,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;

          final zoneWidth = screenWidth * AppConstants.stopZoneWidthRatio;
          final zoneHeight = screenHeight * AppConstants.stopZoneHeightRatio;

          return Stack(
            children: [
              if (widget.child != null) widget.child!,

              // Top-Left: Unlock Vault / Settings (Long Press 2 seconds)
              Positioned(
                top: 0,
                left: 0,
                width: zoneWidth,
                height: zoneHeight,
                child: GestureDetector(
                  key: const Key('secret_zone_unlock'),
                  behavior: HitTestBehavior.opaque,
                  onLongPress: widget.onUnlockLongPress,
                  child: const ColoredBox(color: Colors.transparent),
                ),
              ),

              // Top-Right: Stop & Save (Double Tap)
              Positioned(
                top: 0,
                right: 0,
                width: zoneWidth,
                height: zoneHeight,
                child: GestureDetector(
                  key: const Key('secret_zone_stop'),
                  behavior: HitTestBehavior.opaque,
                  onDoubleTap: widget.onStopDoubleTap,
                  child: const ColoredBox(color: Colors.transparent),
                ),
              ),

              // Bottom-Right: Switch Lens (Double Tap)
              Positioned(
                bottom: 0,
                right: 0,
                width: zoneWidth,
                height: zoneHeight,
                child: GestureDetector(
                  key: const Key('secret_zone_switch_lens'),
                  behavior: HitTestBehavior.opaque,
                  onDoubleTap: widget.onSwitchLensDoubleTap,
                  child: const ColoredBox(color: Colors.transparent),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
