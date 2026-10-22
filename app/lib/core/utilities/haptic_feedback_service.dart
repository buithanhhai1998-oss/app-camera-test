import 'package:flutter/services.dart';
import '../constants/app_constants.dart';

/// Haptic Feedback Service providing tactile confirmations for blind/camouflaged interactions.
class HapticFeedbackService {
  const HapticFeedbackService();

  /// 1 pulse: Confirms recording has started.
  Future<void> startRecordingPulse() async {
    await HapticFeedback.lightImpact();
  }

  /// 2 pulses: Confirms recording has stopped and file saved.
  Future<void> stopRecordingPulse() async {
    await HapticFeedback.mediumImpact();
    await Future<void>.delayed(AppConstants.hapticPulseInterval);
    await HapticFeedback.mediumImpact();
  }

  /// 3 pulses: Alerts of an error, cancellation, or unauthorized unlock attempt.
  Future<void> errorPulse() async {
    for (int i = 0; i < 3; i++) {
      await HapticFeedback.heavyImpact();
      if (i < 2) {
        await Future<void>.delayed(AppConstants.hapticPulseInterval);
      }
    }
  }

  /// Subtle click for button tap or zone detection.
  Future<void> selectionClick() async {
    await HapticFeedback.selectionClick();
  }
}
