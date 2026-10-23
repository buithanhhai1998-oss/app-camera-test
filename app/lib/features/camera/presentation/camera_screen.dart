import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/permissions/permission_service.dart';
import '../../overlay/presentation/overlay_controller.dart';
import '../../overlay/widgets/camouflaged_stack_widget.dart';
import '../../media_library/data/recordings_database.dart';
import '../../media_library/domain/media_item.dart';
import '../../media_library/presentation/media_library_screen.dart';
import '../../recording/presentation/recording_controller.dart';
import '../../recording/services/auto_record_coordinator.dart';
import '../../recording/services/orphan_recovery_service.dart';
import '../../recording/services/recording_storage_service.dart';
import '../../settings/presentation/onboarding_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../services/camera_service.dart';

/// Primary Camouflaged Camera Screen managing auto-recording, secret zones, and lifecycle.
class CameraScreen extends ConsumerStatefulWidget {
  final CameraService? cameraServiceOverride;
  final RecordingStorageService? storageServiceOverride;
  final RecordingsDatabase? databaseOverride;

  const CameraScreen({
    super.key,
    this.cameraServiceOverride,
    this.storageServiceOverride,
    this.databaseOverride,
  });

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> with WidgetsBindingObserver {
  late final CameraService _cameraService;
  late final RecordingStorageService _storageService;
  late final RecordingsDatabase _database;
  late final AutoRecordCoordinator _coordinator;
  late final PermissionService _permissionService;

  bool _isFirstLaunch = false;
  bool _isCheckingFirstLaunch = true;
  bool _cameraInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _cameraService = widget.cameraServiceOverride ?? CameraService();
    _storageService = widget.storageServiceOverride ?? RecordingStorageService();
    _database = widget.databaseOverride ?? RecordingsDatabase();
    _permissionService = PermissionService();

    final recordingCtrl = ref.read(recordingControllerProvider.notifier);

    _coordinator = AutoRecordCoordinator(
      cameraService: _cameraService,
      storageService: _storageService,
      recordingController: recordingCtrl,
      onRecordingSaved: _handleRecordingSaved,
    );

    _bootstrapApp();
  }

