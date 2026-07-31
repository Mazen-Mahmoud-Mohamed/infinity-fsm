import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order_priority.dart';
import 'package:mobile/features/work_orders/domain/repositories/work_order_repository.dart';

class AssignWorkOrderUseCase {
  AssignWorkOrderUseCase(this._repository);

  final WorkOrderRepository _repository;

  Future<Result<WorkOrder>> call({
    required String id,
    required String technicianId,
    WorkOrderPriority? priority,
    DateTime? scheduledAt,
  }) {
    return _repository.assign(
      id: id,
      technicianId: technicianId,
      priority: priority,
      scheduledAt: scheduledAt,
    );
  }
}
