import 'package:mobile/features/inventory/domain/entities/pending_inventory_action.dart';

class PendingInventoryActionModel extends PendingInventoryAction {
  const PendingInventoryActionModel({
    required super.id,
    required super.type,
    required super.createdAt,
    super.resourceId,
    super.payload,
    super.retryCount,
    super.lastError,
  });

  factory PendingInventoryActionModel.fromJson(Map<String, dynamic> json) {
    return PendingInventoryActionModel(
      id: json['id']?.toString() ?? '',
      type: PendingInventoryActionType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => PendingInventoryActionType.createPart,
      ),
      resourceId: json['resourceId']?.toString(),
      payload: json['payload'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['payload'] as Map)
          : const {},
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
      lastError: json['lastError']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'resourceId': resourceId,
      'payload': payload,
      'createdAt': createdAt.toIso8601String(),
      'retryCount': retryCount,
      'lastError': lastError,
    };
  }
}
