import 'package:flutter/material.dart';

/// Infinity brand palette.
///
/// Widgets should prefer [Theme.of] / [ColorScheme] over these constants.
/// Use [AppThemeColors] theme extension for semantic success / warning / info.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF2563EB);
  static const Color secondary = Color(0xFF0EA5E9);
  static const Color accent = Color(0xFF60A5FA);

  // Light surfaces (existing — do not redesign)
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceTint = Color(0xFFEFF6FF);
  static const Color border = Color(0xFFE5E7EB);

  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);

  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF6B7280);

  // Dark surfaces — Material 3 tonal, never pure black
  static const Color darkBackground = Color(0xFF121416);
  static const Color darkSurface = Color(0xFF1A1C1E);
  static const Color darkSurfaceContainer = Color(0xFF1E2022);
  static const Color darkSurfaceContainerHigh = Color(0xFF282A2C);
  static const Color darkSurfaceContainerHighest = Color(0xFF333537);
  static const Color darkSurfaceTint = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF3F4346);
  static const Color darkOutline = Color(0xFF8B9198);
  static const Color darkTextPrimary = Color(0xFFE2E2E6);
  static const Color darkTextSecondary = Color(0xFFC0C7CF);
}

/// Semantic colors exposed through [ThemeData.extensions].
@immutable
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  const AppThemeColors({
    required this.success,
    required this.warning,
    required this.info,
    required this.surfaceTint,
    required this.border,
  });

  final Color success;
  final Color warning;
  final Color info;
  final Color surfaceTint;
  final Color border;

  static const AppThemeColors light = AppThemeColors(
    success: AppColors.success,
    warning: AppColors.warning,
    info: AppColors.info,
    surfaceTint: AppColors.surfaceTint,
    border: AppColors.border,
  );

  static const AppThemeColors dark = AppThemeColors(
    success: Color(0xFF4ADE80),
    warning: Color(0xFFFBBF24),
    info: Color(0xFF94A3B8),
    surfaceTint: AppColors.darkSurfaceTint,
    border: AppColors.darkBorder,
  );

  static AppThemeColors of(BuildContext context) {
    return Theme.of(context).extension<AppThemeColors>() ?? AppThemeColors.light;
  }

  @override
  AppThemeColors copyWith({
    Color? success,
    Color? warning,
    Color? info,
    Color? surfaceTint,
    Color? border,
  }) {
    return AppThemeColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      surfaceTint: surfaceTint ?? this.surfaceTint,
      border: border ?? this.border,
    );
  }

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) {
      return this;
    }
    return AppThemeColors(
      success: Color.lerp(success, other.success, t) ?? success,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      info: Color.lerp(info, other.info, t) ?? info,
      surfaceTint: Color.lerp(surfaceTint, other.surfaceTint, t) ?? surfaceTint,
      border: Color.lerp(border, other.border, t) ?? border,
    );
  }
}
