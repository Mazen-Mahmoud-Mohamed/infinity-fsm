import 'package:equatable/equatable.dart';

enum ManagedUserStatus {
  active,
  disabled,
  locked;

  String get apiValue => switch (this) {
        ManagedUserStatus.active => 'ACTIVE',
        ManagedUserStatus.disabled => 'DISABLED',
        ManagedUserStatus.locked => 'LOCKED',
      };

  static ManagedUserStatus fromApi(String? value) {
    switch (value?.toUpperCase()) {
      case 'DISABLED':
      case 'INACTIVE':
        return ManagedUserStatus.disabled;
      case 'LOCKED':
        return ManagedUserStatus.locked;
      case 'ACTIVE':
      default:
        return ManagedUserStatus.active;
    }
  }
}

class UserNamedRef extends Equatable {
  const UserNamedRef({required this.id, this.name, this.code});
  final String id;
  final String? name;
  final String? code;
  @override
  List<Object?> get props => [id, name, code];
}

class UserActivityItem extends Equatable {
  const UserActivityItem({
    required this.id,
    required this.action,
    this.userId,
    this.actorId,
    this.summary,
    this.createdAt,
  });

  final String id;
  final String action;
  final String? userId;
  final String? actorId;
  final String? summary;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id, action, userId, actorId, summary, createdAt];
}

class ManagedUser extends Equatable {
  const ManagedUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.status,
    required this.roles,
    this.companyId,
    this.employeeId,
    this.username,
    this.phone,
    this.jobTitle,
    this.avatarUrl,
    this.primaryRole,
    this.branchId,
    this.regionId,
    this.cityId,
    this.departmentId,
    this.teamId,
    this.positionId,
    this.department,
    this.branch,
    this.team,
    this.position,
    this.lastLoginAt,
    this.lastActiveAt,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
    this.recentActivity = const [],
  });

  final String id;
  final String? companyId;
  final String? employeeId;
  final String? username;
  final String email;
  final String firstName;
  final String lastName;
  final String fullName;
  final String? phone;
  final String? jobTitle;
  final String? avatarUrl;
  final List<String> roles;
  final String? primaryRole;
  final ManagedUserStatus status;
  final String? branchId;
  final String? regionId;
  final String? cityId;
  final String? departmentId;
  final String? teamId;
  final String? positionId;
  final UserNamedRef? department;
  final UserNamedRef? branch;
  final UserNamedRef? team;
  final UserNamedRef? position;
  final DateTime? lastLoginAt;
  final DateTime? lastActiveAt;
  final UserNamedRef? createdBy;
  final UserNamedRef? updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<UserActivityItem> recentActivity;

  @override
  List<Object?> get props => [
        id,
        companyId,
        employeeId,
        username,
        email,
        firstName,
        lastName,
        fullName,
        phone,
        jobTitle,
        avatarUrl,
        roles,
        primaryRole,
        status,
        branchId,
        regionId,
        cityId,
        departmentId,
        teamId,
        positionId,
        department,
        branch,
        team,
        position,
        lastLoginAt,
        lastActiveAt,
        createdBy,
        updatedBy,
        createdAt,
        updatedAt,
        recentActivity,
      ];
}

class ManagedUserPage extends Equatable {
  const ManagedUserPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<ManagedUser> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  bool get hasMore => page < totalPages;

  @override
  List<Object?> get props => [items, page, limit, total, totalPages];
}

class UsersDashboard extends Equatable {
  const UsersDashboard({
    required this.totalUsers,
    required this.activeUsers,
    required this.disabledUsers,
    required this.lockedUsers,
  });

  final int totalUsers;
  final int activeUsers;
  final int disabledUsers;
  final int lockedUsers;

  @override
  List<Object?> get props =>
      [totalUsers, activeUsers, disabledUsers, lockedUsers];
}

class ManagedUserUpsertInput {
  const ManagedUserUpsertInput({
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    required this.branchId,
    required this.regionId,
    required this.cityId,
    required this.departmentId,
    this.password,
    this.phone,
    this.jobTitle,
    this.employeeId,
    this.roles = const ['TECHNICIAN'],
    this.teamId,
    this.positionId,
    this.status = ManagedUserStatus.active,
  });

  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String? password;
  final String? phone;
  final String? jobTitle;
  final String? employeeId;
  final List<String> roles;
  final String branchId;
  final String regionId;
  final String cityId;
  final String departmentId;
  final String? teamId;
  final String? positionId;
  final ManagedUserStatus status;
}

class AvatarUploadBytes {
  const AvatarUploadBytes({
    required this.bytes,
    required this.fileName,
  });
  final List<int> bytes;
  final String fileName;
}

enum PendingUsersActionType {
  createUser,
  updateUser,
  setStatus,
  deleteUser,
  resetPassword,
  changePassword,
}

class PendingUsersAction extends Equatable {
  const PendingUsersAction({
    required this.id,
    required this.type,
    required this.createdAt,
    this.resourceId,
    this.payload = const {},
    this.retryCount = 0,
    this.lastError,
  });

  final String id;
  final PendingUsersActionType type;
  final String? resourceId;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int retryCount;
  final String? lastError;

  @override
  List<Object?> get props =>
      [id, type, resourceId, payload, createdAt, retryCount, lastError];
}
