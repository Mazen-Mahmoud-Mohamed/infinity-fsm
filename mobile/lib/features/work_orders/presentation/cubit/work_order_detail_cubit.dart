import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/services/address_resolver_service.dart';
import 'package:mobile/core/services/gps_service.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/attendance/domain/entities/gps_snapshot.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order_priority.dart';
import 'package:mobile/features/work_orders/domain/usecases/accept_work_order_usecase.dart';
import 'package:mobile/features/work_orders/domain/usecases/add_after_photos_usecase.dart';
import 'package:mobile/features/work_orders/domain/usecases/add_progress_note_usecase.dart';
import 'package:mobile/features/work_orders/domain/usecases/add_progress_photos_usecase.dart';
import 'package:mobile/features/work_orders/domain/usecases/assign_work_order_usecase.dart';
import 'package:mobile/features/work_orders/domain/usecases/cancel_work_order_usecase.dart';
import 'package:mobile/features/work_orders/domain/usecases/complete_work_order_usecase.dart';
import 'package:mobile/features/work_orders/domain/usecases/delete_work_order_usecase.dart';
import 'package:mobile/features/work_orders/domain/usecases/get_work_order_by_id_usecase.dart';
import 'package:mobile/features/work_orders/domain/usecases/reject_work_order_usecase.dart';
import 'package:mobile/features/work_orders/domain/usecases/remove_work_order_photo_usecase.dart';
import 'package:mobile/features/work_orders/domain/usecases/save_before_work_usecase.dart';
import 'package:mobile/features/work_orders/domain/usecases/start_work_order_usecase.dart';

enum WorkOrderDetailStatus { initial, loading, success, failure }

enum WorkOrderAction {
  accept,
  reject,
  start,
  complete,
  cancel,
  delete,
  assign,
  beforeWork,
  progressNote,
  progressPhoto,
  afterPhoto,
  removePhoto,
}

class WorkOrderDetailState extends Equatable {
  const WorkOrderDetailState({
    this.status = WorkOrderDetailStatus.initial,
    this.workOrder,
    this.action,
    this.message,
    this.isError = false,
    this.deleted = false,
    this.mutated = false,
  });

  final WorkOrderDetailStatus status;
  final WorkOrder? workOrder;
  final WorkOrderAction? action;
  final String? message;
  final bool isError;
  final bool deleted;
  final bool mutated;

  bool get isBusy => action != null;

  WorkOrderDetailState copyWith({
    WorkOrderDetailStatus? status,
    WorkOrder? workOrder,
    WorkOrderAction? action,
    bool clearAction = false,
    String? message,
    bool clearMessage = false,
    bool? isError,
    bool? deleted,
    bool? mutated,
  }) {
    return WorkOrderDetailState(
      status: status ?? this.status,
      workOrder: workOrder ?? this.workOrder,
      action: clearAction ? null : (action ?? this.action),
      message: clearMessage ? null : (message ?? this.message),
      isError: isError ?? this.isError,
      deleted: deleted ?? this.deleted,
      mutated: mutated ?? this.mutated,
    );
  }

  @override
  List<Object?> get props =>
      [status, workOrder, action, message, isError, deleted, mutated];
}

class WorkOrderDetailCubit extends Cubit<WorkOrderDetailState> {
  WorkOrderDetailCubit({
    required GetWorkOrderByIdUseCase getById,
    required AcceptWorkOrderUseCase accept,
    required RejectWorkOrderUseCase reject,
    required StartWorkOrderUseCase start,
    required CompleteWorkOrderUseCase complete,
    required CancelWorkOrderUseCase cancel,
    required DeleteWorkOrderUseCase delete,
    required AssignWorkOrderUseCase assign,
    required SaveBeforeWorkUseCase saveBeforeWork,
    required AddProgressNoteUseCase addProgressNote,
    required AddProgressPhotosUseCase addProgressPhotos,
    required AddAfterPhotosUseCase addAfterPhotos,
    required RemoveWorkOrderPhotoUseCase removePhoto,
    required GpsService gpsService,
    required AddressResolverService addressResolverService,
    required this.workOrderId,
  })  : _getById = getById,
        _accept = accept,
        _reject = reject,
        _start = start,
        _complete = complete,
        _cancel = cancel,
        _delete = delete,
        _assign = assign,
        _saveBeforeWork = saveBeforeWork,
        _addProgressNote = addProgressNote,
        _addProgressPhotos = addProgressPhotos,
        _addAfterPhotos = addAfterPhotos,
        _removePhoto = removePhoto,
        _gpsService = gpsService,
        _addressResolver = addressResolverService,
        super(const WorkOrderDetailState());

