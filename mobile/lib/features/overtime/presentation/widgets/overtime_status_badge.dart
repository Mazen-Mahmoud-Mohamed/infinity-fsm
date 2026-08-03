import 'package:flutter/material.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_status.dart';
import 'package:mobile/features/overtime/presentation/utils/overtime_labels.dart';

class OvertimeStatusBadge extends StatelessWidget {
  const OvertimeStatusBadge({
    super.key,
    required this.status,
    this.pendingSync = false,
  });

  final OvertimeStatus status;

  /// Offline session waiting for upload — takes precedence over [status].
  final bool pendingSync;

  Color _color(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final semantic = AppThemeColors.of(context);
    if (pendingSync) {
      return semantic.warning;
    }
    switch (status) {
      case OvertimeStatus.running:
        return semantic.info;
      case OvertimeStatus.pendingReview:
        return semantic.warning;
      case OvertimeStatus.approved:
        return semantic.success;
      case OvertimeStatus.rejected:
        return colors.error;
      case OvertimeStatus.cancelled:
        return colors.onSurfaceVariant;
    }
  }

  String _label(AppLocalizations l10n) {
    if (pendingSync) {
      return l10n.overtimeStatusPendingSync;
    }
    return overtimeStatusLabel(l10n, status);
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _label(AppLocalizations.of(context)),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
