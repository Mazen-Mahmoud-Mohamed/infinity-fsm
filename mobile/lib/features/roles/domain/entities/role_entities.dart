import 'package:equatable/equatable.dart';

class RolesDashboard extends Equatable {
  const RolesDashboard({
    required this.totalRoles,
    required this.activeRoles,
    required this.systemRoles,
    required this.customRoles,
  });

  final int totalRoles;
  final int activeRoles;
  final int systemRoles;
  final int customRoles;

  @override
  List<Object?> get props =>
      [totalRoles, activeRoles, systemRoles, customRoles];
}

class PermissionCatalogItem extends Equatable {
  const PermissionCatalogItem({
    required this.key,
    required this.module,
    required this.action,
    this.constant,
  });

  final String key;
  final String module;
  final String action;
  final String? constant;

  @override
  List<Object?> get props => [key, module, action, constant];
}

class RoleEntity extends Equatable {
  const RoleEntity({
    required this.id,
    required this.name,
    required this.slug,
    required this.permissions,
    required this.isSystem,
    required this.isActive,
    this.companyId,
    this.description,
    this.color,
    this.assignedUsersCount = 0,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? companyId;
  final String name;
  final String slug;
  final String? description;
  final List<String> permissions;
  final String? color;
  final bool isSystem;
  final bool isActive;
  final int assignedUsersCount;
  final String? createdBy;
  final String? updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [
        id,
        companyId,
        name,
        slug,
        description,
        permissions,
        color,
        isSystem,
        isActive,
        assignedUsersCount,
        createdBy,
        updatedBy,
        createdAt,
        updatedAt,
      ];
}

class RolePage extends Equatable {
  const RolePage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<RoleEntity> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  bool get hasMore => page < totalPages;

  @override
  List<Object?> get props => [items, page, limit, total, totalPages];
}

class RoleUserRef extends Equatable {
  const RoleUserRef({
    required this.id,
    required this.fullName,
    required this.roles,
    this.email,
    this.username,
    this.employeeId,
    this.status,
    this.isActive,
    this.avatarUrl,
  });

  final String id;
  final String fullName;
  final String? email;
  final String? username;
  final String? employeeId;
  final List<String> roles;
  final String? status;
  final bool? isActive;
  final String? avatarUrl;

  @override
  List<Object?> get props =>
      [id, fullName, email, username, employeeId, roles, status, isActive];
}

class RoleUsersPage extends Equatable {
  const RoleUsersPage({
    required this.role,
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final RoleEntity role;
  final List<RoleUserRef> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  bool get hasMore => page < totalPages;

  @override
  List<Object?> get props => [role, items, page, limit, total, totalPages];
}

class RoleUpsertInput extends Equatable {
  const RoleUpsertInput({
    required this.name,
    required this.permissions,
    this.slug,
    this.description,
    this.color,
    this.isActive = true,
  });

  final String name;
  final String? slug;
  final String? description;
  final List<String> permissions;
  final String? color;
  final bool isActive;

  @override
  List<Object?> get props =>
      [name, slug, description, permissions, color, isActive];
}

class RoleAssignResult extends Equatable {
  const RoleAssignResult({
    required this.roleId,
    required this.slug,
    required this.requested,
    required this.updatedCount,
    required this.assignedUsersCount,
  });

  final String roleId;
  final String slug;
  final int requested;
  final int updatedCount;
  final int assignedUsersCount;

  @override
  List<Object?> get props =>
      [roleId, slug, requested, updatedCount, assignedUsersCount];
}

/// Offline queue placeholder — interfaces only, no execution.
class PendingRolesAction extends Equatable {
  const PendingRolesAction({
    required this.id,
    required this.type,
    required this.createdAt,
    this.resourceId,
    this.payload = const {},
    this.retryCount = 0,
    this.lastError,
  });

  final String id;
  final String type;
  final String? resourceId;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int retryCount;
  final String? lastError;

  @override
  List<Object?> get props =>
      [id, type, resourceId, payload, createdAt, retryCount, lastError];
}
