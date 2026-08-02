import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/overtime/domain/services/overtime_calculator.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  tzdata.initializeTimeZones();

  group('OvertimeCalculator (Africa/Cairo)', () {
    late final tz.Location location;

    setUpAll(() {
      location = tz.getLocation(OfficialWorkingHours.timeZoneId);
    });

    /// Wall-clock in Africa/Cairo → absolute instant.
    DateTime at(int year, int month, int day, int hour, [int minute = 0]) {
      return tz.TZDateTime(location, year, month, day, hour, minute);
    }

    test('uses Africa/Cairo company timezone', () {
      expect(OfficialWorkingHours.timeZoneId, 'Africa/Cairo');
      expect(OvertimeCalculator.calculationVersion, 'ot-v4-africa-cairo');
    });

    test('Example A: Sat 04:00 → 12:00', () {
      // 2026-08-01 is Saturday.
      final r = OvertimeCalculator.calculate(
        at(2026, 8, 1, 4),
        at(2026, 8, 1, 12),
      );
      expect(r.totalDurationMinutes, 8 * 60);
      expect(r.workingDurationMinutes, 3 * 60);
      expect(r.eligibleOvertimeMinutes, 5 * 60);
    });

    test('Example B: Sat 14:00 → 18:00', () {
      final r = OvertimeCalculator.calculate(
        at(2026, 8, 1, 14),
        at(2026, 8, 1, 18),
      );
      expect(r.totalDurationMinutes, 4 * 60);
      expect(r.workingDurationMinutes, 3 * 60);
      expect(r.eligibleOvertimeMinutes, 60);
    });

    test('Example C: Sat 18:00 → 23:00', () {
      final r = OvertimeCalculator.calculate(
        at(2026, 8, 1, 18),
        at(2026, 8, 1, 23),
      );
      expect(r.workingDurationMinutes, 0);
      expect(r.eligibleOvertimeMinutes, 5 * 60);
    });

    test('Example D: Sat 07:00 → 08:30', () {
      final r = OvertimeCalculator.calculate(
        at(2026, 8, 1, 7),
        at(2026, 8, 1, 8, 30),
      );
      expect(r.eligibleOvertimeMinutes, 90);
      expect(r.workingDurationMinutes, 0);
    });

    test('Example E: Sat 08:00 → 20:00', () {
      final r = OvertimeCalculator.calculate(
        at(2026, 8, 1, 8),
        at(2026, 8, 1, 20),
      );
      expect(r.workingDurationMinutes, 8 * 60);
      expect(r.eligibleOvertimeMinutes, 4 * 60);
    });

    test('midnight: Sat 22:00 → Sun 04:00', () {
      final r = OvertimeCalculator.calculate(
        at(2026, 8, 1, 22),
        at(2026, 8, 2, 4),
      );
      expect(r.totalDurationMinutes, 6 * 60);
      expect(r.workingDurationMinutes, 0);
      expect(r.eligibleOvertimeMinutes, 6 * 60);
    });

    test('Friday full office window is all eligible', () {
      // 2026-07-31 is a Friday.
      final r = OvertimeCalculator.calculate(
        at(2026, 7, 31, 9),
        at(2026, 7, 31, 17),
      );
      expect(r.totalDurationMinutes, 8 * 60);
      expect(r.workingDurationMinutes, 0);
      expect(r.eligibleOvertimeMinutes, 8 * 60);
    });

    test('Thu 22:00 → Fri 08:00 → 10h eligible', () {
      final r = OvertimeCalculator.calculate(
        at(2026, 7, 30, 22),
        at(2026, 7, 31, 8),
      );
      expect(r.totalDurationMinutes, 10 * 60);
      expect(r.workingDurationMinutes, 0);
      expect(r.eligibleOvertimeMinutes, 10 * 60);
    });

    test('eligible equals total - working', () {
      final r = OvertimeCalculator.calculate(
        at(2026, 8, 1, 3, 15),
        at(2026, 8, 1, 21, 45),
      );
      expect(
        r.eligibleOvertimeMinutes,
        r.totalDurationMinutes - r.workingDurationMinutes,
      );
    });
  });
}
