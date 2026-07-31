enum OvertimeStatus {
  running,
  pendingReview,
  approved,
  rejected,
  cancelled;

  static OvertimeStatus fromApi(String value) {
    switch (value.toUpperCase()) {
      case 'PENDING_REVIEW':
        return OvertimeStatus.pendingReview;
      case 'APPROVED':
        return OvertimeStatus.approved;
      case 'REJECTED':
        return OvertimeStatus.rejected;
      case 'CANCELLED':
        return OvertimeStatus.cancelled;
      default:
        return OvertimeStatus.running;
    }
  }

  String get apiValue {
    switch (this) {
      case OvertimeStatus.running:
        return 'RUNNING';
      case OvertimeStatus.pendingReview:
        return 'PENDING_REVIEW';
      case OvertimeStatus.approved:
        return 'APPROVED';
      case OvertimeStatus.rejected:
        return 'REJECTED';
      case OvertimeStatus.cancelled:
        return 'CANCELLED';
    }
  }

  String get label {
    switch (this) {
      case OvertimeStatus.running:
        return 'Running';
      case OvertimeStatus.pendingReview:
        return 'Pending review';
      case OvertimeStatus.approved:
        return 'Approved';
      case OvertimeStatus.rejected:
        return 'Rejected';
      case OvertimeStatus.cancelled:
        return 'Cancelled';
    }
  }
}
