import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/overtime/domain/services/overtime_calculator.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  tzdata.initializeTimeZones();

  group('OvertimeCalculator full-day holiday semantics', () {
    late final tz.Location location;

    setUpAll(() {
      location = tz.getLocation(OfficialWorkingHours.timeZoneId);
    });

    DateTime at(int year, int month, int day, int hour, [int minute = 0]) {
      return tz.TZDateTime(location, year, month, day, hour, minute);
    }

    // 2026-09-18 Friday; 2026-09-19 Saturday holiday; 2026-09-20 Sunday working

    test('1. Friday 00:00–24:00 => 24h eligible', () {
      final r = OvertimeCalculator.calculate(
        at(2026, 9, 18, 0),
        at(2026, 9, 19, 0),
      );
      expect(r.workingDurationMinutes, 0);
      expect(r.eligibleOvertimeMinutes, 24 * 60);
    });

    test('2. Custom holiday 00:00–24:00 => 24h eligible', () {
      final r = OvertimeCalculator.calculate(
        at(2026, 9, 19, 0),
        at(2026, 9, 20, 0),
        customHolidayDates: {'2026-09-19'},
      );
      expect(r.workingDurationMinutes, 0);
      expect(r.eligibleOvertimeMinutes, 24 * 60);
    });

    test('3. Custom holiday 08:00–18:00 => 10h eligible', () {
      final r = OvertimeCalculator.calculate(
        at(2026, 9, 19, 8),
        at(2026, 9, 19, 18),
        customHolidayDates: {'2026-09-19'},
      );
      expect(r.totalDurationMinutes, 10 * 60);
      expect(r.workingDurationMinutes, 0);
      expect(r.eligibleOvertimeMinutes, 10 * 60);
    });

    test('4. Custom holiday 09:00–17:00 => 8h eligible', () {
      final r = OvertimeCalculator.calculate(
        at(2026, 9, 19, 9),
        at(2026, 9, 19, 17),
        customHolidayDates: {'2026-09-19'},
      );
      expect(r.eligibleOvertimeMinutes, 8 * 60);
      expect(r.workingDurationMinutes, 0);
    });

    test('5. Custom holiday 12:00–14:00 => 2h eligible', () {
      final r = OvertimeCalculator.calculate(
        at(2026, 9, 19, 12),
        at(2026, 9, 19, 14),
        customHolidayDates: {'2026-09-19'},
      );
      expect(r.eligibleOvertimeMinutes, 2 * 60);
    });

    test('6. Normal weekday 08:00–18:00 => 2h eligible', () {
      final r = OvertimeCalculator.calculate(
        at(2026, 9, 19, 8),
        at(2026, 9, 19, 18),
      );
      expect(r.workingDurationMinutes, 8 * 60);
      expect(r.eligibleOvertimeMinutes, 2 * 60);
    });

    test('7. Normal weekday 09:00–17:00 => 0h eligible', () {
      final r = OvertimeCalculator.calculate(
        at(2026, 9, 19, 9),
        at(2026, 9, 19, 17),
      );
      expect(r.eligibleOvertimeMinutes, 0);
    });

    test('8. Normal weekday 12:00–14:00 => 0h eligible', () {
      final r = OvertimeCalculator.calculate(
        at(2026, 9, 19, 12),
        at(2026, 9, 19, 14),
      );
      expect(r.eligibleOvertimeMinutes, 0);
    });

    test('9. Friday + custom holiday => no double counting', () {
      final r = OvertimeCalculator.calculate(
        at(2026, 9, 18, 0),
        at(2026, 9, 19, 0),
        customHolidayDates: {'2026-09-18'},
      );
      expect(r.eligibleOvertimeMinutes, 24 * 60);
      expect(r.workingDurationMinutes, 0);
    });

    test('10. Multi-day holiday + next normal day', () {
      // Sat holiday 20:00 → Sun 10:00: 4h + 9h eligible, 1h working
      final r = OvertimeCalculator.calculate(
        at(2026, 9, 19, 20),
        at(2026, 9, 20, 10),
        customHolidayDates: {'2026-09-19'},
      );
      expect(r.totalDurationMinutes, 14 * 60);
      expect(r.workingDurationMinutes, 60);
      expect(r.eligibleOvertimeMinutes, 13 * 60);
    });

    test('12. mirrors backend: empty cache keeps Friday-only', () {
      final r = OvertimeCalculator.calculate(
        at(2026, 9, 19, 8),
        at(2026, 9, 19, 18),
        customHolidayDates: {},
      );
      expect(r.eligibleOvertimeMinutes, 2 * 60);
    });
  });
}
