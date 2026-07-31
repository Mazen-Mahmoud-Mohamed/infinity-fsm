import 'package:equatable/equatable.dart';

/// Placeholder for future offline sync of asset mutations.
enum PendingAssetActionType {
  createCategory,
  updateCategory,
  deleteCategory,
  createAsset,
  updateAsset,
  deleteAsset,
  addHistory,
}

class PendingAssetAction extends Equatable {
  const PendingAssetAction({
    required this.id,
    required this.type,
    required this.createdAt,
    this.resourceId,
    this.payload = const {},
    this.retryCount = 0,
    this.lastError,
  });

  final String id;
  final PendingAssetActionType type;
  final String? resourceId;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int retryCount;
  final String? lastError;

  PendingAssetAction copyWith({int? retryCount, String? lastError}) {
    return PendingAssetAction(
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
