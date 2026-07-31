import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/theme/app_colors.dart';

class AttendanceOfflineBanner extends StatelessWidget {
  const AttendanceOfflineBanner({
    super.key,
    required this.visible,
    this.pendingCount = 0,
  });

  final bool visible;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    if (!visible && pendingCount == 0) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final warning = AppThemeColors.of(context).warning;
    final message = visible
        ? l10n.attendanceOfflineCachedData
        : l10n.attendancePendingSync(pendingCount);

    return Container(
      width: double.infinity,
      color: warning.withValues(alpha: 0.18),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(
            visible ? Icons.wifi_off : Icons.sync,
            size: 18,
            color: warning,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: warning),
            ),
          ),
        ],
      ),
    );
  }
}
