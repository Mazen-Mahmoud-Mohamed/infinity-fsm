import 'package:mobile/features/users/domain/entities/user_management_entities.dart';

UserNamedRef? _namedRef(dynamic raw) {
  if (raw is! Map<String, dynamic>) return null;
  final id = raw['id']?.toString();
  if (id == null || id.isEmpty) return null;
  return UserNamedRef(
    id: id,
    name: raw['name']?.toString(),
    code: raw['code']?.toString(),
  );
}

class ManagedUserModel extends ManagedUser {
  const ManagedUserModel({
    required super.id,
    required super.email,
    required super.firstName,
    required super.lastName,
    required super.fullName,
    required super.status,
    required super.roles,
    super.companyId,
    super.employeeId,
    super.username,
    super.phone,
    super.jobTitle,
    super.avatarUrl,
    super.primaryRole,
    super.branchId,
    super.regionId,
    super.cityId,
    super.departmentId,
    super.teamId,
    super.positionId,
    super.department,
    super.branch,
    super.team,
    super.position,
    super.lastLoginAt,
    super.lastActiveAt,
    super.createdBy,
    super.updatedBy,
    super.createdAt,
    super.updatedAt,
    super.recentActivity,
  });

  factory ManagedUserModel.fromJson(Map<String, dynamic> json) {
    final rolesRaw = json['roles'];
    final roles = rolesRaw is List
        ? rolesRaw.map((e) => e.toString()).toList()
        : <String>[];
    final activity = json['recentActivity'];

    return ManagedUserModel(
      id: json['id']?.toString() ?? '',
      companyId: json['companyId']?.toString(),
      employeeId: json['employeeId']?.toString(),
      username: json['username']?.toString(),
      email: json['email']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      fullName: json['fullName']?.toString() ??
          '${json['firstName'] ?? ''} ${json['lastName'] ?? ''}'.trim(),
      phone: json['phone']?.toString(),
      jobTitle: json['jobTitle']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      roles: roles,
      primaryRole: json['primaryRole']?.toString() ??
          (roles.isNotEmpty ? roles.first : null),
      status: ManagedUserStatus.fromApi(json['status']?.toString()),
      branchId: json['branchId']?.toString(),
      regionId: json['regionId']?.toString(),
      cityId: json['cityId']?.toString(),
      departmentId: json['departmentId']?.toString(),
      teamId: json['teamId']?.toString(),
      positionId: json['positionId']?.toString(),
      department: _namedRef(json['department']),
      branch: _namedRef(json['branch']),
      team: _namedRef(json['team']),
      position: _namedRef(json['position']),
      lastLoginAt: DateTime.tryParse(json['lastLoginAt']?.toString() ?? ''),
      lastActiveAt: DateTime.tryParse(json['lastActiveAt']?.toString() ?? ''),
      createdBy: _namedRef(json['createdBy']),
      updatedBy: _namedRef(json['updatedBy']),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
      recentActivity: activity is List
          ? activity
              .whereType<Map<String, dynamic>>()
              .map(
                (item) => UserActivityItem(
                  id: item['id']?.toString() ?? '',
                  action: item['action']?.toString() ?? '',
                  userId: item['userId']?.toString(),
                  actorId: item['actorId']?.toString(),
                  summary: item['summary']?.toString(),
                  createdAt:
                      DateTime.tryParse(item['createdAt']?.toString() ?? ''),
                ),
              )
              .toList()
          : const [],
    );
  }
}

class UsersDashboardModel extends UsersDashboard {
  const UsersDashboardModel({
    required super.totalUsers,
    required super.activeUsers,
    required super.disabledUsers,
    required super.lockedUsers,
  });

  factory UsersDashboardModel.fromJson(Map<String, dynamic> json) {
    return UsersDashboardModel(
      totalUsers: (json['totalUsers'] as num?)?.toInt() ?? 0,
      activeUsers: (json['activeUsers'] as num?)?.toInt() ?? 0,
      disabledUsers: (json['disabledUsers'] as num?)?.toInt() ?? 0,
      lockedUsers: (json['lockedUsers'] as num?)?.toInt() ?? 0,
    );
  }
}

class PendingUsersActionModel extends PendingUsersAction {
  const PendingUsersActionModel({
    required super.id,
    required super.type,
    required super.createdAt,
    super.resourceId,
    super.payload,
    super.retryCount,
    super.lastError,
  });

  factory PendingUsersActionModel.fromJson(Map<String, dynamic> json) {
    return PendingUsersActionModel(
      id: json['id']?.toString() ?? '',
      type: PendingUsersActionType.values.firstWhere(
        (v) => v.name == json['type'],
        orElse: () => PendingUsersActionType.updateUser,
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
