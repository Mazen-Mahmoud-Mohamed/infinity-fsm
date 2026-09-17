import 'package:mobile/core/utils/timezone_bootstrap.dart';
import 'package:timezone/timezone.dart' as tz;

/// Official company working hours — single source of truth on the client.
///
/// Must stay aligned with backend `working-hours.policy.js`.
/// Window is half-open: [start, end) so 17:00 is outside working hours.
///
/// Working days: Saturday–Thursday in [timeZoneId].
/// Friday is NOT a working day — all Friday time is eligible overtime.
///
/// Business calendar days always use [timeZoneId] (`Africa/Cairo`), never the
/// device / server process timezone.
class OfficialWorkingHours {
  const OfficialWorkingHours({
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    this.customHolidayDates = const <String>{},
  });

  /// Company IANA timezone (Cairo, Egypt).
  static const String timeZoneId = 'Africa/Cairo';

  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;

  /// Gregorian YYYY-MM-DD Cairo calendar keys for company official holidays.
  final Set<String> customHolidayDates;

  int get startMinutesOfDay => startHour * 60 + startMinute;

  int get endMinutesOfDay => endHour * 60 + endMinute;

  /// Current company defaults: 09:00 → 17:00 Africa/Cairo.
  static const OfficialWorkingHours current = OfficialWorkingHours(
    startHour: 9,
    startMinute: 0,
    endHour: 17,
    endMinute: 0,
  );

  OfficialWorkingHours withCustomHolidayDates(Iterable<String> dates) {
    return OfficialWorkingHours(
      startHour: startHour,
      startMinute: startMinute,
      endHour: endHour,
      endMinute: endMinute,
      customHolidayDates: Set<String>.unmodifiable(
        dates.map((d) => d.trim()).where((d) => d.isNotEmpty),
      ),
    );
  }

  /// Friday has no official working hours (Cairo calendar weekday).
  /// Custom company holidays are an additional non-working condition —
  /// identical semantics to Friday: no 09:00–17:00 window; all session
  /// overlap on that calendar day is overtime-eligible (up to 24h).
  static bool isOfficialWorkingDay(
    DateTime day, {
    Set<String>? customHolidayDates,
  }) {
    if (day.weekday == DateTime.friday) return false;
    final holidays = customHolidayDates;
    if (holidays != null && holidays.isNotEmpty) {
      final key =
          '${day.year.toString().padLeft(4, '0')}-'
          '${day.month.toString().padLeft(2, '0')}-'
          '${day.day.toString().padLeft(2, '0')}';
      if (holidays.contains(key)) return false;
    }
    return true;
  }

  /// Friday OR custom holiday — full non-working calendar day.
  static bool isNonWorkingCalendarDay(
    DateTime day, {
    Set<String>? customHolidayDates,
  }) =>
      !isOfficialWorkingDay(day, customHolidayDates: customHolidayDates);
}

/// Result of [OvertimeCalculator.calculate].
class OvertimeDurationResult {
  const OvertimeDurationResult({
    required this.totalDurationMinutes,
    required this.workingDurationMinutes,
    required this.eligibleOvertimeMinutes,
  });

  final int totalDurationMinutes;
  final int workingDurationMinutes;
  final int eligibleOvertimeMinutes;
}

/// Shared overtime duration calculator (Flutter).
///
/// Eligible OT = session time outside official hours on working days,
/// plus **all** time on Friday — evaluated in [OfficialWorkingHours.timeZoneId].
/// Working duration = overlap with [09:00, 17:00) on Sat–Thu only.
/// Eligible = Total − Working.
///
/// Online / synced sessions trust backend values. This calculator is for
/// offline end preview only and must not overwrite migrated server values.
class OvertimeCalculator {
  OvertimeCalculator._();

  static const String calculationVersion = 'ot-v4-africa-cairo';

  static tz.Location get _cairo {
    ensureTimeZonesInitialized();
    return tz.getLocation(OfficialWorkingHours.timeZoneId);
  }

  static OvertimeDurationResult calculate(
    DateTime startAt,
    DateTime endAt, {
    OfficialWorkingHours hours = OfficialWorkingHours.current,
    Set<String>? customHolidayDates,
  }) {
    final effectiveHours = customHolidayDates == null
        ? hours
        : hours.withCustomHolidayDates(customHolidayDates);
    if (!endAt.isAfter(startAt)) {
      return const OvertimeDurationResult(
        totalDurationMinutes: 0,
        workingDurationMinutes: 0,
        eligibleOvertimeMinutes: 0,
      );
    }

    final location = _cairo;
    final start = tz.TZDateTime.from(startAt.toUtc(), location);
    final end = tz.TZDateTime.from(endAt.toUtc(), location);

    final totalMs = end.difference(start).inMilliseconds;
    final totalDurationMinutes = totalMs <= 0 ? 0 : totalMs ~/ 60000;

    var workingMs = 0;
    var cursor = tz.TZDateTime(location, start.year, start.month, start.day);
    final lastDay = tz.TZDateTime(location, end.year, end.month, end.day);

    while (!cursor.isAfter(lastDay)) {
      workingMs += _workingOverlapMsForDay(
        start,
        end,
        cursor,
        effectiveHours,
        location,
      );
      cursor = tz.TZDateTime(
        location,
        cursor.year,
        cursor.month,
        cursor.day + 1,
      );
    }

    final workingDurationMinutes = workingMs <= 0 ? 0 : workingMs ~/ 60000;
    final eligibleOvertimeMinutes =
        (totalDurationMinutes - workingDurationMinutes).clamp(0, 1 << 30);

    return OvertimeDurationResult(
      totalDurationMinutes: totalDurationMinutes,
      workingDurationMinutes: workingDurationMinutes,
      eligibleOvertimeMinutes: eligibleOvertimeMinutes,
    );
  }

  static int _workingOverlapMsForDay(
    tz.TZDateTime sessionStart,
    tz.TZDateTime sessionEnd,
    tz.TZDateTime day,
    OfficialWorkingHours hours,
    tz.Location location,
  ) {
    if (!OfficialWorkingHours.isOfficialWorkingDay(
      day,
      customHolidayDates: hours.customHolidayDates,
    )) {
      // Friday / custom holiday: no official window → 0 working ms so the
      // entire day segment is overtime-eligible (eligible = total − working).
      return 0;
    }

    final dayStart = tz.TZDateTime(location, day.year, day.month, day.day);
    final dayEnd = tz.TZDateTime(location, day.year, day.month, day.day + 1);
    final officialStart = tz.TZDateTime(
      location,
      day.year,
      day.month,
      day.day,
      hours.startHour,
      hours.startMinute,
    );
    final officialEnd = tz.TZDateTime(
      location,
      day.year,
      day.month,
      day.day,
      hours.endHour,
      hours.endMinute,
    );

    final segmentStart =
        sessionStart.isAfter(dayStart) ? sessionStart : dayStart;
    final segmentEnd = sessionEnd.isBefore(dayEnd) ? sessionEnd : dayEnd;
    if (!segmentEnd.isAfter(segmentStart)) {
      return 0;
    }

    final overlapStart =
        segmentStart.isAfter(officialStart) ? segmentStart : officialStart;
    final overlapEnd =
        segmentEnd.isBefore(officialEnd) ? segmentEnd : officialEnd;
    if (!overlapEnd.isAfter(overlapStart)) {
      return 0;
    }

    return overlapEnd.difference(overlapStart).inMilliseconds;
  }
}
