import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order.dart';
import 'package:mobile/features/work_orders/domain/repositories/work_order_repository.dart';

class AddProgressPhotosUseCase {
  AddProgressPhotosUseCase(this._repository);

  final WorkOrderRepository _repository;

  Future<Result<WorkOrder>> call(
    String id, {
    required List<WorkOrderAttachmentInput> photos,
  }) {
    return _repository.addProgressPhotos(id, photos: photos);
  }
}
