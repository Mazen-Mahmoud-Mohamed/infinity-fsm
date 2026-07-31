import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order.dart';
import 'package:mobile/features/work_orders/domain/repositories/work_order_repository.dart';

class SaveBeforeWorkUseCase {
  SaveBeforeWorkUseCase(this._repository);

  final WorkOrderRepository _repository;

  Future<Result<WorkOrder>> call(
    String id, {
    String? beforeNotes,
    List<WorkOrderAttachmentInput> photos = const [],
  }) {
    return _repository.saveBeforeWork(
      id,
      beforeNotes: beforeNotes,
      photos: photos,
    );
  }
}
