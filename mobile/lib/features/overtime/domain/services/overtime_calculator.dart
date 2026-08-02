/// Official company working hours — single source of truth on the client.
///
/// Must stay aligned with backend `working-hours.policy.js`.
/// Window is half-open: [start, end) so 17:00 is outside working hours.
class OfficialWorkingHours {
  const OfficialWorkingHours({
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
  });

  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;

  int get startMinutesOfDay => startHour * 60 + startMinute;

  int get endMinutesOfDay => endHour * 60 + endMinute;

  /// Current company defaults: 09:00 → 17:00.
  static const OfficialWorkingHours current = OfficialWorkingHours(
    startHour: 9,
    startMinute: 0,
    endHour: 17,
    endMinute: 0,
  );
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
/// Eligible OT = session time outside [OfficialWorkingHours].
/// Working duration = overlap with official hours.
/// Eligible = Total − Working.
///
/// Uses the wall-clock of the provided [DateTime] values (callers should pass
/// the same timeline used for the session, typically local / recorded instants).
/// Online sessions trust the backend; this calculator is for offline / preview
/// consistency with the same algorithm.
class OvertimeCalculator {
  OvertimeCalculator._();

  static const String calculationVersion = 'ot-v2-outside-official-hours';

  static OvertimeDurationResult calculate(
    DateTime startAt,
    DateTime endAt, {
    OfficialWorkingHours hours = OfficialWorkingHours.current,
  }) {
    if (!endAt.isAfter(startAt)) {
      return const OvertimeDurationResult(
        totalDurationMinutes: 0,
        workingDurationMinutes: 0,
        eligibleOvertimeMinutes: 0,
      );
    }

    final start = startAt.toLocal();
    final end = endAt.toLocal();

    final totalMs = end.difference(start).inMilliseconds;
    final totalDurationMinutes = totalMs <= 0 ? 0 : totalMs ~/ 60000;

    var workingMs = 0;
    var cursor = DateTime(start.year, start.month, start.day);
    final lastDay = DateTime(end.year, end.month, end.day);

    while (!cursor.isAfter(lastDay)) {
      workingMs += _workingOverlapMsForDay(start, end, cursor, hours);
      cursor = cursor.add(const Duration(days: 1));
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
    DateTime sessionStart,
    DateTime sessionEnd,
    DateTime day,
    OfficialWorkingHours hours,
  ) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final officialStart = DateTime(
      day.year,
      day.month,
      day.day,
      hours.startHour,
      hours.startMinute,
    );
    final officialEnd = DateTime(
      day.year,
      day.month,
      day.day,
      hours.endHour,
      hours.endMinute,
    );

    final segmentStart = sessionStart.isAfter(dayStart) ? sessionStart : dayStart;
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
