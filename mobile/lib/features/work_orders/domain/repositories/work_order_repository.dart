import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/work_orders/domain/entities/pending_work_order_action.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order_priority.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order_status.dart';

abstract class WorkOrderRepository {
  Future<Result<WorkOrderPage>> listWorkOrders({
    int page = 1,
    int limit = 20,
    WorkOrderStatus? status,
    String? search,
  });

  Future<Result<WorkOrderPage>> listMyAssignments({
    int page = 1,
    int limit = 20,
    WorkOrderStatus? status,
    String? search,
  });

  Future<Result<WorkOrder>> getById(String id);

  Future<Result<WorkOrder>> create(WorkOrderUpsertInput input);

  Future<Result<WorkOrder>> update(String id, WorkOrderUpsertInput input);

  Future<Result<void>> delete(String id);

  Future<Result<WorkOrder>> assign({
    required String id,
    required String technicianId,
    WorkOrderPriority? priority,
    DateTime? scheduledAt,
  });

  Future<Result<WorkOrder>> accept(String id);

  Future<Result<WorkOrder>> reject(String id, {String? rejectionReason});

  Future<Result<WorkOrder>> start(String id, {required WorkOrderLocationInput location});

  Future<Result<WorkOrder>> complete(
    String id, {
    required WorkOrderLocationInput location,
    String? completionNotes,
  });

  Future<Result<WorkOrder>> cancel(String id, {String? cancellationReason});

  Future<Result<WorkOrder>> saveBeforeWork(
    String id, {
    String? beforeNotes,
    List<WorkOrderAttachmentInput> photos = const [],
  });

  Future<Result<WorkOrder>> addProgressNote(String id, {required String text});

  Future<Result<WorkOrder>> addProgressPhotos(
    String id, {
    required List<WorkOrderAttachmentInput> photos,
  });

  Future<Result<WorkOrder>> addAfterPhotos(
    String id, {
    required List<WorkOrderAttachmentInput> photos,
  });

  Future<Result<WorkOrder>> removePhoto(
    String id, {
    required WorkOrderPhotoCategory category,
    required String url,
  });

  /// Offline sync prep — returns queued actions (empty in online MVP).
  Future<List<PendingWorkOrderAction>> getPendingActions();

  /// Offline sync prep — no-op online MVP, returns Success(0).
  /// Queue helpers exist on [WorkOrderLocalDataSource] for future sync.
  Future<Result<int>> syncPendingActions();
}
