import 'package:mobile/core/network/network_error_mapper.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/roles/data/datasources/roles_local_datasource.dart';
import 'package:mobile/features/roles/data/datasources/roles_remote_datasource.dart';
import 'package:mobile/features/roles/domain/entities/role_entities.dart';
import 'package:mobile/features/roles/domain/repositories/roles_repository.dart';

class RolesRepositoryImpl implements RolesRepository {
  RolesRepositoryImpl({
    required RolesRemoteDataSource remote,
    required RolesLocalDataSource local,
  })  : _remote = remote,
        _local = local;

  final RolesRemoteDataSource _remote;
  final RolesLocalDataSource _local;

  @override
  Future<Result<RolesDashboard>> getDashboard() async {
    try {
      return Success(await _remote.getDashboard());
    } on Object catch (e) {
      return NetworkErrorMapper.map(e);
    }
  }

  @override
  Future<Result<RolePage>> listRoles({
    int page = 1,
    int limit = 20,
    String? search,
    bool? isActive,
    bool? isSystem,
  }) async {
    try {
      return Success(
        await _remote.listRoles(
          page: page,
          limit: limit,
          search: search,
          isActive: isActive,
          isSystem: isSystem,
        ),
      );
    } on Object catch (e) {
      return NetworkErrorMapper.map(e);
    }
  }

  @override
  Future<Result<RoleEntity>> getRoleById(String id) async {
    try {
      return Success(await _remote.getRoleById(id));
    } on Object catch (e) {
      return NetworkErrorMapper.map(e);
    }
  }

  @override
  Future<Result<List<PermissionCatalogItem>>> getPermissionCatalog() async {
    try {
      return Success(await _remote.getPermissionCatalog());
    } on Object catch (e) {
      return NetworkErrorMapper.map(e);
    }
  }

  @override
  Future<Result<RoleEntity>> createRole(RoleUpsertInput input) async {
    try {
      return Success(await _remote.createRole(input));
    } on Object catch (e) {
      return NetworkErrorMapper.map(e);
    }
  }

  @override
  Future<Result<RoleEntity>> updateRole(String id, RoleUpsertInput input) async {
    try {
      return Success(await _remote.updateRole(id, input));
    } on Object catch (e) {
      return NetworkErrorMapper.map(e);
    }
  }

  @override
  Future<Result<RoleEntity>> setRoleStatus(String id, bool isActive) async {
    try {
      return Success(await _remote.setRoleStatus(id, isActive));
    } on Object catch (e) {
      return NetworkErrorMapper.map(e);
    }
  }

  @override
  Future<Result<void>> deleteRole(String id) async {
    try {
      await _remote.deleteRole(id);
      return const Success(null);
    } on Object catch (e) {
      return NetworkErrorMapper.map(e);
    }
  }

  @override
  Future<Result<RoleEntity>> cloneRole(
    String id, {
    String? name,
    String? slug,
  }) async {
    try {
      return Success(await _remote.cloneRole(id, name: name, slug: slug));
    } on Object catch (e) {
      return NetworkErrorMapper.map(e);
    }
  }

  @override
  Future<Result<RoleUsersPage>> listRoleUsers(
    String id, {
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    try {
      return Success(
        await _remote.listRoleUsers(
          id,
          page: page,
          limit: limit,
          search: search,
        ),
      );
    } on Object catch (e) {
      return NetworkErrorMapper.map(e);
    }
  }

  @override
  Future<Result<RoleAssignResult>> assignRoleToUsers(
    String id,
    List<String> userIds,
  ) async {
    try {
      return Success(await _remote.assignRoleToUsers(id, userIds));
    } on Object catch (e) {
      return NetworkErrorMapper.map(e);
    }
  }

  @override
  Future<List<PendingRolesAction>> getPendingActions() async {
    return _local.readPendingQueue();
  }
}
