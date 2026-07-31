import 'package:equatable/equatable.dart';

enum AssetHistoryType {
  installation,
  maintenance,
  repair,
  inspection,
  statusChange,
  created,
  updated;

  String get apiValue {
    switch (this) {
      case AssetHistoryType.installation:
        return 'INSTALLATION';
      case AssetHistoryType.maintenance:
        return 'MAINTENANCE';
      case AssetHistoryType.repair:
        return 'REPAIR';
      case AssetHistoryType.inspection:
        return 'INSPECTION';
      case AssetHistoryType.statusChange:
        return 'STATUS_CHANGE';
      case AssetHistoryType.created:
        return 'CREATED';
      case AssetHistoryType.updated:
        return 'UPDATED';
    }
  }

  static AssetHistoryType fromApi(String? value) {
    switch (value?.toUpperCase()) {
      case 'INSTALLATION':
        return AssetHistoryType.installation;
      case 'MAINTENANCE':
        return AssetHistoryType.maintenance;
      case 'REPAIR':
        return AssetHistoryType.repair;
      case 'INSPECTION':
        return AssetHistoryType.inspection;
      case 'STATUS_CHANGE':
        return AssetHistoryType.statusChange;
      case 'CREATED':
        return AssetHistoryType.created;
      case 'UPDATED':
      default:
        return AssetHistoryType.updated;
    }
  }
}

class AssetHistoryUserRef extends Equatable {
  const AssetHistoryUserRef({required this.id, this.name});

  final String id;
  final String? name;

  @override
  List<Object?> get props => [id, name];
}

class AssetHistory extends Equatable {
  const AssetHistory({
    required this.id,
    required this.assetId,
    required this.type,
    this.companyId,
    this.title,
    this.description,
    this.fromStatus,
    this.toStatus,
    this.eventDate,
    this.user,
    this.createdAt,
  });

  final String id;
  final String? companyId;
  final String assetId;
  final AssetHistoryType type;
  final String? title;
  final String? description;
  final String? fromStatus;
  final String? toStatus;
  final DateTime? eventDate;
  final AssetHistoryUserRef? user;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [
        id,
        companyId,
        assetId,
        type,
        title,
        description,
        fromStatus,
        toStatus,
        eventDate,
        user,
        createdAt,
      ];
}

class AssetHistoryPage extends Equatable {
  const AssetHistoryPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<AssetHistory> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  bool get hasMore => page < totalPages;

  @override
  List<Object?> get props => [items, page, limit, total, totalPages];
}

class AssetHistoryCreateInput {
  const AssetHistoryCreateInput({
    required this.assetId,
    required this.type,
    this.title,
    this.description,
    this.toStatus,
    this.eventDate,
  });

  final String assetId;
  final AssetHistoryType type;
  final String? title;
  final String? description;
  final String? toStatus;
  final DateTime? eventDate;
}
