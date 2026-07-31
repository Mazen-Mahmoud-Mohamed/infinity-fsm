import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/roles/domain/entities/role_entities.dart';

abstract class RolesRepository {
  Future<Result<RolesDashboard>> getDashboard();

  Future<Result<RolePage>> listRoles({
    int page = 1,
    int limit = 20,
    String? search,
    bool? isActive,
    bool? isSystem,
  });

  Future<Result<RoleEntity>> getRoleById(String id);

  Future<Result<List<PermissionCatalogItem>>> getPermissionCatalog();

  Future<Result<RoleEntity>> createRole(RoleUpsertInput input);

  Future<Result<RoleEntity>> updateRole(String id, RoleUpsertInput input);

  Future<Result<RoleEntity>> setRoleStatus(String id, bool isActive);

  Future<Result<void>> deleteRole(String id);

  Future<Result<RoleEntity>> cloneRole(String id, {String? name, String? slug});

  Future<Result<RoleUsersPage>> listRoleUsers(
    String id, {
    int page = 1,
    int limit = 20,
    String? search,
  });

  Future<Result<RoleAssignResult>> assignRoleToUsers(
    String id,
    List<String> userIds,
  );

  Future<List<PendingRolesAction>> getPendingActions();
}
