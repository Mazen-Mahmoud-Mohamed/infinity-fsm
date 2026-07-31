import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/work_orders/domain/repositories/work_order_repository.dart';

class DeleteWorkOrderUseCase {
  DeleteWorkOrderUseCase(this._repository);

  final WorkOrderRepository _repository;

  Future<Result<void>> call(String id) => _repository.delete(id);
}
