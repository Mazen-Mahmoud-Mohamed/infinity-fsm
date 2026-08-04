import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_rbac.dart';

/// Prefer [RbacLabels.role] / [localizeRoleLabel] for new code.
String userRoleLabel(AppLocalizations l10n, String role) =>
    RbacLabels.role(l10n, role);
