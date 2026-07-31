import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/users/domain/entities/user_management_entities.dart';
import 'package:mobile/features/users/domain/repositories/users_repository.dart';

class GetUsersDashboardUseCase {
  GetUsersDashboardUseCase(this._repository);
  final UsersRepository _repository;
  Future<Result<UsersDashboard>> call() => _repository.getDashboard();
}

class ListManagedUsersUseCase {
  ListManagedUsersUseCase(this._repository);
  final UsersRepository _repository;
  Future<Result<ManagedUserPage>> call({
    int page = 1,
    int limit = 20,
    String? search,
    ManagedUserStatus? status,
    String? role,
    String? departmentId,
    String? branchId,
  }) =>
      _repository.listUsers(
        page: page,
        limit: limit,
        search: search,
        status: status,
        role: role,
        departmentId: departmentId,
        branchId: branchId,
      );
}

class GetManagedUserByIdUseCase {
  GetManagedUserByIdUseCase(this._repository);
  final UsersRepository _repository;
  Future<Result<ManagedUser>> call(String id) => _repository.getUserById(id);
}

class CreateManagedUserUseCase {
  CreateManagedUserUseCase(this._repository);
  final UsersRepository _repository;
  Future<Result<ManagedUser>> call(ManagedUserUpsertInput input) =>
      _repository.createUser(input);
}

class UpdateManagedUserUseCase {
  UpdateManagedUserUseCase(this._repository);
  final UsersRepository _repository;
  Future<Result<ManagedUser>> call(String id, ManagedUserUpsertInput input) =>
      _repository.updateUser(id, input);
}

class SetManagedUserStatusUseCase {
  SetManagedUserStatusUseCase(this._repository);
  final UsersRepository _repository;
  Future<Result<ManagedUser>> call(String id, ManagedUserStatus status) =>
      _repository.setUserStatus(id, status);
}

class DeleteManagedUserUseCase {
  DeleteManagedUserUseCase(this._repository);
  final UsersRepository _repository;
  Future<Result<ManagedUser>> call(String id) => _repository.deleteUser(id);
}

class ResetManagedUserPasswordUseCase {
  ResetManagedUserPasswordUseCase(this._repository);
  final UsersRepository _repository;
  Future<Result<void>> call(String id, String newPassword) =>
      _repository.resetPassword(id, newPassword);
}

class ChangeOwnPasswordUseCase {
  ChangeOwnPasswordUseCase(this._repository);
  final UsersRepository _repository;
  Future<Result<void>> call({
    required String currentPassword,
    required String newPassword,
  }) =>
      _repository.changeOwnPassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
}

class UploadUserAvatarUseCase {
  UploadUserAvatarUseCase(this._repository);
  final UsersRepository _repository;
  Future<Result<ManagedUser>> call(String id, AvatarUploadBytes avatar) =>
      _repository.uploadAvatar(id, avatar);
}

class SyncPendingUsersUseCase {
  SyncPendingUsersUseCase(this._repository);
  final UsersRepository _repository;
  Future<Result<int>> call() => _repository.syncPendingActions();
}
