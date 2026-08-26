import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_app_message.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_type.dart';

/// Technician-only overtime presentation labels.
///
/// Arabic strings omit "الإضافي" / "إضافي" from overtime wording while
/// shared admin/supervisor keys remain unchanged.
String overtimeTechnicianTypeLabel(
  AppLocalizations l10n,
  OvertimeType type,
) {
  switch (type) {
    case OvertimeType.normal:
      return l10n.overtimeTechnicianTypeNormal;
    case OvertimeType.travel:
      return l10n.overtimeTechnicianTypeTravel;
  }
}

/// Maps overtime feedback keys to technician presentation strings.
String localizeTechnicianOvertimeMessage(
  AppLocalizations l10n,
  String? message, {
  String? code,
}) {
  final key = (code != null && code.isNotEmpty) ? code : message;
  if (key == null || key.isEmpty) {
    return localizeAppMessage(l10n, message, code: code);
  }

  switch (key) {
    case 'overtimeEnded':
      return l10n.overtimeTechnicianEnded;
    case 'normalOvertimeStarted':
      return l10n.overtimeTechnicianNormalStarted;
    case 'travelOvertimeStarted':
      return l10n.overtimeTechnicianTravelStarted;
    case 'overtimeContinueExistingSession':
      return l10n.overtimeTechnicianContinueExistingSession;
    case 'overtimeActiveSessionReminder':
      return l10n.overtimeTechnicianActiveSessionReminder;
    case 'overtimeLoadFailed':
      return l10n.overtimeTechnicianLoadFailed;
    case 'OVERTIME_NOT_FOUND':
    case 'errorOvertimeNotFound':
      return l10n.overtimeTechnicianErrorNotFound;
    case 'overtimeNoRunningSession':
      return l10n.overtimeTechnicianNoRunningSession;
    default:
      return localizeAppMessage(l10n, message, code: code);
  }
}
