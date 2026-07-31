import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Locale-aware date/number formatters for user-visible values.
class AppFormatters {
  AppFormatters._();

  static String localeName(BuildContext context) =>
      Localizations.localeOf(context).toString();

  static DateFormat date(BuildContext context, String pattern) =>
      DateFormat(pattern, localeName(context));

  /// Medium date: 31 Jul 2026 / ٣١ يوليو ٢٠٢٦
  static DateFormat mediumDate(BuildContext context) =>
      date(context, 'dd MMM yyyy');

  /// Medium date + time
  static DateFormat mediumDateTime(BuildContext context) =>
      date(context, 'dd MMM yyyy, HH:mm');

  /// Medium date + time (space separator)
  static DateFormat mediumDateTimeSpaced(BuildContext context) =>
      date(context, 'dd MMM yyyy HH:mm');

  /// Weekday + month day: Fri, Jul 31
  static DateFormat weekdayMonthDay(BuildContext context) =>
      date(context, 'EEE, MMM d');

  /// Localized time (e.g. 5:30 PM / ٥:٣٠ م)
  static DateFormat jm(BuildContext context) =>
      DateFormat.jm(localeName(context));

  /// 24h time
  static DateFormat hm(BuildContext context) =>
      DateFormat('HH:mm', localeName(context));

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
