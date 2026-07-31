import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_colors.dart';

/// Subtle light-only brand gradients for hero surfaces.
class AppGradients {
  AppGradients._();

  static const LinearGradient surface = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.surface, AppColors.surfaceTint],
  );

  static const LinearGradient hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.surfaceTint, AppColors.surface],
  );

  static const LinearGradient primarySoft = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primary, AppColors.secondary],
  );
}
