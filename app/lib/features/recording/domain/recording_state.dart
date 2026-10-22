import 'package:flutter/foundation.dart';

/// Enum representing the finite states of the video recording lifecycle.
enum RecordingStatus {
  idle,
  initializing,
  ready,
  recording,
  stopping,
  saved,
  interrupted,
  error,
}

/// Immutable state model for the recording engine.
@immutable
class RecordingState {
  final RecordingStatus status;
  final Duration elapsedDuration;
  final String? currentFilePath;
  final String? errorMessage;

  const RecordingState({
    this.status = RecordingStatus.idle,
    this.elapsedDuration = Duration.zero,
    this.currentFilePath,
    this.errorMessage,
  });

  bool get isRecording => status == RecordingStatus.recording;
  bool get isBusy => status == RecordingStatus.initializing || status == RecordingStatus.stopping;
  bool get canStart => status == RecordingStatus.ready || status == RecordingStatus.idle || status == RecordingStatus.saved;
  bool get canStop => status == RecordingStatus.recording;

  RecordingState copyWith({
    RecordingStatus? status,
    Duration? elapsedDuration,
    String? currentFilePath,
    String? errorMessage,
  }) {
    return RecordingState(
      status: status ?? this.status,
      elapsedDuration: elapsedDuration ?? this.elapsedDuration,
      currentFilePath: currentFilePath ?? this.currentFilePath,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecordingState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          elapsedDuration == other.elapsedDuration &&
          currentFilePath == other.currentFilePath &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode =>
      status.hashCode ^
      elapsedDuration.hashCode ^
      currentFilePath.hashCode ^
      errorMessage.hashCode;

  @override
  String toString() {
    return 'RecordingState(status: $status, duration: ${elapsedDuration.inSeconds}s, path: $currentFilePath, error: $errorMessage)';
  }
}
