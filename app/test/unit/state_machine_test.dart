import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sideload_app/features/recording/domain/recording_state.dart';
import 'package:flutter_sideload_app/features/recording/presentation/recording_controller.dart';
import 'package:flutter_sideload_app/features/overlay/presentation/overlay_controller.dart';
import 'package:flutter_sideload_app/core/utilities/haptic_feedback_service.dart';

class MockHapticFeedbackService extends HapticFeedbackService {
  int startPulses = 0;
  int stopPulses = 0;
  int errorPulses = 0;
  int selectionClicks = 0;

  @override
  Future<void> startRecordingPulse() async {
    startPulses++;
  }

  @override
  Future<void> stopRecordingPulse() async {
    stopPulses++;
  }

  @override
  Future<void> errorPulse() async {
    errorPulses++;
  }

  @override
  Future<void> selectionClick() async {
    selectionClicks++;
  }
}

void main() {
  group('RecordingState & RecordingController Finite State Machine Tests', () {
    late MockHapticFeedbackService mockHaptic;
    late RecordingController controller;

    setUp(() {
      mockHaptic = MockHapticFeedbackService();
      controller = RecordingController(haptic: mockHaptic);
    });

    tearDown(() {
      controller.dispose();
    });

    test('Initial state is idle with 0 duration', () {
      expect(controller.state.status, equals(RecordingStatus.idle));
      expect(controller.state.elapsedDuration, equals(Duration.zero));
      expect(controller.state.isRecording, isFalse);
      expect(controller.state.canStart, isTrue);
      expect(controller.state.canStop, isFalse);
    });

    test('Transitions from idle to ready when camera preview initializes', () {
      controller.setReady();
      expect(controller.state.status, equals(RecordingStatus.ready));
      expect(controller.state.canStart, isTrue);
    });

    test('Starts recording successfully from ready state and triggers haptic pulse', () async {
      controller.setReady();
      final success = await controller.startRecording(destinationPath: '/path/video.mp4');

      expect(success, isTrue);
      expect(controller.state.status, equals(RecordingStatus.recording));
      expect(controller.state.isRecording, isTrue);
      expect(controller.state.currentFilePath, equals('/path/video.mp4'));
      expect(mockHaptic.startPulses, equals(1));
    });

    test('Rejects starting a new recording if already recording and fires error pulse', () async {
      controller.setReady();
      await controller.startRecording(destinationPath: '/path/video.mp4');
      
      // Attempt to start again while currently recording
      final duplicateStart = await controller.startRecording(destinationPath: '/path/video2.mp4');

      expect(duplicateStart, isFalse);
      expect(mockHaptic.errorPulses, equals(1));
      expect(controller.state.status, equals(RecordingStatus.recording));
      expect(controller.state.currentFilePath, equals('/path/video.mp4'));
    });

    test('Stops recording gracefully and triggers 2 stop haptic pulses', () async {
      controller.setReady();
      await controller.startRecording(destinationPath: '/path/video.mp4');
      
      final savedPath = await controller.stopRecording();

      expect(savedPath, equals('/path/video.mp4'));
      expect(controller.state.status, equals(RecordingStatus.saved));
      expect(controller.state.isRecording, isFalse);
      expect(mockHaptic.stopPulses, equals(1));
    });

    test('Rejects stopping if not actively recording', () async {
      controller.setReady();
      final savedPath = await controller.stopRecording();

      expect(savedPath, isNull);
      expect(mockHaptic.errorPulses, equals(1));
    });

    test('Handles system interruption properly', () async {
      controller.setReady();
      await controller.startRecording(destinationPath: '/path/interrupted.mp4');

      controller.handleInterruption('App entered background');

      expect(controller.state.status, equals(RecordingStatus.interrupted));
      expect(controller.state.isRecording, isFalse);
      expect(controller.state.errorMessage, contains('background'));
    });

    test('Handles error transition and triggers alarm pulse', () async {
      await controller.setError('Camera hardware lock failed');

      expect(controller.state.status, equals(RecordingStatus.error));
      expect(controller.state.errorMessage, equals('Camera hardware lock failed'));
      expect(mockHaptic.errorPulses, equals(1));
    });
  });

  group('CameraOverlayState & OverlayController Tests', () {
    late MockHapticFeedbackService mockHaptic;
    late OverlayController overlayController;

    setUp(() {
      mockHaptic = MockHapticFeedbackService();
      overlayController = OverlayController(haptic: mockHaptic);
    });

    test('Initial overlay defaults have full disguise opacity and auto-record enabled', () {
      expect(overlayController.state.opacity, equals(1.0));
      expect(overlayController.state.fitMode, equals(BoxFit.cover));
      expect(overlayController.state.showSecretHints, isFalse);
      expect(overlayController.state.isAutoRecordOnLaunch, isTrue);
      expect(overlayController.state.isVaultUnlocked, isFalse);
    });

    test('Toggles secret hints on 3-finger gesture with click haptic', () async {
      expect(overlayController.state.showSecretHints, isFalse);
      
      await overlayController.toggleSecretHints();
      expect(overlayController.state.showSecretHints, isTrue);
      expect(mockHaptic.selectionClicks, equals(1));

      await overlayController.toggleSecretHints();
      expect(overlayController.state.showSecretHints, isFalse);
      expect(mockHaptic.selectionClicks, equals(2));
    });

    test('Clamps opacity correctly between 0.0 and 1.0', () async {
      await overlayController.setOpacity(1.5);
      expect(overlayController.state.opacity, equals(1.0));

      await overlayController.setOpacity(-0.2);
      expect(overlayController.state.opacity, equals(0.0));

      await overlayController.setOpacity(0.65);
      expect(overlayController.state.opacity, equals(0.65));
    });

    test('Sets and changes vault unlock state', () {
      overlayController.setVaultUnlocked(true);
      expect(overlayController.state.isVaultUnlocked, isTrue);

      overlayController.setVaultUnlocked(false);
      expect(overlayController.state.isVaultUnlocked, isFalse);
    });

    test('Increase and decrease opacity step methods', () async {
      await overlayController.setOpacity(0.5);
      expect(overlayController.state.opacity, equals(0.5));

      await overlayController.increaseOpacity(0.2);
      expect(overlayController.state.opacity, closeTo(0.7, 0.001));

      await overlayController.decreaseOpacity(0.3);
      expect(overlayController.state.opacity, closeTo(0.4, 0.001));
    });

    test('togglePeekOpacity switches between 1.0 and 0.35', () async {
      await overlayController.setOpacity(1.0);
      await overlayController.togglePeekOpacity();
      expect(overlayController.state.opacity, equals(0.35));

      await overlayController.togglePeekOpacity();
      expect(overlayController.state.opacity, equals(1.0));
    });

    test('cycleOpacity cycles across 4 presets', () async {
      await overlayController.setOpacity(1.0);
      await overlayController.cycleOpacity();
      expect(overlayController.state.opacity, equals(0.65));

      await overlayController.cycleOpacity();
      expect(overlayController.state.opacity, equals(0.35));

      await overlayController.cycleOpacity();
      expect(overlayController.state.opacity, equals(0.10));

      await overlayController.cycleOpacity();
      expect(overlayController.state.opacity, equals(1.0));
    });
  });
}
