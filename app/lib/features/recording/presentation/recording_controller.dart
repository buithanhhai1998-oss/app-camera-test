import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utilities/haptic_feedback_service.dart';
import '../domain/recording_state.dart';

/// StateNotifier that enforces finite state transitions for video recording.
class RecordingController extends StateNotifier<RecordingState> {
  final HapticFeedbackService _haptic;
  Timer? _timer;

  RecordingController({HapticFeedbackService? haptic})
      : _haptic = haptic ?? const HapticFeedbackService(),
        super(const RecordingState());

  /// Public getters avoiding protected state member warnings.
  RecordingState get currentState => state;
  RecordingStatus get currentStatus => state.status;
  bool get isRecording => state.isRecording;
  bool get canStart => state.canStart;
  bool get canStop => state.canStop;
  Duration get elapsedDuration => state.elapsedDuration;
  String? get currentFilePath => state.currentFilePath;

  /// Sets state to ready when camera preview is successfully initialized.
  void setReady() {
    if (state.status == RecordingStatus.recording || state.status == RecordingStatus.stopping) {
      return;
    }
    state = state.copyWith(status: RecordingStatus.ready, errorMessage: null);
  }

  /// Begins video recording session with haptic confirmation.
  Future<bool> startRecording({String? destinationPath}) async {
    if (!state.canStart) {
      await _haptic.errorPulse();
      return false;
    }

    state = state.copyWith(
      status: RecordingStatus.recording,
      elapsedDuration: Duration.zero,
      currentFilePath: destinationPath,
      errorMessage: null,
    );

    _startTimer();
    await _haptic.startRecordingPulse();
    return true;
  }

  /// Stops current recording session with haptic confirmation.
  Future<String?> stopRecording() async {
    if (!state.canStop) {
      await _haptic.errorPulse();
      return null;
    }

    _stopTimer();
    state = state.copyWith(status: RecordingStatus.stopping);

    final String? savedPath = state.currentFilePath;

    state = state.copyWith(
      status: RecordingStatus.saved,
      currentFilePath: savedPath,
    );

    await _haptic.stopRecordingPulse();
    return savedPath;
  }

  /// Marks session as interrupted (e.g. app backgrounded, incoming phone call, thermal limit).
  void handleInterruption([String? reason]) {
    _stopTimer();
    state = state.copyWith(
      status: RecordingStatus.interrupted,
      errorMessage: reason ?? 'Recording session interrupted by system',
    );
  }

  /// Sets error state and gives alarm haptic feedback.
  Future<void> setError(String message) async {
    _stopTimer();
    state = state.copyWith(
      status: RecordingStatus.error,
      errorMessage: message,
    );
    await _haptic.errorPulse();
  }

  /// Reset to idle state.
  void reset() {
    _stopTimer();
    state = const RecordingState();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.status == RecordingStatus.recording) {
        state = state.copyWith(
          elapsedDuration: state.elapsedDuration + const Duration(seconds: 1),
        );
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}

/// Riverpod provider for the RecordingController.
final recordingControllerProvider =
    StateNotifierProvider<RecordingController, RecordingState>((ref) {
  return RecordingController();
});
