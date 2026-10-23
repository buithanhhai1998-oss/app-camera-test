import 'dart:async';
import 'dart:io';
import '../../camera/services/camera_service.dart';
import '../presentation/recording_controller.dart';
import 'recording_storage_service.dart';

/// Callback type for persisting new recordings into database.
typedef OnRecordingSaved = Future<void> Function(String filePath, Duration duration, int fileSizeBytes);

/// Coordinates CameraService, RecordingStorageService, and RecordingController.
class AutoRecordCoordinator {
  final CameraService _cameraService;
  final RecordingStorageService _storageService;
  final RecordingController _recordingController;
  final OnRecordingSaved? _onRecordingSaved;

  Timer? _safetyAutoStopTimer;
  Duration? _maxRecordingDuration; // null = unlimited

  AutoRecordCoordinator({
    required CameraService cameraService,
    required RecordingStorageService storageService,
    required RecordingController recordingController,
    OnRecordingSaved? onRecordingSaved,
    Duration? maxRecordingDuration,
  })  : _cameraService = cameraService,
        _storageService = storageService,
        _recordingController = recordingController,
        _onRecordingSaved = onRecordingSaved,
        _maxRecordingDuration = maxRecordingDuration;

  Duration? get maxRecordingDuration => _maxRecordingDuration;
  set maxRecordingDuration(Duration? duration) {
    _maxRecordingDuration = duration;
  }

  /// Initiates recording session.
  Future<bool> startSession() async {
    if (!_recordingController.canStart) {
      return false;
    }

    try {
      final destPath = await _storageService.generateNewRecordingPath();
      await _cameraService.startVideoRecording();

      final started = await _recordingController.startRecording(destinationPath: destPath);
      if (!started) return false;

      // Start safety auto-stop if configured
      final maxDuration = _maxRecordingDuration;
      if (maxDuration != null && maxDuration > Duration.zero) {
        _safetyAutoStopTimer?.cancel();
        _safetyAutoStopTimer = Timer(maxDuration, () async {
          if (_recordingController.isRecording) {
            await stopAndSaveSession();
          }
        });
      }

      return true;
    } catch (e) {
      await _recordingController.setError('Failed to start recording: $e');
      return false;
    }
  }

  /// Stops session, persists file to Documents/recordings, validates, and notifies.
  Future<String?> stopAndSaveSession() async {
    _safetyAutoStopTimer?.cancel();
    _safetyAutoStopTimer = null;

    if (!_recordingController.canStop) {
      return null;
    }

    final Duration duration = _recordingController.elapsedDuration;
    final String? expectedPath = _recordingController.currentFilePath;

    try {
      final xfile = await _cameraService.stopVideoRecording();
      final destination = expectedPath ?? await _storageService.generateNewRecordingPath();

      // Ensure file is copied or moved into destination in Documents/recordings
      final tempFile = File(xfile.path);
      if (tempFile.path != destination) {
        final destFile = File(destination);
        if (await destFile.exists()) {
          await destFile.delete();
        }
        await tempFile.copy(destination);
        try {
          await tempFile.delete();
        } catch (_) {}
      }

      final isValid = await _storageService.validateRecordingFile(destination);
      if (!isValid) {
        await _recordingController.setError('Recorded file is corrupted or empty');
        return null;
      }

      final fileSizeBytes = await File(destination).length();
      await _recordingController.stopRecording();

      final onSaved = _onRecordingSaved;
      if (onSaved != null) {
        await onSaved(destination, duration, fileSizeBytes);
      }

      return destination;
    } catch (e) {
      await _recordingController.setError('Failed to finalize recording: $e');
      return null;
    }
  }

  /// Handles application interruption (e.g. backgrounding, incoming call).
  Future<void> handleInterruption(String reason) async {
    _safetyAutoStopTimer?.cancel();
    _safetyAutoStopTimer = null;

    if (_recordingController.isRecording) {
      try {
        await stopAndSaveSession();
      } catch (_) {}
    }
    _recordingController.handleInterruption(reason);
  }

  void dispose() {
    _safetyAutoStopTimer?.cancel();
    _safetyAutoStopTimer = null;
  }
}
