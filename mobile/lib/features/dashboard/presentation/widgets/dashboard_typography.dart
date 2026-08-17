import 'package:flutter/material.dart';

/// Centralized Dashboard text hierarchy.
///
/// Builds on [ThemeData.textTheme] / [AppTypography] — does not introduce a
/// separate font family. Keeps English and Arabic visually equivalent.
class DashboardTypography {
  DashboardTypography._();

  static const double _pageTitleSize = 20;
  static const double _sectionTitleSize = 16.5;
  static const double _kpiValueSize = 18;
  static const double _kpiLabelSize = 11.5;
  static const double _chartTitleSize = 13;
  static const double _chartAxisSize = 10;
  static const double _tableHeaderSize = 11;
  static const double _secondarySize = 12;

  /// App bar / page title — clear but not dominant.
  static TextStyle pageTitle(BuildContext context) {
    final theme = Theme.of(context);
    return (theme.textTheme.titleLarge ?? const TextStyle()).copyWith(
      fontSize: _pageTitleSize,
      fontWeight: FontWeight.w600,
      height: 1.25,
      letterSpacing: -0.2,
      color: theme.colorScheme.onSurface,
    );
  }

  /// "Welcome back," — regular / muted.
  static TextStyle welcome(BuildContext context) {
    final theme = Theme.of(context);
    return (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.35,
      color: theme.colorScheme.onSurfaceVariant,
    );
  }

  /// User name next to welcome — semibold, same line balance.
  static TextStyle welcomeName(BuildContext context) {
    final theme = Theme.of(context);
    return (theme.textTheme.titleMedium ?? const TextStyle()).copyWith(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      height: 1.35,
      color: theme.colorScheme.onSurface,
    );
  }

  /// Panel / section headers (Workforce, Operations, …).
  static TextStyle sectionTitle(BuildContext context) {
    final theme = Theme.of(context);
    return (theme.textTheme.titleSmall ?? const TextStyle()).copyWith(
      fontSize: _sectionTitleSize,
      fontWeight: FontWeight.w600,
      height: 1.3,
      letterSpacing: -0.1,
      color: theme.colorScheme.onSurface,
    );
  }

  /// Primary KPI strip values.
  static TextStyle kpiValue(BuildContext context) {
    final theme = Theme.of(context);
    return (theme.textTheme.titleMedium ?? const TextStyle()).copyWith(
      fontSize: _kpiValueSize,
      fontWeight: FontWeight.w600,
      height: 1.15,
      letterSpacing: -0.15,
      color: theme.colorScheme.onSurface,
    );
  }

  /// KPI / metric labels under values.
  static TextStyle kpiLabel(BuildContext context) {
    final theme = Theme.of(context);
    return (theme.textTheme.labelSmall ?? const TextStyle()).copyWith(
      fontSize: _kpiLabelSize,
      fontWeight: FontWeight.w400,
      height: 1.25,
      letterSpacing: 0.05,
      color: theme.colorScheme.onSurfaceVariant,
    );
  }

  /// Compact overtime / workforce nested KPI values.
  static TextStyle metricValue(BuildContext context) {
    final theme = Theme.of(context);
    return (theme.textTheme.titleSmall ?? const TextStyle()).copyWith(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      height: 1.15,
      color: theme.colorScheme.onSurface,
    );
  }

  static TextStyle body(BuildContext context) {
    final theme = Theme.of(context);
    return (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
      fontSize: 13.5,
      fontWeight: FontWeight.w400,
      height: 1.35,
      color: theme.colorScheme.onSurface,
    );
  }

  static TextStyle secondary(BuildContext context) {
    final theme = Theme.of(context);
    return (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
      fontSize: _secondarySize,
      fontWeight: FontWeight.w400,
      height: 1.3,
      color: theme.colorScheme.onSurfaceVariant,
    );
  }

  /// Operations / Resources row labels.
  static TextStyle listLabel(BuildContext context) {
    final theme = Theme.of(context);
    return (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
      fontSize: 13.5,
      fontWeight: FontWeight.w400,
      height: 1.3,
      color: theme.colorScheme.onSurface,
    );
  }

  /// Operations / Resources row values (right-aligned).
  static TextStyle listValue(BuildContext context, {Color? color}) {
    final theme = Theme.of(context);
    return (theme.textTheme.titleSmall ?? const TextStyle()).copyWith(
      fontSize: 13.5,
      fontWeight: FontWeight.w600,
      height: 1.3,
      color: color ?? theme.colorScheme.onSurface,
    );
  }

  static TextStyle chartTitle(BuildContext context) {
    final theme = Theme.of(context);
    return (theme.textTheme.labelLarge ?? const TextStyle()).copyWith(
      fontSize: _chartTitleSize,
      fontWeight: FontWeight.w500,
      height: 1.25,
      color: theme.colorScheme.onSurface,
    );
  }

  static TextStyle chartAxis(BuildContext context, {bool compact = false}) {
    final theme = Theme.of(context);
    return (theme.textTheme.labelSmall ?? const TextStyle()).copyWith(
      fontSize: compact ? 11.5 : _chartAxisSize,
      fontWeight: FontWeight.w400,
      height: compact ? 1.15 : 1.1,
      color: theme.colorScheme.onSurfaceVariant,
    );
  }

  static TextStyle chartTooltipValue(BuildContext context) {
    final theme = Theme.of(context);
    return (theme.textTheme.labelSmall ?? const TextStyle()).copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      height: 1.25,
      color: theme.colorScheme.onSurface,
    );
  }

  static TextStyle chartMeta(BuildContext context) {
    final theme = Theme.of(context);
    return (theme.textTheme.labelSmall ?? const TextStyle()).copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w400,
      height: 1.2,
      color: theme.colorScheme.onSurfaceVariant,
    );
  }

  static TextStyle chartTooltip(BuildContext context) {
    final theme = Theme.of(context);
    return (theme.textTheme.labelSmall ?? const TextStyle()).copyWith(
      fontSize: 11.5,
      fontWeight: FontWeight.w500,
      height: 1.2,
      color: theme.colorScheme.primary,
    );
  }

  static TextStyle tableHeader(BuildContext context) {
    final theme = Theme.of(context);
    return (theme.textTheme.labelSmall ?? const TextStyle()).copyWith(
      fontSize: _tableHeaderSize,
      fontWeight: FontWeight.w500,
      height: 1.25,
      letterSpacing: 0.1,
      color: theme.colorScheme.onSurfaceVariant,
    );
  }

  static TextStyle tableName(BuildContext context) {
    final theme = Theme.of(context);
    return (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
      fontSize: 13.5,
      fontWeight: FontWeight.w600,
      height: 1.25,
      color: theme.colorScheme.onSurface,
    );
  }

  static TextStyle tableValue(BuildContext context, {Color? color}) {
    final theme = Theme.of(context);
    return (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      height: 1.25,
      color: color ?? theme.colorScheme.onSurface,
    );
  }

  static TextStyle feedTitle(BuildContext context) {
    final theme = Theme.of(context);
    return (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
      fontSize: 13.5,
      fontWeight: FontWeight.w500,
      height: 1.3,
      color: theme.colorScheme.onSurface,
    );
  }

  static TextStyle windowSelector(BuildContext context) {
    final theme = Theme.of(context);
    return (theme.textTheme.labelMedium ?? const TextStyle()).copyWith(
      fontSize: 12.5,
      fontWeight: FontWeight.w500,
      height: 1.2,
    );
  }
}
