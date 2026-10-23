import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utilities/haptic_feedback_service.dart';
import '../domain/overlay_state.dart';

/// Controller managing decoy wallpaper, secret touch zones, and disguise opacity.
class OverlayController extends StateNotifier<CameraOverlayState> {
  final HapticFeedbackService _haptic;
  static const String _keyImagePath = 'overlay_image_path';
  static const String _keyFitMode = 'overlay_fit_mode';
  static const String _keyOpacity = 'overlay_opacity';
  static const String _keyAutoRecord = 'overlay_auto_record';

  OverlayController({HapticFeedbackService? haptic})
      : _haptic = haptic ?? const HapticFeedbackService(),
        super(const CameraOverlayState()) {
    _loadSavedSettings();
  }

  Future<void> _loadSavedSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? path = prefs.getString(_keyImagePath);
      final String? fit = prefs.getString(_keyFitMode);
      final double? opacity = prefs.getDouble(_keyOpacity);
      final bool? autoRecord = prefs.getBool(_keyAutoRecord);

      state = state.copyWith(
        imagePath: path,
        fitMode: fit == 'contain' ? BoxFit.contain : BoxFit.cover,
        opacity: opacity ?? 1.0,
        isAutoRecordOnLaunch: autoRecord ?? true,
      );
    } catch (_) {
      // Keep defaults if prefs unavailable
    }
  }

  /// Sets decoy image path and persists to disk.
  Future<void> setDecoyImage(String path) async {
    state = state.copyWith(imagePath: path);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyImagePath, path);
    } catch (_) {}
    await _haptic.selectionClick();
  }

  /// Changes BoxFit mode (cover vs contain).
  Future<void> setFitMode(BoxFit mode) async {
    state = state.copyWith(fitMode: mode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyFitMode, mode == BoxFit.contain ? 'contain' : 'cover');
    } catch (_) {}
  }

  /// Sets overlay opacity (0.0 = translucent/preview visible, 1.0 = completely masked).
  Future<void> setOpacity(double opacity) async {
    final clamped = opacity.clamp(0.0, 1.0);
    state = state.copyWith(opacity: clamped);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_keyOpacity, clamped);
    } catch (_) {}
  }

  /// Increases opacity by [step] (up to 1.0) to make decoy less transparent.
  Future<void> increaseOpacity([double step = 0.2]) async {
    final newOpacity = (state.opacity + step).clamp(0.0, 1.0);
    await setOpacity(newOpacity);
    await _haptic.selectionClick();
  }

  /// Decreases opacity by [step] (down to 0.1) so user can peek through to preview camera.
  Future<void> decreaseOpacity([double step = 0.2]) async {
    final newOpacity = (state.opacity - step).clamp(0.1, 1.0);
    await setOpacity(newOpacity);
    await _haptic.selectionClick();
  }

  /// Toggles between fully masked (1.0) and translucent peek mode (0.35).
  Future<void> togglePeekOpacity() async {
    if (state.opacity >= 0.7) {
      await setOpacity(0.35); // Peek through to see camera framing
    } else {
      await setOpacity(1.0); // Completely hide camera
    }
    await _haptic.selectionClick();
  }

  /// Cycles opacity across 4 presets: 1.0 (Full mask) -> 0.65 -> 0.35 (Peek) -> 0.1.
  Future<void> cycleOpacity() async {
    final current = state.opacity;
    double next;
    if (current >= 0.9) {
      next = 0.65;
    } else if (current >= 0.55) {
      next = 0.35;
    } else if (current >= 0.25) {
      next = 0.10;
    } else {
      next = 1.0;
    }
    await setOpacity(next);
    await _haptic.selectionClick();
  }

  /// Toggles visibility of the secret hint overlay (wireframe boxes for touch zones).
  /// Triggered by 3-finger tap.
  Future<void> toggleSecretHints() async {
    final bool updated = !state.showSecretHints;
    state = state.copyWith(showSecretHints: updated);
    await _haptic.selectionClick();
  }

  /// Unlocks the vault to view recordings and configure settings.
  void setVaultUnlocked(bool unlocked) {
    state = state.copyWith(isVaultUnlocked: unlocked);
  }

  /// Enables or disables automatic recording on application launch.
  Future<void> setAutoRecordOnLaunch(bool enabled) async {
    state = state.copyWith(isAutoRecordOnLaunch: enabled);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyAutoRecord, enabled);
    } catch (_) {}
  }
}

/// Riverpod provider for OverlayController.
final overlayControllerProvider =
    StateNotifierProvider<OverlayController, CameraOverlayState>((ref) {
  return OverlayController();
});
