import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/core/services/biometric_auth_service.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/features/settings/presentation/pages/server_management_page.dart';
import 'package:mobile/features/settings/presentation/utils/admin_settings_unlock_session.dart';

/// Shared unlock path: admin check → biometric → mark session → [route].
Future<void> openAdminSettingsSecurely(
  BuildContext context, {
  required String route,
  String? signInTitle,
}) async {
  final l10n = AppLocalizations.of(context);
  final user = context.read<AuthCubit>().state.user;

  if (!ServerManagementPage.canAccess(user)) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(l10n.serverMgmtAccessDenied)),
      );
    return;
  }

  final session = getIt<AdminSettingsUnlockSession>();
  if (session.isUnlocked) {
    if (!context.mounted) return;
    context.push(route);
    return;
  }

  final biometric = getIt<BiometricAuthService>();
  final canAuth = await biometric.canAuthenticate();
  if (!context.mounted) return;

  if (!canAuth) {
    // Mobile without device auth: block. Desktop without platform auth: allow
    // admin-gated entry so Windows deployments remain manageable.
    final isDesktop = !kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
    if (!isDesktop) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.serverMgmtBiometricUnavailable)),
        );
      return;
    }
    session.markUnlocked();
    context.push(route);
    return;
  }

  final ok = await biometric.authenticate(
    reason: l10n.serverMgmtBiometricReason,
    cancelButton: l10n.inventoryCancel,
    signInTitle: signInTitle ?? l10n.serverMgmtTitle,
  );
  if (!context.mounted || !ok) {
    return;
  }

  session.markUnlocked();
  context.push(route);
}

/// Shared unlock path: admin check → biometric → Server Management route.
Future<void> openServerManagementSecurely(BuildContext context) {
  return openAdminSettingsSecurely(
    context,
    route: RoutePaths.settingsServer,
  );
}

/// Hidden developer options (same admin + biometric gate).
Future<void> openDeveloperOptionsSecurely(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return openAdminSettingsSecurely(
    context,
    route: RoutePaths.settingsDeveloper,
    signInTitle: l10n.settingsDeveloperOptions,
  );
}

/// Hidden admin application logs (same admin + biometric gate).
Future<void> openAdminLogsSecurely(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return openAdminSettingsSecurely(
    context,
    route: RoutePaths.settingsLogs,
    signInTitle: l10n.settingsAdminLogs,
  );
}

/// Ensures the current route was unlocked; otherwise runs biometric unlock.
///
/// Use on protected Settings pages to block deep-link bypass.
Future<bool> ensureAdminSettingsUnlocked(BuildContext context) async {
  final session = getIt<AdminSettingsUnlockSession>();
  if (session.isUnlocked) return true;

  final l10n = AppLocalizations.of(context);
  final user = context.read<AuthCubit>().state.user;
  if (!ServerManagementPage.canAccess(user)) {
    return false;
  }

  final biometric = getIt<BiometricAuthService>();
  final canAuth = await biometric.canAuthenticate();
  if (!context.mounted) return false;

  if (!canAuth) {
    final isDesktop = !kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
    if (!isDesktop) return false;
    session.markUnlocked();
    return true;
  }

  final ok = await biometric.authenticate(
    reason: l10n.serverMgmtBiometricReason,
    cancelButton: l10n.inventoryCancel,
    signInTitle: l10n.serverMgmtTitle,
  );
  if (!ok) return false;
  session.markUnlocked();
  return true;
}
