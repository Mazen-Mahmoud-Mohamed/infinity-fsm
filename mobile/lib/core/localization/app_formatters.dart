import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Locale-aware date/number formatters for user-visible values.
///
/// Clock times are always shown in **12-hour** form (never `HH:mm`).
class AppFormatters {
  AppFormatters._();

  static String localeName(BuildContext context) =>
      Localizations.localeOf(context).toString();

  static DateFormat date(BuildContext context, String pattern) =>
      DateFormat(pattern, localeName(context));

  /// Medium date: 31 Jul 2026 / ٣١ يوليو ٢٠٢٦
  static DateFormat mediumDate(BuildContext context) =>
      date(context, 'dd MMM yyyy');

  /// Medium date + 12-hour time (e.g. 31 Jul 2026, 4:35 PM)
  static DateFormat mediumDateTime(BuildContext context) =>
      date(context, 'dd MMM yyyy, h:mm a');

  /// Medium date + 12-hour time (space separator)
  static DateFormat mediumDateTimeSpaced(BuildContext context) =>
      date(context, 'dd MMM yyyy h:mm a');

  /// Weekday + month day: Fri, Jul 31
  static DateFormat weekdayMonthDay(BuildContext context) =>
      date(context, 'EEE, MMM d');

  /// Localized 12-hour time (e.g. 5:30 PM / ٥:٣٠ م)
  static DateFormat jm(BuildContext context) =>
      DateFormat.jm(localeName(context));

  /// Localized 12-hour time — same as [jm] (24-hour display is not used).
  static DateFormat hm(BuildContext context) => jm(context);

  static String formatDecimal(
    BuildContext context,
    num value, {
    int fractionDigits = 2,
  }) {
    return NumberFormat.decimalPatternDigits(
      locale: localeName(context),
      decimalDigits: fractionDigits,
    ).format(value);
  }

  static String formatDecimalOrInt(BuildContext context, num value) {
    if (value is int || value == value.roundToDouble()) {
      return NumberFormat.decimalPattern(localeName(context)).format(value.round());
    }
    return formatDecimal(context, value, fractionDigits: 1);
  }

  static String formatCoordinates(
    BuildContext context, {
    required double latitude,
    required double longitude,
    int fractionDigits = 5,
  }) {
    final lat = formatDecimal(context, latitude, fractionDigits: fractionDigits);
    final lng =
        formatDecimal(context, longitude, fractionDigits: fractionDigits);
    return '$lat, $lng';
  }
}
