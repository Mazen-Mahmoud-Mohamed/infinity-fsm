import 'package:mobile/features/attendance/domain/entities/attendance_status.dart';
import 'package:mobile/features/attendance/domain/entities/gps_snapshot.dart';

/// Thrown when a requested attendance action violates a business rule.
/// Mirrors the validation enforced server-side in `attendance.service.js`
/// so employees get instant feedback without a round trip.
class AttendanceRuleViolation implements Exception {
  AttendanceRuleViolation(this.message);

  /// Localization message key (or legacy English fallback).
  final String message;

  @override
  String toString() => message;
}

class AttendanceGpsRejected implements Exception {
  AttendanceGpsRejected(this.message, this.accuracy, [this.thresholdMeters]);

  /// Localization key, optionally encoded as
  /// `attendanceGpsAccuracyExceeded:accuracy:threshold`.
  final String message;
  final double accuracy;
  final double? thresholdMeters;

  @override
  String toString() => message;
}

class AttendanceRules {
  AttendanceRules._();

  static void assertCanClockIn(AttendanceStatus status) {
    if (status != AttendanceStatus.notStarted) {
      throw AttendanceRuleViolation('attendanceAlreadyClockedIn');
    }
  }

  static void assertCanClockOut(AttendanceStatus status) {
    if (status == AttendanceStatus.notStarted) {
      throw AttendanceRuleViolation('attendanceMustClockInBeforeOut');
    }
    if (status == AttendanceStatus.onBreak) {
      throw AttendanceRuleViolation('attendanceEndBreakBeforeOut');
    }
    if (status == AttendanceStatus.clockedOut) {
      throw AttendanceRuleViolation('attendanceAlreadyClockedOut');
    }
  }

  static void assertCanStartBreak(AttendanceStatus status) {
    if (status == AttendanceStatus.notStarted) {
      throw AttendanceRuleViolation('attendanceMustClockInBeforeBreak');
    }
    if (status == AttendanceStatus.onBreak) {
      throw AttendanceRuleViolation('attendanceBreakAlreadyInProgress');
    }
    if (status == AttendanceStatus.clockedOut) {
      throw AttendanceRuleViolation('attendanceAlreadyClockedOut');
    }
  }

  static void assertCanEndBreak(AttendanceStatus status) {
    if (status != AttendanceStatus.onBreak) {
      throw AttendanceRuleViolation('attendanceNoActiveBreak');
    }
  }

  static void assertGpsAccuracy(GpsSnapshot gps, double thresholdMeters) {
    if (gps.accuracy > thresholdMeters) {
      throw AttendanceGpsRejected(
        'attendanceGpsAccuracyExceeded:'
        '${gps.accuracy.round()}:${thresholdMeters.round()}',
        gps.accuracy,
        thresholdMeters,
      );
    }
  }
}