  Future<void> _bootstrapApp() async {
    final prefs = await SharedPreferences.getInstance();
    final bool firstLaunchDone = prefs.getBool('is_first_launch_done') ?? false;

    if (!firstLaunchDone) {
      if (mounted) {
        setState(() {
          _isFirstLaunch = true;
          _isCheckingFirstLaunch = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isFirstLaunch = false;
        _isCheckingFirstLaunch = false;
      });
    }

    await _initCameraAndAutoRecord();
  }

  Future<void> _initCameraAndAutoRecord() async {
    // 1. Recover any unindexed orphan recordings from previous sessions
    final orphanService = OrphanRecoveryService(
      storageService: _storageService,
      database: _database,
    );
    orphanService.recoverOrphanRecordings().ignore();

    // 2. Read preferences for preferred lens & duration limit
    final prefs = await SharedPreferences.getInstance();
    final preferredLensStr = prefs.getString('settings_preferred_lens') ?? 'back';
    final maxDurationMinutes = prefs.getInt('settings_max_duration_minutes') ?? 0;

    if (maxDurationMinutes > 0) {
      _coordinator.maxRecordingDuration = Duration(minutes: maxDurationMinutes);
    }

    final preferredLens = preferredLensStr == 'front'
        ? CameraLensDirection.front
        : CameraLensDirection.back;

    // 3. Initialize Camera Hardware
    try {
      await _cameraService.initialize(preferredLens: preferredLens);
      if (mounted) {
        setState(() => _cameraInitialized = true);
        ref.read(recordingControllerProvider.notifier).setReady();
      }

      // 4. Auto-Record if enabled
      final overlayState = ref.read(overlayControllerProvider);
      if (overlayState.isAutoRecordOnLaunch) {
        // Allow widget tree to settle frame before recording
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (mounted && ref.read(recordingControllerProvider).canStart) {
            await _coordinator.startSession();
          }
        });
      }
    } catch (e) {
      ref.read(recordingControllerProvider.notifier).setError('Camera init failed: $e');
    }
  }

  Future<void> _handleRecordingSaved(String path, Duration duration, int fileSizeBytes) async {
    final filename = path.split(RegExp(r'[\\/]')).last;
    final item = MediaItem(
      filename: filename,
      filepath: path,
      durationSeconds: duration.inSeconds,
      fileSizeBytes: fileSizeBytes,
      createdAt: DateTime.now(),
    );
    await _database.insertRecording(item);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Finalize active recording immediately to prevent corrupted MP4
      _coordinator.handleInterruption('App entered background');
    }
  }

  // --- Secret Gesture Handlers ---

  /// Top-Right: Double Tap -> Stop & Save recording
  Future<void> _onStopDoubleTap() async {
    if (ref.read(recordingControllerProvider).isRecording) {
      await _coordinator.stopAndSaveSession();
    }
  }

  /// Top-Left: Long Press 2s -> Authenticate Face ID & Open Media Library
  Future<void> _onUnlockLongPress() async {
    final prefs = await SharedPreferences.getInstance();
    final useBiometrics = prefs.getBool('settings_use_biometrics') ?? true;

    bool authenticated = true;
    if (useBiometrics) {
      authenticated = await _permissionService.authenticateWithBiometrics(
        reason: 'Xác thực Face ID để mở thư viện video bí mật',
      );
    }

    if (authenticated && mounted) {
      // If currently recording, stop and save before leaving screen
      if (ref.read(recordingControllerProvider).isRecording) {
        await _coordinator.stopAndSaveSession();
      }

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MediaLibraryScreen(
            database: _database,
            storageService: _storageService,
            onOpenSettings: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(
                    overlayController: ref.read(overlayControllerProvider.notifier),
                    overlayState: ref.read(overlayControllerProvider),
                    database: _database,
                    storageService: _storageService,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }
  }

  /// Bottom-Right: Double Tap -> Switch Lens
  Future<void> _onSwitchLensDoubleTap() async {
    if (!ref.read(recordingControllerProvider).isRecording) {
      try {
        await _cameraService.switchCameraLens();
        if (mounted) setState(() {});
      } catch (_) {}
    }
  }

  /// Bottom-Left: Tap -> Cycle Opacity (Peek camera preview)
  void _onOpacityTap() {
    ref.read(overlayControllerProvider.notifier).cycleOpacity();
  }

  /// 3-Finger Tap: Toggle Visual Hint Overlay
  void _onThreeFingerTap() {
    ref.read(overlayControllerProvider.notifier).toggleSecretHints();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _coordinator.dispose();
    _cameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingFirstLaunch) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_isFirstLaunch) {
      return OnboardingScreen(
        overlayController: ref.read(overlayControllerProvider.notifier),
        onFinish: () {
          setState(() => _isFirstLaunch = false);
          _initCameraAndAutoRecord();
        },
      );
    }

    final overlayState = ref.watch(overlayControllerProvider);
    final recordingState = ref.watch(recordingControllerProvider);

    final Widget previewWidget;
    final controller = _cameraService.controller;
    if (_cameraInitialized && controller != null && controller.value.isInitialized) {
      previewWidget = CameraPreview(controller);
    } else {
      previewWidget = const ColoredBox(color: Colors.black);
    }

    return CamouflagedStackWidget(
      cameraPreview: previewWidget,
      overlayState: overlayState,
      isRecording: recordingState.isRecording,
      elapsedDuration: recordingState.elapsedDuration,
      onStopDoubleTap: _onStopDoubleTap,
      onUnlockLongPress: _onUnlockLongPress,
      onSwitchLensDoubleTap: _onSwitchLensDoubleTap,
      onOpacityTap: _onOpacityTap,
      onThreeFingerTap: _onThreeFingerTap,
      onIncreaseOpacity: () => ref.read(overlayControllerProvider.notifier).increaseOpacity(),
      onDecreaseOpacity: () => ref.read(overlayControllerProvider.notifier).decreaseOpacity(),
      onTogglePeekOpacity: () => ref.read(overlayControllerProvider.notifier).togglePeekOpacity(),
    );
  }
}
