import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/features/notifications/domain/entities/app_notification.dart';

/// Technical audit keys that must not appear in user-facing notification UI.
bool isInternalSystemAuditEvent(String? action) {
  final raw = (action ?? '').trim().toLowerCase();
  if (raw.isEmpty) return false;

  const hiddenExact = {
    'auth.token_refreshed',
    'auth.refresh',
    'auth.token_refresh',
    'keep_alive',
    'ping',
    'heartbeat',
  };
  if (hiddenExact.contains(raw)) return true;

  if (raw.endsWith('.refresh') || raw.endsWith('.token_refreshed')) {
    return true;
  }

  return raw.contains('keep_alive') || raw == 'ping';
}

bool shouldShowUserNotification(AppNotification notification) {
  return !isInternalSystemAuditEvent(notification.title);
}

/// Maps internal audit / notification event keys to user-facing copy.
///
/// Never display raw keys such as `auth.login` or `auth.token_refreshed`.
String localizeAuditEvent(AppLocalizations l10n, String? action) {
  final raw = (action ?? '').trim();
  if (raw.isEmpty) return l10n.eventGenericActivity;

  switch (raw) {
    case 'auth.login':
      return l10n.eventAuthLogin;
    case 'auth.login_failed':
      return l10n.eventAuthLoginFailed;
    case 'auth.logout':
      return l10n.eventAuthLogout;
    case 'auth.token_refreshed':
      return l10n.eventAuthTokenRefreshed;
  }

  final module = raw.contains('.') ? raw.split('.').first.toLowerCase() : '';
  switch (module) {
    case 'auth':
      return l10n.eventAuthGeneric;
    case 'attendance':
      return l10n.eventAttendanceGeneric;
    case 'overtime':
      return l10n.eventOvertimeGeneric;
    case 'work_order':
    case 'work-orders':
    case 'work_orders':
      return l10n.eventWorkOrderGeneric;
    case 'inventory':
      return l10n.eventInventoryGeneric;
    case 'asset':
    case 'assets':
      return l10n.eventAssetsGeneric;
    case 'pm':
    case 'preventive_maintenance':
      return l10n.eventPmGeneric;
    case 'report':
    case 'reports':
      return l10n.eventReportsGeneric;
    case 'user':
    case 'users':
      return l10n.eventUsersGeneric;
    case 'organization':
    case 'org':
      return l10n.eventOrganizationGeneric;
    case 'security':
      return l10n.eventSecurityGeneric;
  }

  // Dotted internal keys must never leak to the UI.
  if (raw.contains('.')) {
    return l10n.eventGenericActivity;
  }

  return raw;
}

String localizeAuditModule(AppLocalizations l10n, String? module) {
  switch ((module ?? '').trim().toLowerCase()) {
    case 'auth':
      return l10n.eventAuthGeneric;
    case 'attendance':
      return l10n.eventAttendanceGeneric;
    case 'overtime':
      return l10n.eventOvertimeGeneric;
    case 'work_order':
    case 'work-orders':
    case 'work_orders':
      return l10n.eventWorkOrderGeneric;
    case 'inventory':
      return l10n.eventInventoryGeneric;
    case 'asset':
    case 'assets':
      return l10n.eventAssetsGeneric;
    case 'pm':
    case 'preventive_maintenance':
      return l10n.eventPmGeneric;
    case 'report':
    case 'reports':
      return l10n.eventReportsGeneric;
    case 'user':
    case 'users':
      return l10n.eventUsersGeneric;
    case 'organization':
    case 'org':
      return l10n.eventOrganizationGeneric;
    case 'security':
      return l10n.eventSecurityGeneric;
    case '':
      return l10n.eventGenericActivity;
    default:
      if ((module ?? '').contains('.')) {
        return l10n.eventGenericActivity;
      }
      return module!;
  }
}

String localizeAuditFeedSubtitle(
  AppLocalizations l10n, {
  required String? module,
  required String? actorName,
}) {
  return l10n.eventFeedActorLine(
    localizeAuditModule(l10n, module),
    (actorName == null || actorName.trim().isEmpty)
        ? l10n.dashboardSystemActor
        : actorName.trim(),
  );
}

String localizeNotificationBody(AppLocalizations l10n, String? body) {
  final raw = (body ?? '').trim();
  if (raw.isEmpty) return l10n.eventGenericActivity;

  final separator = raw.contains(' · ') ? ' · ' : (raw.contains('·') ? '·' : null);
  if (separator != null) {
    final parts = raw.split(separator);
    if (parts.length >= 2) {
      final module = parts.first.trim();
      final actor = parts.sublist(1).join(separator).trim();
      return localizeAuditFeedSubtitle(
        l10n,
        module: module,
        actorName: actor,
      );
    }
  }

  return localizeAuditEvent(l10n, raw);
}
