import 'package:mobile/core/localization/duration_formatter.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';

class OvertimeFormatters {
  OvertimeFormatters._();

  static String durationFromMinutes(int? minutes, AppLocalizations l10n) {
    return DurationFormatter.fromMinutes(minutes, l10n);
  }

  /// Human-readable worked / approved OT duration (never decimal hours).
  static String hoursValue(double? hours, AppLocalizations l10n) {
    if (hours == null) return '—';
    return DurationFormatter.fromHours(hours, l10n);
  }

  static String coordinates({
    required double latitude,
    required double longitude,
  }) {
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }
}
