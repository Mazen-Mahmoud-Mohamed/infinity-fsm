import 'package:mobile/core/localization/l10n/app_localizations.dart';

String userRoleLabel(AppLocalizations l10n, String role) {
  switch (role.toUpperCase()) {
    case 'ADMIN':
      return l10n.usersRoleAdmin;
    case 'SUPERVISOR':
      return l10n.usersRoleSupervisor;
    case 'TECHNICIAN':
      return l10n.usersRoleTechnician;
    case 'HR':
      return l10n.usersRoleHr;
    default:
      return role;
  }
}
