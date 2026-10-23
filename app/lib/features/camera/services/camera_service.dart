import 'package:camera/camera.dart' as cam;

/// Exception thrown when camera operations fail.
class CameraServiceException implements Exception {
  final String message;
  final String? code;

  CameraServiceException(this.message, {this.code});

  @override
  String toString() => 'CameraServiceException: $message (code: $code)';
}

/// Service managing the camera hardware lifecycle and AVFoundation recording pipeline.
class CameraService {
  cam.CameraController? _controller;
  List<cam.CameraDescription> _availableCameras = [];
  int _selectedCameraIndex = 0;
  bool _isInitializing = false;

  cam.CameraController? get controller => _controller;
  bool get isInitialized => _controller != null && _controller!.value.isInitialized;
  bool get isRecording => _controller != null && _controller!.value.isRecordingVideo;
  List<cam.CameraDescription> get availableCameras => _availableCameras;
  cam.CameraLensDirection get currentLensDirection =>
      _availableCameras.isNotEmpty
          ? _availableCameras[_selectedCameraIndex].lensDirection
          : cam.CameraLensDirection.back;

  /// Discovers available cameras and initializes the default camera.
  Future<void> initialize({
    cam.CameraLensDirection preferredLens = cam.CameraLensDirection.back,
    cam.ResolutionPreset resolution = cam.ResolutionPreset.high,
    bool enableAudio = true,
  }) async {
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      if (_availableCameras.isEmpty) {
        _availableCameras = await cam.availableCameras();
      }

      if (_availableCameras.isEmpty) {
        throw CameraServiceException('No camera hardware found on this device', code: 'NO_CAMERAS');
      }

      // Find preferred lens or fallback to first available
      _selectedCameraIndex = _availableCameras.indexWhere(
        (camera) => camera.lensDirection == preferredLens,
      );
      if (_selectedCameraIndex == -1) {
        _selectedCameraIndex = 0;
      }

      await _initController(
        _availableCameras[_selectedCameraIndex],
        resolution: resolution,
        enableAudio: enableAudio,
      );
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _initController(
    cam.CameraDescription description, {
    required cam.ResolutionPreset resolution,
    required bool enableAudio,
  }) async {
    // Clean up existing controller before opening a new session to avoid resource conflicts
    if (_controller != null) {
      final old = _controller;
      _controller = null;
      await old?.dispose();
    }

    final newController = cam.CameraController(
      description,
      resolution,
      enableAudio: enableAudio,
      imageFormatGroup: cam.ImageFormatGroup.bgra8888,
    );

    try {
      await newController.initialize();
      _controller = newController;
    } on cam.CameraException catch (e) {
      await newController.dispose();
      throw CameraServiceException(e.description ?? e.code, code: e.code);
    }
  }

  /// Switches between front and back camera lenses.
  Future<void> switchCameraLens() async {
    if (_availableCameras.length < 2) return;
    if (isRecording) {
      throw CameraServiceException('Cannot switch lens while actively recording', code: 'BUSY_RECORDING');
    }

    _selectedCameraIndex = (_selectedCameraIndex + 1) % _availableCameras.length;
    final nextCamera = _availableCameras[_selectedCameraIndex];
    await _initController(
      nextCamera,
      resolution: _controller?.resolutionPreset ?? cam.ResolutionPreset.high,
      enableAudio: _controller?.enableAudio ?? true,
    );
  }

  /// Starts video recording to a local file.
  Future<void> startVideoRecording() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      throw CameraServiceException('Camera not initialized', code: 'NOT_INITIALIZED');
    }
    if (c.value.isRecordingVideo) {
      throw CameraServiceException('Camera is already recording', code: 'ALREADY_RECORDING');
    }

    try {
      await c.startVideoRecording();
    } on cam.CameraException catch (e) {
      throw CameraServiceException(e.description ?? e.code, code: e.code);
    }
  }

  /// Stops current video recording and returns the captured file.
  Future<cam.XFile> stopVideoRecording() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      throw CameraServiceException('Camera not initialized', code: 'NOT_INITIALIZED');
    }
    if (!c.value.isRecordingVideo) {
      throw CameraServiceException('Camera is not recording', code: 'NOT_RECORDING');
    }

    try {
      return await c.stopVideoRecording();
    } on cam.CameraException catch (e) {
      throw CameraServiceException(e.description ?? e.code, code: e.code);
    }
  }

  /// Disposes camera resources cleanly.
  Future<void> dispose() async {
    final c = _controller;
    _controller = null;
    if (c != null) {
      if (c.value.isRecordingVideo) {
        try {
          await c.stopVideoRecording();
        } catch (_) {}
      }
      await c.dispose();
    }
  }
}
