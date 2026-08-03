import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

/// Device biometric / credential gate for admin-only surfaces.
class BiometricAuthService {
  BiometricAuthService({LocalAuthentication? localAuth})
      : _auth = localAuth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  /// Returns true when the device can authenticate (biometrics or device PIN).
  Future<bool> canAuthenticate() async {
    if (kIsWeb) return false;
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// Prompts biometric auth with automatic device-credential fallback.
  ///
  /// Returns `true` on success, `false` on cancel/failure/unsupported.
  Future<bool> authenticate({
    required String reason,
    String? cancelButton,
    String? signInTitle,
  }) async {
    if (kIsWeb) return false;
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return false;

      // biometricOnly: false → fingerprint/face, with device PIN/pattern fallback.
      return _auth.authenticate(
        localizedReason: reason,
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }
}
