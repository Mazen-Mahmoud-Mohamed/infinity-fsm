import 'package:flutter/material.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order_priority.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order_status.dart';
import 'package:mobile/features/work_orders/presentation/utils/work_order_labels.dart';

class WorkOrderStatusBadge extends StatelessWidget {
  const WorkOrderStatusBadge({super.key, required this.status});

  final WorkOrderStatus status;

  Color _color(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final semantic = AppThemeColors.of(context);
    switch (status) {
      case WorkOrderStatus.pending:
        return colors.onSurfaceVariant;
      case WorkOrderStatus.assigned:
        return semantic.info;
      case WorkOrderStatus.accepted:
        return semantic.success;
      case WorkOrderStatus.rejected:
        return colors.error;
      case WorkOrderStatus.inProgress:
        return semantic.warning;
      case WorkOrderStatus.completed:
        return semantic.success;
      case WorkOrderStatus.cancelled:
        return colors.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = _color(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        workOrderStatusLabel(l10n, status),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class WorkOrderPriorityBadge extends StatelessWidget {
  const WorkOrderPriorityBadge({super.key, required this.priority});

  final WorkOrderPriority priority;

  Color _color(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final semantic = AppThemeColors.of(context);
    switch (priority) {
      case WorkOrderPriority.low:
        return colors.onSurfaceVariant;
      case WorkOrderPriority.medium:
        return semantic.info;
      case WorkOrderPriority.high:
        return semantic.warning;
      case WorkOrderPriority.critical:
        return colors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = _color(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        workOrderPriorityLabel(l10n, priority),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
