import 'package:mobile/core/localization/l10n/app_localizations.dart';

/// Shared presentation-only duration formatting.
///
/// Hour-based KPIs always use `H:MM` (never decimal hours).
/// Minute-native metrics may use minutes-only when under one hour.
///
/// Does not change stored values or calculations.
class DurationFormatter {
  DurationFormatter._();

  /// Formats a duration expressed in decimal hours as `H:MM`.
  ///
  /// Examples: `0` → `0:00 h`, `0.25` → `0:15 h`, `1.5` → `1:30 h`.
  static String fromHours(num hours, AppLocalizations l10n) {
    final totalMinutes = (hours.toDouble() * 60).round();
    final safe = totalMinutes < 0 ? 0 : totalMinutes;
    final h = safe ~/ 60;
    final m = safe % 60;
    return l10n.durationHoursMinutes(
      h.toString(),
      m.toString().padLeft(2, '0'),
    );
  }

  /// Formats a duration expressed in whole minutes.
  ///
  /// - `0` → hour form (`0:00 h`) for KPI consistency
  /// - under 1 hour → minutes-only (`45 min`) for minute-native metrics
  /// - 1 hour or more → `H:MM`
  static String fromMinutes(int? minutes, AppLocalizations l10n) {
    if (minutes == null) {
      return l10n.valueNotSet;
    }

    final safe = minutes < 0 ? 0 : minutes;
    if (safe == 0) {
      return l10n.durationHoursMinutes('0', '00');
    }
    if (safe < 60) {
      return l10n.durationMinutesOnly(safe);
    }

    final hours = safe ~/ 60;
    final mins = safe % 60;
    return l10n.durationHoursMinutes(
      hours.toString(),
      mins.toString().padLeft(2, '0'),
    );
  }
}
