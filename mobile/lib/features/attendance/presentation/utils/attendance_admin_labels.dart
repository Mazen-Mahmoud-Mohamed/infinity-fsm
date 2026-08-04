import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_rbac.dart';
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
  if ((role ?? '').trim().isEmpty) {
    return l10n.valueNotSet;
  }
  return localizeRoleLabel(l10n, role);
}

String attendanceAddressSnippet(String? fullAddress, {String fallback = '—'}) {
  final text = (fullAddress ?? '').trim();
  if (text.isEmpty) return fallback;
  if (text.length <= 80) return text;
  return '${text.substring(0, 77)}...';
}
