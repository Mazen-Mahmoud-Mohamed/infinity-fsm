import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/overtime/domain/services/overtime_calculator.dart';

void main() {
  group('OvertimeCalculator', () {
    DateTime at(int hour, [int minute = 0, int day = 1]) =>
        DateTime(2026, 8, day, hour, minute);

    test('Example A: 04:00 → 12:00', () {
      final r = OvertimeCalculator.calculate(at(4), at(12));
      expect(r.totalDurationMinutes, 8 * 60);
      expect(r.workingDurationMinutes, 3 * 60);
      expect(r.eligibleOvertimeMinutes, 5 * 60);
    });

    test('Example B: 14:00 → 18:00', () {
      final r = OvertimeCalculator.calculate(at(14), at(18));
      expect(r.totalDurationMinutes, 4 * 60);
      expect(r.workingDurationMinutes, 3 * 60);
      expect(r.eligibleOvertimeMinutes, 60);
    });

    test('Example C: 18:00 → 23:00', () {
      final r = OvertimeCalculator.calculate(at(18), at(23));
      expect(r.workingDurationMinutes, 0);
      expect(r.eligibleOvertimeMinutes, 5 * 60);
    });

    test('Example D: 07:00 → 08:30', () {
      final r = OvertimeCalculator.calculate(at(7), at(8, 30));
      expect(r.eligibleOvertimeMinutes, 90);
      expect(r.workingDurationMinutes, 0);
    });

    test('Example E: 08:00 → 20:00', () {
      final r = OvertimeCalculator.calculate(at(8), at(20));
      expect(r.workingDurationMinutes, 8 * 60);
      expect(r.eligibleOvertimeMinutes, 4 * 60);
    });

    test('midnight: 22:00 → 04:00 next day', () {
      final r = OvertimeCalculator.calculate(at(22), at(4, 0, 2));
      expect(r.totalDurationMinutes, 6 * 60);
      expect(r.workingDurationMinutes, 0);
      expect(r.eligibleOvertimeMinutes, 6 * 60);
    });

    test('eligible equals total - working', () {
      final r = OvertimeCalculator.calculate(at(3, 15), at(21, 45));
      expect(
        r.eligibleOvertimeMinutes,
        r.totalDurationMinutes - r.workingDurationMinutes,
      );
    });
  });
}
