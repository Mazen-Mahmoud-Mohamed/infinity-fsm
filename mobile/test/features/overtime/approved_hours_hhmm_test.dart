import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/overtime/presentation/utils/approved_hours_hhmm.dart';

void main() {
  group('ApprovedHoursHhMm', () {
    test('14:30 → 870 minutes → 14.5 API hours (not 14.30 decimal)', () {
      final parsed = ApprovedHoursHhMm.parse('14:30');
      expect(parsed.isValid, isTrue);
      expect(parsed.totalMinutes, 870);
      expect(parsed.apiHours, 14.5);
      expect(ApprovedHoursHhMm.toApiHours(870), isNot(14.30));
    });

    test('10:00 → 600 minutes → 10 API hours', () {
      final parsed = ApprovedHoursHhMm.parse('10:00');
      expect(parsed.totalMinutes, 600);
      expect(parsed.apiHours, 10);
    });

    test('0:30 → 30 minutes → 0.5 API hours', () {
      final parsed = ApprovedHoursHhMm.parse('0:30');
      expect(parsed.totalMinutes, 30);
      expect(parsed.apiHours, 0.5);
    });

    test('rejects invalid minutes such as 14:75', () {
      expect(ApprovedHoursHhMm.parse('14:75').isValid, isFalse);
      expect(ApprovedHoursHhMm.parse('14:60').isValid, isFalse);
    });

    test('rejects empty, decimal-hour, and malformed input', () {
      expect(ApprovedHoursHhMm.parse('').isValid, isFalse);
      expect(ApprovedHoursHhMm.parse(null).isValid, isFalse);
      expect(ApprovedHoursHhMm.parse('14.30').isValid, isFalse);
      expect(ApprovedHoursHhMm.parse('14').isValid, isFalse);
      expect(ApprovedHoursHhMm.parse(':30').isValid, isFalse);
    });

    test('rejects approved duration greater than worked minutes', () {
      final result = ApprovedHoursHhMm.parseAndValidateAgainstWorked(
        raw: '14:30',
        workedMinutes: 800,
      );
      expect(result.isValid, isFalse);
    });

    test('accepts approved duration equal to worked minutes', () {
      final result = ApprovedHoursHhMm.parseAndValidateAgainstWorked(
        raw: '14:30',
        workedMinutes: 870,
      );
      expect(result.isValid, isTrue);
      expect(result.totalMinutes, 870);
    });

    test('formatFromMinutes round-trips common values', () {
      expect(ApprovedHoursHhMm.formatFromMinutes(870), '14:30');
      expect(ApprovedHoursHhMm.formatFromMinutes(600), '10:00');
      expect(ApprovedHoursHhMm.formatFromMinutes(30), '0:30');
      expect(ApprovedHoursHhMm.formatFromMinutes(0), '0:00');
    });
  });
}
