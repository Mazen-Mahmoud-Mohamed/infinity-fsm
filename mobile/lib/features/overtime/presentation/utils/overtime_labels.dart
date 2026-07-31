import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_status.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_type.dart';

String overtimeStatusLabel(AppLocalizations l10n, OvertimeStatus status) {
  switch (status) {
    case OvertimeStatus.running:
      return l10n.overtimeStatusRunning;
    case OvertimeStatus.pendingReview:
      return l10n.overtimeStatusPendingReview;
    case OvertimeStatus.approved:
      return l10n.overtimeStatusApproved;
    case OvertimeStatus.rejected:
      return l10n.overtimeStatusRejected;
    case OvertimeStatus.cancelled:
      return l10n.overtimeStatusCancelled;
  }
}

String overtimeTypeLabel(AppLocalizations l10n, OvertimeType type) {
  switch (type) {
    case OvertimeType.normal:
      return l10n.overtimeTypeNormal;
    case OvertimeType.travel:
      return l10n.overtimeTypeTravel;
  }
}