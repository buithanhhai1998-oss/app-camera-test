/// Application-wide constants for Flutter Camouflaged Camera & Recorder.
class AppConstants {
  AppConstants._();

  static const String appName = 'Camera';
  static const String dbName = 'media_vault.db';
  static const String recordingsDir = 'recordings';
  static const String snapshotsDir = 'snapshots';

  // Secret Touch Zone dimensions (normalized 0.0 to 1.0 of screen width/height)
  // Top-Right: Stop & Save (Double Tap)
  static const double stopZoneWidthRatio = 0.30;
  static const double stopZoneHeightRatio = 0.20;

  // Top-Left: Unlock Vault / Settings (Long Press 2 seconds)
  static const double unlockZoneWidthRatio = 0.30;
  static const double unlockZoneHeightRatio = 0.20;
  static const Duration unlockLongPressDuration = Duration(seconds: 2);

  // Bottom-Right: Switch Camera Lens (Double Tap)
  static const double switchLensZoneWidthRatio = 0.30;
  static const double switchLensZoneHeightRatio = 0.20;

  // Bottom-Left: Opacity Adjust / Peek Camera View (Tap / Double Tap)
  static const double opacityZoneWidthRatio = 0.30;
  static const double opacityZoneHeightRatio = 0.20;

  // Haptic feedback timing
  static const Duration hapticPulseInterval = Duration(milliseconds: 150);
}
