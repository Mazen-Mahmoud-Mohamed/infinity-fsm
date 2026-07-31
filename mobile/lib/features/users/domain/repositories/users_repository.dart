import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/users/domain/entities/user_management_entities.dart';

abstract class UsersRepository {
  Future<Result<UsersDashboard>> getDashboard();

  Future<Result<ManagedUserPage>> listUsers({
    int page = 1,
    int limit = 20,
    String? search,
    ManagedUserStatus? status,
    String? role,
    String? departmentId,
    String? branchId,
  });

  Future<Result<ManagedUser>> getUserById(String id);

  Future<Result<ManagedUser>> createUser(ManagedUserUpsertInput input);

  Future<Result<ManagedUser>> updateUser(String id, ManagedUserUpsertInput input);

  Future<Result<ManagedUser>> setUserStatus(String id, ManagedUserStatus status);

  Future<Result<ManagedUser>> deleteUser(String id);

  Future<Result<void>> resetPassword(String id, String newPassword);

  Future<Result<void>> changeOwnPassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<Result<ManagedUser>> uploadAvatar(String id, AvatarUploadBytes avatar);

  Future<List<PendingUsersAction>> getPendingActions();

  Future<Result<int>> syncPendingActions();
}
