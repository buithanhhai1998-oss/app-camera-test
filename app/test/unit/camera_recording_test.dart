import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sideload_app/features/camera/services/camera_service.dart';
import 'package:flutter_sideload_app/features/recording/domain/recording_state.dart';
import 'package:flutter_sideload_app/features/recording/presentation/recording_controller.dart';
import 'package:flutter_sideload_app/features/recording/services/auto_record_coordinator.dart';
import 'package:flutter_sideload_app/features/recording/services/recording_storage_service.dart';
import 'package:flutter_sideload_app/core/utilities/haptic_feedback_service.dart';

class FakeCameraService extends CameraService {
  bool isCameraRecording = false;
  bool isInitializedState = true;
  String? mockRecordedFilePath;

  @override
  bool get isInitialized => isInitializedState;

  @override
  bool get isRecording => isCameraRecording;

  @override
  Future<void> startVideoRecording() async {
    if (!isInitializedState) {
      throw CameraServiceException('Not initialized', code: 'NOT_INITIALIZED');
    }
    if (isCameraRecording) {
      throw CameraServiceException('Already recording', code: 'ALREADY_RECORDING');
    }
    isCameraRecording = true;
  }

  @override
  Future<XFile> stopVideoRecording() async {
    if (!isCameraRecording) {
      throw CameraServiceException('Not recording', code: 'NOT_RECORDING');
    }
    isCameraRecording = false;
    return XFile(mockRecordedFilePath ?? '');
  }
}

class FakeHapticService extends HapticFeedbackService {
  int startPulses = 0;
  int stopPulses = 0;
  int errorPulses = 0;

  @override
  Future<void> startRecordingPulse() async => startPulses++;
  @override
  Future<void> stopRecordingPulse() async => stopPulses++;
  @override
  Future<void> errorPulse() async => errorPulses++;
}

void main() {
  late Directory tempDir;
  late RecordingStorageService storageService;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('camera_test_sandbox_');
    storageService = RecordingStorageService(overrideDir: tempDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('RecordingStorageService Unit Tests', () {
    test('generateNewRecordingPath creates path with REC_YYYYMMDD_HHMMSS.mp4 format', () async {
      final path = await storageService.generateNewRecordingPath();
      expect(path, contains('REC_'));
      expect(path.endsWith('.mp4'), isTrue);
      final filename = File(path).uri.pathSegments.last;
      expect(RegExp(r'^REC_\d{8}_\d{6}\.mp4$').hasMatch(filename), isTrue);
    });

    test('validateRecordingFile returns true only for existing non-empty file', () async {
      final validFile = File('${tempDir.path}/valid.mp4');
      await validFile.writeAsBytes([1, 2, 3, 4, 5]);

      final emptyFile = File('${tempDir.path}/empty.mp4');
      await emptyFile.writeAsBytes([]);

      expect(await storageService.validateRecordingFile(validFile.path), isTrue);
      expect(await storageService.validateRecordingFile(emptyFile.path), isFalse);
      expect(await storageService.validateRecordingFile('${tempDir.path}/missing.mp4'), isFalse);
    });

    test('calculateTotalRecordingsBytes sums up byte size of all files in directory', () async {
      final file1 = File('${tempDir.path}/f1.mp4');
      await file1.writeAsBytes(List.filled(100, 0));
      final file2 = File('${tempDir.path}/f2.mp4');
      await file2.writeAsBytes(List.filled(250, 0));

      final total = await storageService.calculateTotalRecordingsBytes();
      expect(total, equals(350));
    });

    test('deleteRecordingFile removes file and returns true', () async {
      final file = File('${tempDir.path}/to_delete.mp4');
      await file.writeAsBytes([1, 2, 3]);
      expect(await file.exists(), isTrue);

      final deleted = await storageService.deleteRecordingFile(file.path);
      expect(deleted, isTrue);
      expect(await file.exists(), isFalse);
    });
  });

  group('AutoRecordCoordinator Workflow Tests', () {
    late FakeCameraService fakeCamera;
    late FakeHapticService fakeHaptic;
    late RecordingController recordingController;
    late AutoRecordCoordinator coordinator;

    setUp(() {
      fakeCamera = FakeCameraService();
      fakeHaptic = FakeHapticService();
      recordingController = RecordingController(haptic: fakeHaptic);
      coordinator = AutoRecordCoordinator(
        cameraService: fakeCamera,
        storageService: storageService,
        recordingController: recordingController,
      );
    });

    tearDown(() {
      coordinator.dispose();
      recordingController.dispose();
    });

    test('startSession initializes recording state and triggers start pulse', () async {
      recordingController.setReady();
      final success = await coordinator.startSession();

      expect(success, isTrue);
      expect(fakeCamera.isCameraRecording, isTrue);
      expect(recordingController.state.status, equals(RecordingStatus.recording));
      expect(fakeHaptic.startPulses, equals(1));
    });

    test('stopAndSaveSession finalizes recording, validates file, and invokes callback', () async {
      recordingController.setReady();
      await coordinator.startSession();

      // Create a mock recorded video file that CameraService will return
      final tempMockFile = File('${tempDir.path}/mock_camera_output.mp4');
      await tempMockFile.writeAsBytes(List.filled(1024, 0));
      fakeCamera.mockRecordedFilePath = tempMockFile.path;

      bool callbackFired = false;
      String? savedPathCallback;
      AutoRecordCoordinator coordinatorWithCb = AutoRecordCoordinator(
        cameraService: fakeCamera,
        storageService: storageService,
        recordingController: recordingController,
        onRecordingSaved: (path, duration, size) async {
          callbackFired = true;
          savedPathCallback = path;
        },
      );

      final finalPath = await coordinatorWithCb.stopAndSaveSession();

      expect(finalPath, isNotNull);
      expect(File(finalPath!).existsSync(), isTrue);
      expect(fakeCamera.isCameraRecording, isFalse);
      expect(recordingController.state.status, equals(RecordingStatus.saved));
      expect(fakeHaptic.stopPulses, equals(1));
      expect(callbackFired, isTrue);
      expect(savedPathCallback, equals(finalPath));

      coordinatorWithCb.dispose();
    });
  });
}
