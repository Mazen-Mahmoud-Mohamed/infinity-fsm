import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/roles/domain/entities/role_entities.dart';
import 'package:mobile/features/roles/domain/repositories/roles_repository.dart';

class GetRolesDashboardUseCase {
  GetRolesDashboardUseCase(this._repository);
  final RolesRepository _repository;
  Future<Result<RolesDashboard>> call() => _repository.getDashboard();
}

class ListRolesUseCase {
  ListRolesUseCase(this._repository);
  final RolesRepository _repository;
  Future<Result<RolePage>> call({
    int page = 1,
    int limit = 20,
    String? search,
    bool? isActive,
    bool? isSystem,
  }) =>
      _repository.listRoles(
        page: page,
        limit: limit,
        search: search,
        isActive: isActive,
        isSystem: isSystem,
      );
}

class GetRoleByIdUseCase {
  GetRoleByIdUseCase(this._repository);
  final RolesRepository _repository;
  Future<Result<RoleEntity>> call(String id) => _repository.getRoleById(id);
}

class GetPermissionCatalogUseCase {
  GetPermissionCatalogUseCase(this._repository);
  final RolesRepository _repository;
  Future<Result<List<PermissionCatalogItem>>> call() =>
      _repository.getPermissionCatalog();
}

class CreateRoleUseCase {
  CreateRoleUseCase(this._repository);
  final RolesRepository _repository;
  Future<Result<RoleEntity>> call(RoleUpsertInput input) =>
      _repository.createRole(input);
}

class UpdateRoleUseCase {
  UpdateRoleUseCase(this._repository);
  final RolesRepository _repository;
  Future<Result<RoleEntity>> call(String id, RoleUpsertInput input) =>
      _repository.updateRole(id, input);
}

class SetRoleStatusUseCase {
  SetRoleStatusUseCase(this._repository);
  final RolesRepository _repository;
  Future<Result<RoleEntity>> call(String id, bool isActive) =>
      _repository.setRoleStatus(id, isActive);
}

class DeleteRoleUseCase {
  DeleteRoleUseCase(this._repository);
  final RolesRepository _repository;
  Future<Result<void>> call(String id) => _repository.deleteRole(id);
}

class CloneRoleUseCase {
  CloneRoleUseCase(this._repository);
  final RolesRepository _repository;
  Future<Result<RoleEntity>> call(String id, {String? name, String? slug}) =>
      _repository.cloneRole(id, name: name, slug: slug);
}

class ListRoleUsersUseCase {
  ListRoleUsersUseCase(this._repository);
  final RolesRepository _repository;
  Future<Result<RoleUsersPage>> call(
    String id, {
    int page = 1,
    int limit = 20,
    String? search,
  }) =>
      _repository.listRoleUsers(id, page: page, limit: limit, search: search);
}

class AssignRoleToUsersUseCase {
  AssignRoleToUsersUseCase(this._repository);
  final RolesRepository _repository;
  Future<Result<RoleAssignResult>> call(String id, List<String> userIds) =>
      _repository.assignRoleToUsers(id, userIds);
}
