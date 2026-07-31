import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/theme/app_colors.dart';

/// Compact sticky Offline Mode indicator. Use once at the app shell level.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({
    super.key,
    this.visible = true,
  });

  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return const SizedBox.shrink();
    }

    final warning = AppThemeColors.of(context).warning;
    final theme = Theme.of(context);

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
                Icon(Icons.cloud_off_outlined, size: 16, color: warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).offlineMode,
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
