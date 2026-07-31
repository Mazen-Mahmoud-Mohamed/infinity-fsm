import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order.dart';
import 'package:mobile/features/work_orders/domain/repositories/work_order_repository.dart';

class StartWorkOrderUseCase {
  StartWorkOrderUseCase(this._repository);

  final WorkOrderRepository _repository;

  Future<Result<WorkOrder>> call(
    String id, {
    required WorkOrderLocationInput location,
  }) {
    return _repository.start(id, location: location);
  }
}
