import 'package:mobile/core/network/network_error_mapper.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/work_orders/data/datasources/work_order_local_datasource.dart';
import 'package:mobile/features/work_orders/data/datasources/work_order_remote_datasource.dart';
import 'package:mobile/features/work_orders/domain/entities/pending_work_order_action.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order_priority.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order_status.dart';
import 'package:mobile/features/work_orders/domain/repositories/work_order_repository.dart';

class WorkOrderRepositoryImpl implements WorkOrderRepository {
  WorkOrderRepositoryImpl({
    required WorkOrderRemoteDataSource remote,
    required WorkOrderLocalDataSource local,
  })  : _remote = remote,
        _local = local;

  final WorkOrderRemoteDataSource _remote;
  final WorkOrderLocalDataSource _local;

  @override
  Future<Result<WorkOrderPage>> listWorkOrders({
    int page = 1,
    int limit = 20,
    WorkOrderStatus? status,
    String? search,
  }) async {
    try {
      final pageResult = await _remote.list(
        page: page,
        limit: limit,
        status: status,
        search: search,
      );
      return Success(pageResult);
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  @override
  Future<Result<WorkOrderPage>> listMyAssignments({
    int page = 1,
    int limit = 20,
    WorkOrderStatus? status,
    String? search,
  }) async {
    try {
      final pageResult = await _remote.listMine(
        page: page,
        limit: limit,
        status: status,
        search: search,
      );
      return Success(pageResult);
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  @override
  Future<Result<WorkOrder>> getById(String id) async {
    try {
      return Success(await _remote.getById(id));
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  @override
  Future<Result<WorkOrder>> create(WorkOrderUpsertInput input) async {
    try {
      return Success(await _remote.create(input));
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  @override
  Future<Result<WorkOrder>> update(String id, WorkOrderUpsertInput input) async {
    try {
      return Success(await _remote.update(id, input));
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      await _remote.delete(id);
      return const Success(null);
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  @override
  Future<Result<WorkOrder>> assign({
    required String id,
    required String technicianId,
    WorkOrderPriority? priority,
    DateTime? scheduledAt,
  }) async {
    try {
      return Success(
        await _remote.assign(
          id: id,
          technicianId: technicianId,
          priority: priority,
          scheduledAt: scheduledAt,
        ),
      );
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  @override
  Future<Result<WorkOrder>> accept(String id) async {
    try {
      return Success(await _remote.accept(id));
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  @override
  Future<Result<WorkOrder>> reject(String id, {String? rejectionReason}) async {
    try {
      return Success(
        await _remote.reject(id, rejectionReason: rejectionReason),
      );
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  @override
  Future<Result<WorkOrder>> start(
    String id, {
    required WorkOrderLocationInput location,
  }) async {
    try {
      return Success(await _remote.start(id, location: location));
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  @override
  Future<Result<WorkOrder>> complete(
    String id, {
    required WorkOrderLocationInput location,
    String? completionNotes,
  }) async {
    try {
      return Success(
        await _remote.complete(
          id,
          location: location,
          completionNotes: completionNotes,
        ),
      );
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  @override
  Future<Result<WorkOrder>> cancel(String id, {String? cancellationReason}) async {
    try {
      return Success(
        await _remote.cancel(id, cancellationReason: cancellationReason),
      );
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  @override
  Future<Result<WorkOrder>> saveBeforeWork(
    String id, {
    String? beforeNotes,
    List<WorkOrderAttachmentInput> photos = const [],
  }) async {
    try {
      return Success(
        await _remote.saveBeforeWork(
          id,
          beforeNotes: beforeNotes,
          photos: photos,
        ),
      );
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  @override
  Future<Result<WorkOrder>> addProgressNote(
    String id, {
    required String text,
  }) async {
    try {
      return Success(await _remote.addProgressNote(id, text: text));
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  @override
  Future<Result<WorkOrder>> addProgressPhotos(
    String id, {
    required List<WorkOrderAttachmentInput> photos,
  }) async {
    try {
      return Success(await _remote.addProgressPhotos(id, photos: photos));
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  @override
  Future<Result<WorkOrder>> addAfterPhotos(
    String id, {
    required List<WorkOrderAttachmentInput> photos,
  }) async {
    try {
      return Success(await _remote.addAfterPhotos(id, photos: photos));
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  @override
  Future<Result<WorkOrder>> removePhoto(
    String id, {
    required WorkOrderPhotoCategory category,
    required String url,
  }) async {
    try {
      return Success(
        await _remote.removePhoto(id, category: category, url: url),
      );
    } on Object catch (error) {
      return NetworkErrorMapper.map(error);
    }
  }

  @override
  Future<List<PendingWorkOrderAction>> getPendingActions() async {
    return _local.readPendingQueue();
  }

  @override
  Future<Result<int>> syncPendingActions() async {
    // Online MVP: offline mutation queue is not executed yet.
    return const Success(0);
  }
}
