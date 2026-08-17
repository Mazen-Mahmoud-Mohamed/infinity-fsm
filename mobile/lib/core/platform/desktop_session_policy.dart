import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Windows-only session persistence rules for Remember Me.
///
/// Android / iOS keep the existing behavior: tokens are always written to
/// secure storage regardless of the Remember Me checkbox.
class DesktopSessionPolicy {
  DesktopSessionPolicy._();

  /// When true, a persisted refresh session is restored only if Remember Me
  /// was enabled at login.
  static bool requiresRememberMeToRestore() {
    if (kIsWeb) return false;
    return Platform.isWindows;
  }

  /// Whether access/refresh tokens should be written to secure storage.
  static bool persistTokensOnDisk({required bool rememberMe}) {
    if (kIsWeb) return true;
    if (Platform.isWindows) return rememberMe;
    return true;
  }
}
