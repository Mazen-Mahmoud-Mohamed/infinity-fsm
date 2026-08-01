import 'package:flutter/material.dart';
import 'package:mobile/core/localization/app_formatters.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/features/dashboard/domain/entities/role_dashboard_summary.dart';

/// Locale-aware calendar period range labels for the dashboard.
class DashboardPeriodRange {
  DashboardPeriodRange._();

  /// Resolves the calendar range for [period] on the client (matches backend).
  static ({DateTime from, DateTime to}) resolveLocal({
    required DashboardPeriod period,
    DateTime? customFrom,
    DateTime? customTo,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final todayStart = DateTime(current.year, current.month, current.day);
    final todayEnd = DateTime(
      current.year,
      current.month,
      current.day,
      23,
      59,
      59,
      999,
    );

    switch (period) {
      case DashboardPeriod.today:
        return (from: todayStart, to: todayEnd);
      case DashboardPeriod.week:
        // Monday-start calendar week (matches backend ISO week).
        final weekday = todayStart.weekday; // Mon=1 … Sun=7
        final from = todayStart.subtract(Duration(days: weekday - 1));
        return (from: from, to: todayEnd);
      case DashboardPeriod.month:
        return (
          from: DateTime(current.year, current.month, 1),
          to: todayEnd,
        );
      case DashboardPeriod.year:
        return (
          from: DateTime(current.year, 1, 1),
          to: todayEnd,
        );
      case DashboardPeriod.custom:
        final from = customFrom == null
            ? DateTime(current.year, current.month, 1)
            : DateTime(customFrom.year, customFrom.month, customFrom.day);
        final end = customTo ?? current;
        final to = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);
        return (from: from, to: to);
    }
  }

  /// Short range text, e.g. `Jul 27 – Aug 1` or `Aug 1 – Today`.
  static String formatRange({
    required BuildContext context,
    required DashboardPeriod period,
    required DateTime from,
    required DateTime to,
    DateTime? now,
  }) {
    final l10n = AppLocalizations.of(context);
    final dayFmt = AppFormatters.date(context, 'd MMM');
    final fromLocal = from.toLocal();
    final toLocal = to.toLocal();
    final today = DateUtils.dateOnly(now ?? DateTime.now());

    if (period == DashboardPeriod.today) {
      return dayFmt.format(fromLocal);
    }

    final toIsToday = DateUtils.dateOnly(toLocal) == today;
    final useUntilNow =
        period != DashboardPeriod.custom && toIsToday;
    final toLabel =
        useUntilNow ? l10n.dashboardRangeUntilNow : dayFmt.format(toLocal);

    return l10n.dashboardRangeSpan(dayFmt.format(fromLocal), toLabel);
  }

  /// Full report line, e.g. `Report: Jul 27 – Aug 1`.
  static String formatReportLine({
    required BuildContext context,
    required DashboardPeriod period,
    required DateTime from,
    required DateTime to,
    DateTime? now,
  }) {
    final l10n = AppLocalizations.of(context);
    return l10n.dashboardReportLine(
      formatRange(
        context: context,
        period: period,
        from: from,
        to: to,
        now: now,
      ),
    );
  }
}
