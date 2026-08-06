import 'package:mobile/core/localization/duration_formatter.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';

class OvertimeFormatters {
  OvertimeFormatters._();

  static String durationFromMinutes(int? minutes, AppLocalizations l10n) {
    return DurationFormatter.fromMinutes(minutes, l10n);
  }

  /// Decimal hours for worked / approved OT display (e.g. `10` or `10.5`).
  static String hoursValue(double? hours) {
    if (hours == null) return '—';
    if (hours == hours.roundToDouble()) {
      return hours.toInt().toString();
    }
    return hours.toStringAsFixed(2);
  }

  static String coordinates({
    required double latitude,
    required double longitude,
  }) {
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }
}
