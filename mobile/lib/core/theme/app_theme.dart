import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_radius.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/theme/app_system_ui.dart';
import 'package:mobile/core/theme/app_typography.dart';

/// Infinity enterprise Material 3 themes (light + dark).
class AppTheme {
  AppTheme._();

  static ThemeData light() {
    const brightness = Brightness.light;

    const colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.surfaceTint,
      onPrimaryContainer: AppColors.primary,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFE0F2FE),
      onSecondaryContainer: AppColors.secondary,
      tertiary: AppColors.accent,
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFDBEAFE),
      onTertiaryContainer: AppColors.primary,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: Color(0xFFFEE2E2),
      onErrorContainer: AppColors.error,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: AppColors.textPrimary,
      onInverseSurface: Colors.white,
      inversePrimary: AppColors.accent,
      surfaceTint: AppColors.primary,
    );

    return _buildTheme(
      colorScheme: colorScheme,
      scaffoldBackground: AppColors.background,
      cardColor: AppColors.surface,
      inputFill: AppColors.surface,
      chipBackground: AppColors.surfaceTint,
      navigationBackground: AppColors.surface,
      dialogBackground: AppColors.surface,
      snackBarBackground: AppColors.textPrimary,
      dataHeadingRow: AppColors.surfaceTint,
      dataRow: AppColors.surface,
      extension: AppThemeColors.light,
      appBarIconColor: AppColors.textSecondary,
    );
  }

  /// Material 3 dark theme with tonal surfaces (never pure black).
  static ThemeData dark() {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.accent,
      onPrimary: Color(0xFF0B1F44),
      primaryContainer: Color(0xFF1E3A5F),
      onPrimaryContainer: Color(0xFFD6E3FF),
      secondary: AppColors.secondary,
      onSecondary: Color(0xFF00344A),
      secondaryContainer: Color(0xFF004D68),
      onSecondaryContainer: Color(0xFFC8E7FF),
      tertiary: Color(0xFF93C5FD),
      onTertiary: Color(0xFF0B1F44),
      tertiaryContainer: Color(0xFF1E3A5F),
      onTertiaryContainer: Color(0xFFD6E3FF),
      error: Color(0xFFF87171),
      onError: Color(0xFF450A0A),
      errorContainer: Color(0xFF7F1D1D),
      onErrorContainer: Color(0xFFFEE2E2),
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
      onSurfaceVariant: AppColors.darkTextSecondary,
      outline: AppColors.darkOutline,
      outlineVariant: AppColors.darkBorder,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: AppColors.darkTextPrimary,
      onInverseSurface: AppColors.darkBackground,
      inversePrimary: AppColors.primary,
      surfaceTint: AppColors.accent,
      surfaceContainerLowest: AppColors.darkSurface,
      surfaceContainerLow: AppColors.darkSurface,
      surfaceContainer: AppColors.darkSurfaceContainer,
      surfaceContainerHigh: AppColors.darkSurfaceContainerHigh,
      surfaceContainerHighest: AppColors.darkSurfaceContainerHighest,
    );

    return _buildTheme(
      colorScheme: colorScheme,
      scaffoldBackground: AppColors.darkBackground,
      cardColor: AppColors.darkSurfaceContainer,
      inputFill: AppColors.darkSurfaceContainerHigh,
      chipBackground: AppColors.darkSurfaceContainerHigh,
      navigationBackground: AppColors.darkSurface,
      dialogBackground: AppColors.darkSurfaceContainer,
      snackBarBackground: AppColors.darkSurfaceContainerHighest,
      dataHeadingRow: AppColors.darkSurfaceContainerHigh,
      dataRow: AppColors.darkSurfaceContainer,
      extension: AppThemeColors.dark,
      appBarIconColor: AppColors.darkTextSecondary,
    );
  }

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required Color scaffoldBackground,
    required Color cardColor,
    required Color inputFill,
    required Color chipBackground,
    required Color navigationBackground,
    required Color dialogBackground,
    required Color snackBarBackground,
    required Color dataHeadingRow,
    required Color dataRow,
    required AppThemeColors extension,
    required Color appBarIconColor,
  }) {
    final borderSide = BorderSide(color: colorScheme.outlineVariant);
    final outlineShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    );
    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.7)),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackground,
      splashFactory: InkSparkle.splashFactory,
      textTheme: AppTypography.textTheme(colorScheme.brightness).apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
      extensions: [extension],
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: AppSystemUi.overlayFor(
          ThemeData(
            brightness: colorScheme.brightness,
            scaffoldBackgroundColor: scaffoldBackground,
            colorScheme: colorScheme,
          ),
        ),
        iconTheme: IconThemeData(color: appBarIconColor),
        actionsIconTheme: IconThemeData(color: appBarIconColor),
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardColor,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: cardShape,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(
            right: Radius.circular(AppRadius.lg),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        prefixIconColor: colorScheme.onSurfaceVariant,
        suffixIconColor: colorScheme.onSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: borderSide,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: borderSide,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          shape: outlineShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.outline),
          shape: outlineShape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          shape: outlineShape,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: outlineShape,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        focusElevation: 3,
        hoverElevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      iconTheme: IconThemeData(color: colorScheme.onSurfaceVariant, size: 24),
      primaryIconTheme: IconThemeData(color: colorScheme.primary, size: 24),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        space: 1,
        thickness: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: navigationBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 64,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.16),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: navigationBackground,
        elevation: 0,
        // Compact (tablet) rail width — unchanged.
        minWidth: 72,
        // Extended (desktop) rail: slightly wider for long labels.
        minExtendedWidth: 248,
        groupAlignment: -0.95,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.14),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        selectedIconTheme: IconThemeData(
          size: 22,
          color: colorScheme.primary,
        ),
        unselectedIconTheme: IconThemeData(
          size: 22,
          color: colorScheme.onSurfaceVariant,
        ),
        selectedLabelTextStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: colorScheme.primary,
        ),
        unselectedLabelTextStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: dialogBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 14,
          height: 1.45,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: dialogBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        // Light: keep classic dark snackbar. Dark: tonal surface (never near-white).
        backgroundColor: colorScheme.brightness == Brightness.dark
            ? colorScheme.surfaceContainerHigh
            : snackBarBackground,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        actionTextColor: colorScheme.primary,
        disabledActionTextColor:
            colorScheme.onSurface.withValues(alpha: 0.38),
        closeIconColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: chipBackground,
        selectedColor: colorScheme.primary.withValues(alpha: 0.18),
        disabledColor: colorScheme.onSurface.withValues(alpha: 0.08),
        side: BorderSide(color: colorScheme.outlineVariant),
        labelStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 12,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        iconTheme: IconThemeData(
          color: colorScheme.onSurfaceVariant,
          size: 18,
        ),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(dataHeadingRow),
        dataRowColor: WidgetStateProperty.all(dataRow),
        dividerThickness: 1,
        headingTextStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        dataTextStyle: TextStyle(color: colorScheme.onSurface),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.primary.withValues(alpha: 0.12),
        circularTrackColor: colorScheme.primary.withValues(alpha: 0.12),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(colorScheme.onPrimary),
        side: BorderSide(color: colorScheme.outline, width: 1.5),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary.withValues(alpha: 0.35);
          }
          return colorScheme.outline.withValues(alpha: 0.28);
        }),
        trackOutlineColor: WidgetStateProperty.all(colorScheme.outlineVariant),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.onSurfaceVariant;
        }),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        minVerticalPadding: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        textStyle: TextStyle(color: colorScheme.onInverseSurface, fontSize: 12),
      ),
    );
  }
}
