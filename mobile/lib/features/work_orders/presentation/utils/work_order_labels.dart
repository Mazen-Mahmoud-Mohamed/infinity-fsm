import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order_priority.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order_status.dart';

String workOrderStatusLabel(AppLocalizations l10n, WorkOrderStatus status) {
  switch (status) {
    case WorkOrderStatus.pending:
      return l10n.workOrderStatusPending;
    case WorkOrderStatus.assigned:
      return l10n.workOrderStatusAssigned;
    case WorkOrderStatus.accepted:
      return l10n.workOrderStatusAccepted;
    case WorkOrderStatus.rejected:
      return l10n.workOrderStatusRejected;
    case WorkOrderStatus.inProgress:
      return l10n.workOrderStatusInProgress;
    case WorkOrderStatus.completed:
      return l10n.workOrderStatusCompleted;
    case WorkOrderStatus.cancelled:
      return l10n.workOrderStatusCancelled;
  }
}

String workOrderPriorityLabel(
  AppLocalizations l10n,
  WorkOrderPriority priority,
) {
  switch (priority) {
    case WorkOrderPriority.low:
      return l10n.workOrderPriorityLow;
    case WorkOrderPriority.medium:
      return l10n.workOrderPriorityMedium;
    case WorkOrderPriority.high:
      return l10n.workOrderPriorityHigh;
    case WorkOrderPriority.critical:
      return l10n.workOrderPriorityCritical;
  }
}

String workOrderTimelineTypeLabel(
  AppLocalizations l10n,
  WorkOrderTimelineType type,
) {
  switch (type) {
    case WorkOrderTimelineType.created:
      return l10n.workOrderTimelineCreated;
    case WorkOrderTimelineType.assigned:
      return l10n.workOrderTimelineAssigned;
    case WorkOrderTimelineType.accepted:
      return l10n.workOrderTimelineAccepted;
    case WorkOrderTimelineType.rejected:
      return l10n.workOrderTimelineRejected;
    case WorkOrderTimelineType.started:
      return l10n.workOrderTimelineStarted;
    case WorkOrderTimelineType.completed:
      return l10n.workOrderTimelineCompleted;
    case WorkOrderTimelineType.cancelled:
      return l10n.workOrderTimelineCancelled;
  }
}
