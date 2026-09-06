import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/utils/timezone_bootstrap.dart';
import 'package:mobile/features/overtime/domain/services/overtime_calculator.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  group('ensureTimeZonesInitialized', () {
    setUp(() {
      resetTimeZonesInitializedForTest();
    });

    test('is idempotent and enables OvertimeCalculator', () {
      ensureTimeZonesInitialized();
      ensureTimeZonesInitialized();
      ensureTimeZonesInitialized();

      final location = tz.getLocation(OfficialWorkingHours.timeZoneId);
      final start = tz.TZDateTime(location, 2026, 8, 1, 4);
      final end = tz.TZDateTime(location, 2026, 8, 1, 12);
      final result = OvertimeCalculator.calculate(start, end);

      expect(result.totalDurationMinutes, 8 * 60);
    });

    test('OvertimeCalculator lazy-inits without prior ensure call', () {
      resetTimeZonesInitializedForTest();
      final location = () {
        ensureTimeZonesInitialized();
        return tz.getLocation(OfficialWorkingHours.timeZoneId);
      }();
      // Reset again so calculate must re-init via _cairo.
      resetTimeZonesInitializedForTest();

      final start = tz.TZDateTime(location, 2026, 8, 1, 4);
      final end = tz.TZDateTime(location, 2026, 8, 1, 5);
      // calculate → _cairo → ensureTimeZonesInitialized
      final result = OvertimeCalculator.calculate(start, end);
      expect(result.totalDurationMinutes, 60);
    });
  });
}
