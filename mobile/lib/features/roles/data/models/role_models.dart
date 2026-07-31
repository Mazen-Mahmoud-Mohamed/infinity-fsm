import 'package:mobile/features/roles/domain/entities/role_entities.dart';

class RolesDashboardModel extends RolesDashboard {
  const RolesDashboardModel({
    required super.totalRoles,
    required super.activeRoles,
    required super.systemRoles,
    required super.customRoles,
  });

  factory RolesDashboardModel.fromJson(Map<String, dynamic> json) {
    return RolesDashboardModel(
      totalRoles: (json['totalRoles'] as num?)?.toInt() ?? 0,
      activeRoles: (json['activeRoles'] as num?)?.toInt() ?? 0,
      systemRoles: (json['systemRoles'] as num?)?.toInt() ?? 0,
      customRoles: (json['customRoles'] as num?)?.toInt() ?? 0,
    );
  }
}

class PermissionCatalogItemModel extends PermissionCatalogItem {
  const PermissionCatalogItemModel({
    required super.key,
    required super.module,
    required super.action,
    super.constant,
  });

  factory PermissionCatalogItemModel.fromJson(Map<String, dynamic> json) {
    return PermissionCatalogItemModel(
      key: json['key']?.toString() ?? '',
      module: json['module']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      constant: json['constant']?.toString(),
    );
  }
}

class RoleModel extends RoleEntity {
  const RoleModel({
    required super.id,
    required super.name,
    required super.slug,
    required super.permissions,
    required super.isSystem,
    required super.isActive,
    super.companyId,
    super.description,
    super.color,
    super.assignedUsersCount,
    super.createdBy,
    super.updatedBy,
    super.createdAt,
    super.updatedAt,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    final permissionsRaw = json['permissions'];
    return RoleModel(
      id: json['id']?.toString() ?? '',
      companyId: json['companyId']?.toString(),
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString(),
      permissions: permissionsRaw is List
          ? permissionsRaw.map((e) => e.toString()).toList()
          : const [],
      color: json['color']?.toString(),
      isSystem: json['isSystem'] == true,
      isActive: json['isActive'] != false,
      assignedUsersCount: (json['assignedUsersCount'] as num?)?.toInt() ?? 0,
      createdBy: json['createdBy']?.toString(),
      updatedBy: json['updatedBy']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }
}

class RoleUserRefModel extends RoleUserRef {
  const RoleUserRefModel({
    required super.id,
    required super.fullName,
    required super.roles,
    super.email,
    super.username,
    super.employeeId,
    super.status,
    super.isActive,
    super.avatarUrl,
  });

  factory RoleUserRefModel.fromJson(Map<String, dynamic> json) {
    final rolesRaw = json['roles'];
    final first = json['firstName']?.toString() ?? '';
    final last = json['lastName']?.toString() ?? '';
    return RoleUserRefModel(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '$first $last'.trim(),
      email: json['email']?.toString(),
      username: json['username']?.toString(),
      employeeId: json['employeeId']?.toString(),
      roles: rolesRaw is List
          ? rolesRaw.map((e) => e.toString()).toList()
          : const [],
      status: json['status']?.toString(),
      isActive: json['isActive'] as bool?,
      avatarUrl: json['avatarUrl']?.toString(),
    );
  }
}

class RoleAssignResultModel extends RoleAssignResult {
  const RoleAssignResultModel({
    required super.roleId,
    required super.slug,
    required super.requested,
    required super.updatedCount,
    required super.assignedUsersCount,
  });

  factory RoleAssignResultModel.fromJson(Map<String, dynamic> json) {
    return RoleAssignResultModel(
      roleId: json['roleId']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      requested: (json['requested'] as num?)?.toInt() ?? 0,
      updatedCount: (json['updatedCount'] as num?)?.toInt() ?? 0,
      assignedUsersCount: (json['assignedUsersCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class PendingRolesActionModel extends PendingRolesAction {
  const PendingRolesActionModel({
    required super.id,
    required super.type,
    required super.createdAt,
    super.resourceId,
    super.payload,
    super.retryCount,
    super.lastError,
  });

  factory PendingRolesActionModel.fromJson(Map<String, dynamic> json) {
    return PendingRolesActionModel(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      resourceId: json['resourceId']?.toString(),
      payload: json['payload'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['payload'] as Map)
          : const {},
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
      lastError: json['lastError']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'resourceId': resourceId,
        'payload': payload,
        'createdAt': createdAt.toIso8601String(),
        'retryCount': retryCount,
        'lastError': lastError,
      };
}
