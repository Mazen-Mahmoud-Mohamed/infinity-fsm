enum WorkOrderPriority {
  low,
  medium,
  high,
  critical;

  static WorkOrderPriority fromApi(String value) {
    switch (value.toUpperCase()) {
      case 'LOW':
        return WorkOrderPriority.low;
      case 'HIGH':
        return WorkOrderPriority.high;
      case 'CRITICAL':
        return WorkOrderPriority.critical;
      default:
        return WorkOrderPriority.medium;
    }
  }

  String get apiValue {
    switch (this) {
      case WorkOrderPriority.low:
        return 'LOW';
      case WorkOrderPriority.medium:
        return 'MEDIUM';
      case WorkOrderPriority.high:
        return 'HIGH';
      case WorkOrderPriority.critical:
        return 'CRITICAL';
    }
  }

  String get label {
    switch (this) {
      case WorkOrderPriority.low:
        return 'Low';
      case WorkOrderPriority.medium:
        return 'Medium';
      case WorkOrderPriority.high:
        return 'High';
      case WorkOrderPriority.critical:
        return 'Critical';
    }
  }
}
