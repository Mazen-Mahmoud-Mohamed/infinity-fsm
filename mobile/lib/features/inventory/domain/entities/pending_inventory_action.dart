import 'package:equatable/equatable.dart';

/// Placeholder for future offline sync of inventory mutations.
enum PendingInventoryActionType {
  createWarehouse,
  updateWarehouse,
  deleteWarehouse,
  createPart,
  updatePart,
  deletePart,
  stockIn,
  stockOut,
  transfer,
  adjustment,
}

class PendingInventoryAction extends Equatable {
  const PendingInventoryAction({
    required this.id,
    required this.type,
    required this.createdAt,
    this.resourceId,
    this.payload = const {},
    this.retryCount = 0,
    this.lastError,
  });

  final String id;
  final PendingInventoryActionType type;
  final String? resourceId;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int retryCount;
  final String? lastError;

  PendingInventoryAction copyWith({
    int? retryCount,
    String? lastError,
  }) {
    return PendingInventoryAction(
      id: id,
      type: type,
      resourceId: resourceId,
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
        resourceId,
        payload,
        createdAt,
        retryCount,
        lastError,
      ];
}
