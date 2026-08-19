import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/services/connectivity_status.dart';
import 'package:mobile/core/theme/app_colors.dart';

/// Compact sticky connectivity indicator for the app shell.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({
    super.key,
    this.snapshot = ConnectivitySnapshot.unknown,
  });

  final ConnectivitySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final message = connectivityStatusMessage(
      AppLocalizations.of(context),
      snapshot,
    );
    if (message == null) {
      return const SizedBox.shrink();
    }

    final warning = AppThemeColors.of(context).warning;
    final theme = Theme.of(context);
    final icon = _iconForLevel(snapshot.level);

    return Material(
      color: warning.withValues(alpha: 0.14),
      elevation: 0,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 32,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(icon, size: 16, color: warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: warning,
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconForLevel(ConnectivityLevel level) {
    return switch (level) {
      ConnectivityLevel.online => Icons.cloud_done_outlined,
      ConnectivityLevel.apiUnavailable => Icons.dns_outlined,
      ConnectivityLevel.internetUnavailable => Icons.wifi_off_outlined,
      ConnectivityLevel.networkUnavailable => Icons.signal_wifi_off_outlined,
      ConnectivityLevel.unknown => Icons.cloud_off_outlined,
    };
  }
}

/// Localized user-facing connectivity label. Returns null when fully online.
String? connectivityStatusMessage(
  AppLocalizations l10n,
  ConnectivitySnapshot snapshot,
) {
  return switch (snapshot.level) {
    ConnectivityLevel.online => null,
    ConnectivityLevel.apiUnavailable => l10n.connectivityApiUnavailable,
    ConnectivityLevel.internetUnavailable => l10n.connectivityNoInternet,
    ConnectivityLevel.networkUnavailable => l10n.connectivityNoNetwork,
    ConnectivityLevel.unknown => l10n.offlineMode,
  };
}

/// Returns true when a failure code represents connectivity (not a product error).
bool isConnectivityFailureCode(String? code) {
  return code == 'OFFLINE' ||
      code == 'TIMEOUT' ||
      code == 'NETWORK_ERROR';
}

/// Hide technical / connectivity text from snackbars and error screens.
bool isUserFacingNetworkNoise(String? message, {String? code}) {
  if (isConnectivityFailureCode(code)) {
    return true;
  }
  if (message == null || message.trim().isEmpty) {
    return true;
  }
  final lower = message.toLowerCase();
  return lower.contains('connection errored') ||
      lower.contains('socketexception') ||
      lower.contains('dioexception') ||
      lower.contains('failed host lookup') ||
      lower.contains('network is unreachable') ||
      lower.contains('connection reset') ||
      lower.contains('connection refused') ||
      lower.contains('no internet') ||
      lower.contains('you are offline') ||
      lower.contains('unable to reach') ||
      lower.contains('request timed out') ||
      lower.contains('clientexception') ||
      message == 'errorNoInternet' ||
      message == 'errorUnableToReachServer' ||
      message == 'errorRequestTimeout';
}

void debugLogNetworkError(Object error, [StackTrace? stackTrace]) {
  if (kDebugMode) {
    debugPrint('Network/debug error: $error');
    if (stackTrace != null) {
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
