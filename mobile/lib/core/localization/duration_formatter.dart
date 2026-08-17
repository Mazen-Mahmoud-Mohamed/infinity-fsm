import 'package:mobile/core/localization/l10n/app_localizations.dart';

/// Shared presentation-only duration formatting.
///
/// Displays human-readable hours + minutes (never decimal hours).
/// Does not change stored values or calculations.
class DurationFormatter {
  DurationFormatter._();

  /// Formats a duration expressed in decimal hours.
  ///
  /// Examples: `14.95` → `14 hours 57 minutes`, `0.5` → `30 minutes`.
  static String fromHours(num? hours, AppLocalizations l10n) {
    if (hours == null) {
      return l10n.valueNotSet;
    }
    final totalMinutes = (hours.toDouble() * 60).round();
    return fromMinutes(totalMinutes, l10n);
  }

  /// Formats a duration expressed in whole minutes.
  ///
  /// Examples: `0` → `0 minutes`, `30` → `30 minutes`,
  /// `60` → `1 hour`, `897` → `14 hours 57 minutes`.
  static String fromMinutes(int? minutes, AppLocalizations l10n) {
    if (minutes == null) {
      return l10n.valueNotSet;
    }

    final safe = minutes < 0 ? 0 : minutes;
    final hours = safe ~/ 60;
    final mins = safe % 60;

    if (hours == 0) {
      return l10n.durationMinutesOnly(mins);
    }
    if (mins == 0) {
      return l10n.durationHoursOnly(hours);
    }
    return l10n.durationHoursAndMinutes(hours, mins);
  }

  /// Compact label for chart axes (keeps numeric scaling unchanged).
  ///
  /// Examples: `122.7` → `122:42 h`, `8` → `8 hours`, `0.75` → `45 minutes`.
  static String compactFromHours(num? hours, AppLocalizations l10n) {
    if (hours == null) {
      return l10n.valueNotSet;
    }

    final totalMinutes = (hours.toDouble() * 60).round();
    final safe = totalMinutes < 0 ? 0 : totalMinutes;
    final h = safe ~/ 60;
    final m = safe % 60;

    if (h == 0) {
      return l10n.durationMinutesOnly(m);
    }
    if (m == 0) {
      return l10n.durationHoursOnly(h);
    }
    return l10n.durationHoursMinutes('$h', m.toString().padLeft(2, '0'));
  }
}
