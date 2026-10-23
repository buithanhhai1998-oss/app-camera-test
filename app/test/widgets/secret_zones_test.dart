import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sideload_app/features/overlay/domain/overlay_state.dart';
import 'package:flutter_sideload_app/features/overlay/widgets/camouflaged_stack_widget.dart';
import 'package:flutter_sideload_app/features/overlay/widgets/hint_wireframe_overlay.dart';

void main() {
  group('SecretTouchZoneLayer & CamouflagedStackWidget Tests', () {
    testWidgets('Double-tapping Top-Right zone triggers stop callback', (tester) async {
      bool stopTriggered = false;
      bool unlockTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: CamouflagedStackWidget(
            cameraPreview: const SizedBox(),
            overlayState: const CameraOverlayState(),
            isRecording: true,
            elapsedDuration: const Duration(seconds: 15),
            onStopDoubleTap: () => stopTriggered = true,
            onUnlockLongPress: () => unlockTriggered = true,
            onSwitchLensDoubleTap: () {},
            onThreeFingerTap: () {},
          ),
        ),
      );

      // Locate Top-Right stop zone
      final stopFinder = find.byKey(const Key('secret_zone_stop'));
      expect(stopFinder, findsOneWidget);

      // Simulate double tap
      await tester.tap(stopFinder);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(stopFinder);
      await tester.pumpAndSettle();

      expect(stopTriggered, isTrue);
      expect(unlockTriggered, isFalse);
    });

    testWidgets('Long-pressing Top-Left zone triggers unlock callback', (tester) async {
      bool unlockTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: CamouflagedStackWidget(
            cameraPreview: const SizedBox(),
            overlayState: const CameraOverlayState(),
            isRecording: false,
            elapsedDuration: Duration.zero,
            onStopDoubleTap: () {},
            onUnlockLongPress: () => unlockTriggered = true,
            onSwitchLensDoubleTap: () {},
            onThreeFingerTap: () {},
          ),
        ),
      );

      final unlockFinder = find.byKey(const Key('secret_zone_unlock'));
      expect(unlockFinder, findsOneWidget);

      // Simulate long press
      await tester.longPress(unlockFinder);
      await tester.pumpAndSettle();

      expect(unlockTriggered, isTrue);
    });

    testWidgets('Hint wireframe is hidden when showSecretHints is false and visible when true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HintWireframeOverlay(
              showHints: false,
              isRecording: true,
              elapsedDuration: Duration(seconds: 10),
            ),
          ),
        ),
      );

      // Hints should not be rendered
      expect(find.textContaining('Nhấp đúp Dừng & Lưu'), findsNothing);

      // Now set showHints = true
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HintWireframeOverlay(
              showHints: true,
              isRecording: true,
              elapsedDuration: Duration(seconds: 10),
            ),
          ),
        ),
      );

      // Wireframe guide text and status must now be rendered
      expect(find.textContaining('Nhấp đúp Dừng & Lưu'), findsOneWidget);
      expect(find.textContaining('Giữ 2s mở Khóa'), findsOneWidget);
      expect(find.textContaining('REC 00:10'), findsOneWidget);
    });
  });
}
