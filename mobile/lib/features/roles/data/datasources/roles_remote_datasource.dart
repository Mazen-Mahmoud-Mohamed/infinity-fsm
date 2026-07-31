import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/features/roles/data/models/role_models.dart';
import 'package:mobile/features/roles/domain/entities/role_entities.dart';

class RolesRemoteDataSource {
  RolesRemoteDataSource(this._client);
  final DioClient _client;

  Future<RolesDashboard> getDashboard() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.rolesDashboard,
    );
    return RolesDashboardModel.fromJson(
      response.data?['data'] as Map<String, dynamic>? ?? const {},
    );
  }

  Future<RolePage> listRoles({
    int page = 1,
    int limit = 20,
    String? search,
    bool? isActive,
    bool? isSystem,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.roles,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (isActive != null) 'isActive': isActive.toString(),
        if (isSystem != null) 'isSystem': isSystem.toString(),
      },
    );
    return _mapRolePage(response.data);
  }

  Future<RoleModel> getRoleById(String id) async {
    final response = await _client.get<Map<String, dynamic>>(
      '${ApiConstants.roles}/$id',
    );
    return RoleModel.fromJson(response.data?['data'] as Map<String, dynamic>);
  }

  Future<List<PermissionCatalogItem>> getPermissionCatalog() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.rolesPermissions,
    );
    final data = response.data?['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(PermissionCatalogItemModel.fromJson)
        .toList();
  }

  Future<RoleModel> createRole(RoleUpsertInput input) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.roles,
      data: _body(input),
    );
    return RoleModel.fromJson(response.data?['data'] as Map<String, dynamic>);
  }

  Future<RoleModel> updateRole(String id, RoleUpsertInput input) async {
    final response = await _client.put<Map<String, dynamic>>(
      '${ApiConstants.roles}/$id',
      data: _body(input),
    );
    return RoleModel.fromJson(response.data?['data'] as Map<String, dynamic>);
  }

  Future<RoleModel> setRoleStatus(String id, bool isActive) async {
    final response = await _client.patch<Map<String, dynamic>>(
      '${ApiConstants.roles}/$id/status',
      data: {'isActive': isActive},
    );
    return RoleModel.fromJson(response.data?['data'] as Map<String, dynamic>);
  }

  Future<void> deleteRole(String id) async {
    await _client.delete<Map<String, dynamic>>('${ApiConstants.roles}/$id');
  }

  Future<RoleModel> cloneRole(String id, {String? name, String? slug}) async {
    final response = await _client.post<Map<String, dynamic>>(
      '${ApiConstants.roles}/$id/clone',
      data: {
        if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
        if (slug != null && slug.trim().isNotEmpty) 'slug': slug.trim(),
      },
    );
    return RoleModel.fromJson(response.data?['data'] as Map<String, dynamic>);
  }

  Future<RoleUsersPage> listRoleUsers(
    String id, {
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      '${ApiConstants.roles}/$id/users',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    final body = response.data;
    final meta = body?['meta'];
    final pagination = meta is Map<String, dynamic>
        ? meta['pagination'] as Map<String, dynamic>?
        : null;
    final data = body?['data'] as Map<String, dynamic>? ?? const {};
    final roleJson = data['role'] as Map<String, dynamic>? ?? const {};
    final itemsRaw = data['items'];
    final items = itemsRaw is List
        ? itemsRaw
            .whereType<Map<String, dynamic>>()
            .map(RoleUserRefModel.fromJson)
            .toList()
        : <RoleUserRef>[];

    return RoleUsersPage(
      role: RoleModel.fromJson(roleJson),
      items: items,
      page: (pagination?['page'] as num?)?.toInt() ?? 1,
      limit: (pagination?['limit'] as num?)?.toInt() ?? 20,
      total: (pagination?['total'] as num?)?.toInt() ?? 0,
      totalPages: (pagination?['totalPages'] as num?)?.toInt() ?? 1,
    );
  }

  Future<RoleAssignResult> assignRoleToUsers(
    String id,
    List<String> userIds,
  ) async {
    final response = await _client.post<Map<String, dynamic>>(
      '${ApiConstants.roles}/$id/assign-users',
      data: {'userIds': userIds},
    );
    return RoleAssignResultModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> _body(RoleUpsertInput input) => {
        'name': input.name,
        if (input.slug != null && input.slug!.trim().isNotEmpty)
          'slug': input.slug,
        if (input.description != null) 'description': input.description,
        'permissions': input.permissions,
        if (input.color != null) 'color': input.color,
        'isActive': input.isActive,
      };

  RolePage _mapRolePage(Map<String, dynamic>? body) {
    final meta = body?['meta'];
    final pagination = meta is Map<String, dynamic>
        ? meta['pagination'] as Map<String, dynamic>?
        : null;
    final data = body?['data'];
    final items = data is List
        ? data.whereType<Map<String, dynamic>>().map(RoleModel.fromJson).toList()
        : <RoleEntity>[];
    return RolePage(
      items: items,
      page: (pagination?['page'] as num?)?.toInt() ?? 1,
      limit: (pagination?['limit'] as num?)?.toInt() ?? 20,
      total: (pagination?['total'] as num?)?.toInt() ?? 0,
      totalPages: (pagination?['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}
