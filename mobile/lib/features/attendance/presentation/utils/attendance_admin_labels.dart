import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_status.dart';

String attendanceManagementStatusLabel(
  AppLocalizations l10n,
  AttendanceStatus status,
) {
  switch (status) {
    case AttendanceStatus.clockedIn:
      return l10n.attendanceStatusPresent;
    case AttendanceStatus.onBreak:
      return l10n.attendanceStatusOnBreak;
    case AttendanceStatus.clockedOut:
      return l10n.attendanceStatusCheckedOut;
    case AttendanceStatus.notStarted:
      return l10n.attendanceStatusNotStarted;
  }
}

String attendanceRoleLabel(AppLocalizations l10n, String? role) {
  switch ((role ?? '').toUpperCase()) {
    case 'ADMIN':
      return l10n.usersRoleAdmin;
    case 'SUPERVISOR':
      return l10n.usersRoleSupervisor;
    case 'TECHNICIAN':
      return l10n.usersRoleTechnician;
    case '':
      return l10n.valueNotSet;
    default:
      return role!;
  }
}

String attendanceAddressSnippet(String? fullAddress, {String fallback = '—'}) {
  final text = (fullAddress ?? '').trim();
  if (text.isEmpty) return fallback;
  if (text.length <= 80) return text;
  return '${text.substring(0, 77)}...';
}
