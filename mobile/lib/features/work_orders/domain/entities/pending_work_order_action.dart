import 'package:equatable/equatable.dart';

/// Placeholder for future offline sync of work-order mutations.
enum PendingWorkOrderActionType {
  create,
  update,
  delete,
  assign,
  accept,
  reject,
  start,
  complete,
  cancel,
  beforeWork,
  progressNote,
  progressPhoto,
  afterPhoto,
  removePhoto,
}

class PendingWorkOrderAction extends Equatable {
  const PendingWorkOrderAction({
    required this.id,
    required this.type,
    required this.createdAt,
    this.workOrderId,
    this.payload = const {},
    this.retryCount = 0,
    this.lastError,
  });

  final String id;
  final PendingWorkOrderActionType type;
  final String? workOrderId;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int retryCount;
  final String? lastError;

  PendingWorkOrderAction copyWith({
    int? retryCount,
    String? lastError,
  }) {
    return PendingWorkOrderAction(
      id: id,
      type: type,
      workOrderId: workOrderId,
      payload: payload,
      createdAt: createdAt,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        workOrderId,
        payload,
        createdAt,
        retryCount,
        lastError,
      ];
}