  final GetWorkOrderByIdUseCase _getById;
  final AcceptWorkOrderUseCase _accept;
  final RejectWorkOrderUseCase _reject;
  final StartWorkOrderUseCase _start;
  final CompleteWorkOrderUseCase _complete;
  final CancelWorkOrderUseCase _cancel;
  final DeleteWorkOrderUseCase _delete;
  final AssignWorkOrderUseCase _assign;
  final SaveBeforeWorkUseCase _saveBeforeWork;
  final AddProgressNoteUseCase _addProgressNote;
  final AddProgressPhotosUseCase _addProgressPhotos;
  final AddAfterPhotosUseCase _addAfterPhotos;
  final RemoveWorkOrderPhotoUseCase _removePhoto;
  final GpsService _gpsService;
  final AddressResolverService _addressResolver;
  final String workOrderId;

  Future<void> load({bool silent = false}) async {
    if (!silent || state.workOrder == null) {
      emit(
        state.copyWith(
          status: WorkOrderDetailStatus.loading,
          clearMessage: true,
          isError: false,
        ),
      );
    }

    final result = await _getById(workOrderId);
    switch (result) {
      case Success(data: final workOrder):
        emit(
          state.copyWith(
            status: WorkOrderDetailStatus.success,
            workOrder: workOrder,
            clearMessage: true,
          ),
        );
      case Failure(message: final message):
        emit(
          state.copyWith(
            status: state.workOrder == null
                ? WorkOrderDetailStatus.failure
                : WorkOrderDetailStatus.success,
            message: message,
            isError: true,
          ),
        );
    }
  }

  void clearMessage() {
    if (state.message == null) {
      return;
    }
    emit(state.copyWith(clearMessage: true, isError: false));
  }

  Future<void> accept() =>
      _runAction(WorkOrderAction.accept, () => _accept(workOrderId));

  Future<void> reject({String? reason}) => _runAction(
        WorkOrderAction.reject,
        () => _reject(workOrderId, rejectionReason: reason),
      );

  Future<void> start() async {
    await _runAction(WorkOrderAction.start, () async {
      final location = await _captureLocation();
      return _start(workOrderId, location: location);
    });
  }

  Future<void> complete({String? completionNotes}) async {
    final workOrder = state.workOrder;
    if (workOrder == null) {
      return;
    }
    if (workOrder.afterPhotos.isEmpty) {
      emit(
        state.copyWith(
          message: 'workOrderAfterPhotoRequiredSnackbar',
          isError: true,
        ),
      );
      return;
    }
    await _runAction(WorkOrderAction.complete, () async {
      final location = await _captureLocation();
      return _complete(
        workOrderId,
        location: location,
        completionNotes: completionNotes,
      );
    });
  }

  Future<void> cancel({String? reason}) => _runAction(
        WorkOrderAction.cancel,
        () => _cancel(workOrderId, cancellationReason: reason),
      );

  Future<void> assign({
    required String technicianId,
    WorkOrderPriority? priority,
    DateTime? scheduledAt,
  }) {
    return _runAction(
      WorkOrderAction.assign,
      () => _assign(
        id: workOrderId,
        technicianId: technicianId,
        priority: priority,
        scheduledAt: scheduledAt,
      ),
    );
  }

  Future<void> saveBeforeWork({
    String? beforeNotes,
    List<WorkOrderAttachmentInput> photos = const [],
  }) {
    return _runAction(
      WorkOrderAction.beforeWork,
      () => _saveBeforeWork(
        workOrderId,
        beforeNotes: beforeNotes,
        photos: photos,
      ),
    );
  }

