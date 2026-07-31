import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order_status.dart';
import 'package:mobile/features/work_orders/domain/repositories/work_order_repository.dart';

class ListWorkOrdersUseCase {
  ListWorkOrdersUseCase(this._repository);

  final WorkOrderRepository _repository;

  Future<Result<WorkOrderPage>> call({
    int page = 1,
    int limit = 20,
    WorkOrderStatus? status,
    String? search,
  }) {
    return _repository.listWorkOrders(
      page: page,
      limit: limit,
      status: status,
      search: search,
    );
  }
}
