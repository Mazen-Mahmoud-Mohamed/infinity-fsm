import 'package:mobile/features/assets/domain/entities/asset_history.dart';
import 'package:mobile/features/assets/domain/entities/assets_dashboard.dart';
import 'package:mobile/features/assets/domain/entities/pending_asset_action.dart';

class AssetHistoryModel extends AssetHistory {
  const AssetHistoryModel({
    required super.id,
    required super.assetId,
    required super.type,
    super.companyId,
    super.title,
    super.description,
    super.fromStatus,
    super.toStatus,
    super.eventDate,
    super.user,
    super.createdAt,
  });

  factory AssetHistoryModel.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    return AssetHistoryModel(
      id: json['id']?.toString() ?? '',
      companyId: json['companyId']?.toString(),
      assetId: json['assetId']?.toString() ?? '',
      type: AssetHistoryType.fromApi(json['type']?.toString()),
      title: json['title']?.toString(),
      description: json['description']?.toString(),
      fromStatus: json['fromStatus']?.toString(),
      toStatus: json['toStatus']?.toString(),
      eventDate: DateTime.tryParse(json['eventDate']?.toString() ?? ''),
      user: userJson is Map<String, dynamic>
          ? AssetHistoryUserRef(
              id: userJson['id']?.toString() ?? '',
              name: userJson['name']?.toString(),
            )
          : null,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}

class AssetsDashboardModel extends AssetsDashboard {
  const AssetsDashboardModel({
    required super.totalAssets,
    required super.active,
    required super.underMaintenance,
    required super.retired,
    required super.warrantyExpiringSoon,
  });

  factory AssetsDashboardModel.fromJson(Map<String, dynamic> json) {
    return AssetsDashboardModel(
      totalAssets: (json['totalAssets'] as num?)?.toInt() ?? 0,
      active: (json['active'] as num?)?.toInt() ?? 0,
      underMaintenance: (json['underMaintenance'] as num?)?.toInt() ?? 0,
      retired: (json['retired'] as num?)?.toInt() ?? 0,
      warrantyExpiringSoon:
          (json['warrantyExpiringSoon'] as num?)?.toInt() ?? 0,
    );
  }
}

class PendingAssetActionModel extends PendingAssetAction {
  const PendingAssetActionModel({
    required super.id,
    required super.type,
    required super.createdAt,
    super.resourceId,
    super.payload,
    super.retryCount,
    super.lastError,
  });

  factory PendingAssetActionModel.fromJson(Map<String, dynamic> json) {
    return PendingAssetActionModel(
      id: json['id']?.toString() ?? '',
      type: PendingAssetActionType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => PendingAssetActionType.createAsset,
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'resourceId': resourceId,
        'payload': payload,
        'createdAt': createdAt.toIso8601String(),
        'retryCount': retryCount,
        'lastError': lastError,
      };
}
