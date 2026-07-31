import 'package:flutter/material.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_status.dart';
import 'package:mobile/features/overtime/presentation/utils/overtime_labels.dart';

class OvertimeStatusBadge extends StatelessWidget {
  const OvertimeStatusBadge({super.key, required this.status});

  final OvertimeStatus status;

  Color _color(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final semantic = AppThemeColors.of(context);
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
        overtimeStatusLabel(AppLocalizations.of(context), status),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
