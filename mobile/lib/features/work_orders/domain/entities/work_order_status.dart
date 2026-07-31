enum WorkOrderStatus {
  pending,
  assigned,
  accepted,
  rejected,
  inProgress,
  completed,
  cancelled;

  static WorkOrderStatus fromApi(String value) {
    switch (value.toUpperCase()) {
      case 'ASSIGNED':
        return WorkOrderStatus.assigned;
      case 'ACCEPTED':
        return WorkOrderStatus.accepted;
      case 'REJECTED':
        return WorkOrderStatus.rejected;
      case 'IN_PROGRESS':
        return WorkOrderStatus.inProgress;
      case 'COMPLETED':
        return WorkOrderStatus.completed;
      case 'CANCELLED':
        return WorkOrderStatus.cancelled;
      default:
        return WorkOrderStatus.pending;
    }
  }

  String get apiValue {
    switch (this) {
      case WorkOrderStatus.pending:
        return 'PENDING';
      case WorkOrderStatus.assigned:
        return 'ASSIGNED';
      case WorkOrderStatus.accepted:
        return 'ACCEPTED';
      case WorkOrderStatus.rejected:
        return 'REJECTED';
      case WorkOrderStatus.inProgress:
        return 'IN_PROGRESS';
      case WorkOrderStatus.completed:
        return 'COMPLETED';
      case WorkOrderStatus.cancelled:
        return 'CANCELLED';
    }
  }

  String get label {
    switch (this) {
      case WorkOrderStatus.pending:
        return 'Pending';
      case WorkOrderStatus.assigned:
        return 'Assigned';
      case WorkOrderStatus.accepted:
        return 'Accepted';
      case WorkOrderStatus.rejected:
        return 'Rejected';
      case WorkOrderStatus.inProgress:
        return 'In Progress';
      case WorkOrderStatus.completed:
        return 'Completed';
      case WorkOrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}
