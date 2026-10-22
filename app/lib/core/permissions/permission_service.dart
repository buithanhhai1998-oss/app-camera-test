import 'package:local_auth/local_auth.dart';

/// Result status of a permission request.
enum PermissionStatusResult {
  granted,
  denied,
  restricted,
  permanentlyDenied,
}

/// Service handling permissions and biometric capabilities.
class PermissionService {
  final LocalAuthentication _localAuth;

  PermissionService({LocalAuthentication? localAuth})
      : _localAuth = localAuth ?? LocalAuthentication();

  /// Check whether biometric authentication (Face ID / Touch ID) is available on the device.
  Future<bool> isBiometricsAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics =
          await _localAuth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();
      return canAuthenticate;
    } catch (_) {
      return false;
    }
  }

  /// Authenticate using Face ID / Touch ID or device passcode.
  Future<bool> authenticateWithBiometrics({
    String reason = 'Authenticate to access secret media vault and settings',
  }) async {
    try {
      final bool isAvailable = await isBiometricsAvailable();
      if (!isAvailable) return true; // Fallback if no biometrics setup on device

      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
