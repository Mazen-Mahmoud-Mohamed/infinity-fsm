import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/core/theme/app_colors.dart';

/// Applies status + navigation bar colors to match the active Material theme.
///
/// Keeps Android edge-to-edge free of a white system nav strip in dark mode.
class AppSystemUi {
  AppSystemUi._();

  static SystemUiOverlayStyle overlayFor(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final navColor = theme.scaffoldBackgroundColor;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: navColor,
      systemNavigationBarDividerColor: navColor,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    );
  }

  static void apply(ThemeData theme) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(overlayFor(theme));
  }

  /// Fallback before [Theme] is available (splash / cold start).
  static void applyBootstrap() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.darkBackground,
      systemNavigationBarDividerColor: AppColors.darkBackground,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarContrastEnforced: false,
    ));
  }
}