  Future<void> addProgressNote(String text) {
    return _runAction(
      WorkOrderAction.progressNote,
      () => _addProgressNote(workOrderId, text: text),
    );
  }

  Future<void> addProgressPhotos(List<WorkOrderAttachmentInput> photos) {
    return _runAction(
      WorkOrderAction.progressPhoto,
      () => _addProgressPhotos(workOrderId, photos: photos),
    );
  }

  Future<void> addAfterPhotos(List<WorkOrderAttachmentInput> photos) {
    return _runAction(
      WorkOrderAction.afterPhoto,
      () => _addAfterPhotos(workOrderId, photos: photos),
    );
  }

  Future<void> removePhoto({
    required WorkOrderPhotoCategory category,
    required String url,
  }) {
    return _runAction(
      WorkOrderAction.removePhoto,
      () => _removePhoto(workOrderId, category: category, url: url),
    );
  }

  Future<void> delete() async {
    if (state.isBusy) {
      return;
    }
    emit(state.copyWith(action: WorkOrderAction.delete, clearMessage: true));

    final result = await _delete(workOrderId);
    switch (result) {
      case Success():
        emit(
          state.copyWith(
            clearAction: true,
            deleted: true,
            mutated: true,
            message: 'workOrderDeleted',
            isError: false,
          ),
        );
      case Failure(message: final message):
        emit(
          state.copyWith(
            clearAction: true,
            message: message,
            isError: true,
          ),
        );
    }
  }

  Future<WorkOrderLocationInput> _captureLocation() async {
    final reading = await _gpsService.getCurrentReading();
    final snapshot = GpsSnapshot(
      latitude: reading.latitude,
      longitude: reading.longitude,
      accuracy: reading.accuracy,
      recordedAt: reading.recordedAt,
      heading: reading.heading,
      speed: reading.speed,
      provider: reading.provider,
    );
    final address = await _addressResolver.resolve(snapshot);
    return WorkOrderLocationInput(
      latitude: reading.latitude,
      longitude: reading.longitude,
      accuracy: reading.accuracy,
      address: address,
      recordedAt: reading.recordedAt,
    );
  }

  Future<void> _runAction(
    WorkOrderAction action,
    Future<Result<WorkOrder>> Function() runner,
  ) async {
    if (state.isBusy) {
      return;
    }

    emit(state.copyWith(action: action, clearMessage: true));
    try {
      final result = await runner();
      switch (result) {
        case Success(data: final workOrder):
          emit(
            state.copyWith(
              clearAction: true,
              status: WorkOrderDetailStatus.success,
              workOrder: workOrder,
              message: _successMessage(action),
              isError: false,
              mutated: true,
            ),
          );
        case Failure(message: final message):
          emit(
            state.copyWith(
              clearAction: true,
              message: message,
              isError: true,
            ),
          );
      }
    } on LocationException catch (error) {
      emit(
        state.copyWith(
          clearAction: true,
          message: error.message,
          isError: true,
        ),
      );
    } on Object catch (error) {
      emit(
        state.copyWith(
          clearAction: true,
          message: error.toString(),
          isError: true,
        ),
      );
    }
  }

  String _successMessage(WorkOrderAction action) {
    switch (action) {
      case WorkOrderAction.accept:
        return 'workOrderAccepted';
      case WorkOrderAction.reject:
        return 'workOrderRejected';
      case WorkOrderAction.start:
        return 'workOrderStarted';
      case WorkOrderAction.complete:
        return 'workOrderCompletedMessage';
      case WorkOrderAction.cancel:
        return 'workOrderCancelledMessage';
      case WorkOrderAction.assign:
        return 'workOrderTechnicianAssigned';
      case WorkOrderAction.delete:
        return 'workOrderDeleted';
      case WorkOrderAction.beforeWork:
        return 'workOrderBeforeWorkSaved';
      case WorkOrderAction.progressNote:
        return 'workOrderProgressNoteAdded';
      case WorkOrderAction.progressPhoto:
        return 'workOrderProgressPhotoUploaded';
      case WorkOrderAction.afterPhoto:
        return 'workOrderAfterPhotoUploaded';
      case WorkOrderAction.removePhoto:
        return 'workOrderPhotoRemoved';
    }
  }
}
