import 'package:flutter/widgets.dart';

/// Immutable state model for the Camera Decoy Overlay.
/// Named [CameraOverlayState] to prevent collision with Flutter's [OverlayState].
@immutable
class CameraOverlayState {
  final String? imagePath;
  final BoxFit fitMode;
  final double opacity;
  final bool showSecretHints;
  final bool isAutoRecordOnLaunch;
  final bool isVaultUnlocked;

  const CameraOverlayState({
    this.imagePath,
    this.fitMode = BoxFit.cover,
    this.opacity = 1.0,
    this.showSecretHints = false,
    this.isAutoRecordOnLaunch = true,
    this.isVaultUnlocked = false,
  });

  bool get hasCustomImage => imagePath != null && imagePath!.isNotEmpty;

  CameraOverlayState copyWith({
    String? imagePath,
    BoxFit? fitMode,
    double? opacity,
    bool? showSecretHints,
    bool? isAutoRecordOnLaunch,
    bool? isVaultUnlocked,
  }) {
    return CameraOverlayState(
      imagePath: imagePath ?? this.imagePath,
      fitMode: fitMode ?? this.fitMode,
      opacity: opacity ?? this.opacity,
      showSecretHints: showSecretHints ?? this.showSecretHints,
      isAutoRecordOnLaunch: isAutoRecordOnLaunch ?? this.isAutoRecordOnLaunch,
      isVaultUnlocked: isVaultUnlocked ?? this.isVaultUnlocked,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CameraOverlayState &&
          runtimeType == other.runtimeType &&
          imagePath == other.imagePath &&
          fitMode == other.fitMode &&
          opacity == other.opacity &&
          showSecretHints == other.showSecretHints &&
          isAutoRecordOnLaunch == other.isAutoRecordOnLaunch &&
          isVaultUnlocked == other.isVaultUnlocked;

  @override
  int get hashCode =>
      imagePath.hashCode ^
      fitMode.hashCode ^
      opacity.hashCode ^
      showSecretHints.hashCode ^
      isAutoRecordOnLaunch.hashCode ^
      isVaultUnlocked.hashCode;
}
