export 'overtime_calculator.dart';

/// Legacy alias — prefer [OfficialWorkingHours.current] / [OvertimeCalculator].
class OvertimeRules {
  OvertimeRules._();

  static const int officialStartHour = 9;
  static const int officialEndHour = 17;
}
