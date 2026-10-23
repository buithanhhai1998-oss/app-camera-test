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
            onOpacityTap: () {},
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
            onOpacityTap: () {},
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

    testWidgets('Tapping Bottom-Left zone triggers opacity cycle callback', (tester) async {
      bool opacityTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: CamouflagedStackWidget(
            cameraPreview: const SizedBox(),
            overlayState: const CameraOverlayState(),
            isRecording: false,
            elapsedDuration: Duration.zero,
            onStopDoubleTap: () {},
            onUnlockLongPress: () {},
            onSwitchLensDoubleTap: () {},
            onOpacityTap: () => opacityTriggered = true,
            onThreeFingerTap: () {},
          ),
        ),
      );

      final opacityFinder = find.byKey(const Key('secret_zone_opacity'));
      expect(opacityFinder, findsOneWidget);

      await tester.tap(opacityFinder);
      await tester.pumpAndSettle();

      expect(opacityTriggered, isTrue);
    });

    testWidgets('Hint wireframe shows opacity adjustment buttons [+] and [-]', (tester) async {
      bool increased = false;
      bool decreased = false;
      bool peekToggled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HintWireframeOverlay(
              showHints: true,
              isRecording: true,
              elapsedDuration: const Duration(seconds: 10),
              opacity: 0.8,
              onIncreaseOpacity: () => increased = true,
              onDecreaseOpacity: () => decreased = true,
              onTogglePeekOpacity: () => peekToggled = true,
            ),
          ),
        ),
      );

      expect(find.textContaining('80%'), findsNWidgets(2));
      expect(find.byKey(const Key('btn_decrease_opacity')), findsOneWidget);
      expect(find.byKey(const Key('btn_increase_opacity')), findsOneWidget);
      expect(find.byKey(const Key('btn_toggle_peek')), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn_decrease_opacity')));
      expect(decreased, isTrue);

      await tester.tap(find.byKey(const Key('btn_increase_opacity')));
      expect(increased, isTrue);

      await tester.tap(find.byKey(const Key('btn_toggle_peek')));
      expect(peekToggled, isTrue);
    });
  });
}
