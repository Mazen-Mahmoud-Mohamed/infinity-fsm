import 'package:mobile/core/network/network_error_mapper.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/users/data/datasources/users_local_datasource.dart';
import 'package:mobile/features/users/data/datasources/users_remote_datasource.dart';
import 'package:mobile/features/users/domain/entities/user_management_entities.dart';
import 'package:mobile/features/users/domain/repositories/users_repository.dart';

class UsersRepositoryImpl implements UsersRepository {
  UsersRepositoryImpl({
    required UsersRemoteDataSource remote,
    required UsersLocalDataSource local,
  })  : _remote = remote,
        _local = local;

  final UsersRemoteDataSource _remote;
  final UsersLocalDataSource _local;

  @override
  Future<Result<UsersDashboard>> getDashboard() async {
    try {
      return Success(await _remote.getDashboard());
    } on Object catch (e) {
      return NetworkErrorMapper.map(e);
    }
  }

  @override
  Future<Result<ManagedUserPage>> listUsers({
    int page = 1,
    int limit = 20,
    String? search,
    ManagedUserStatus? status,
    String? role,
    String? departmentId,
    String? branchId,
  }) async {
    try {
      return Success(
        await _remote.listUsers(
          page: page,
          limit: limit,
          search: search,
          status: status,
          role: role,
          departmentId: departmentId,
          branchId: branchId,
        ),
      );
    } on Object catch (e) {
      return NetworkErrorMapper.map(e);
    }
  }

  @override
  Future<Result<ManagedUser>> getUserById(String id) async {
    try {
      return Success(await _remote.getUserById(id));
    } on Object catch (e) {
      return NetworkErrorMapper.map(e);
    }
  }

  @override
  Future<Result<ManagedUser>> createUser(ManagedUserUpsertInput input) async {
    try {
      return Success(await _remote.createUser(input));
    } on Object catch (e) {
      return NetworkErrorMapper.map(e);
    }
  }

  @override
  Future<Result<ManagedUser>> updateUser(
    String id,
    ManagedUserUpsertInput input,
  ) async {
    try {
      return Success(await _remote.updateUser(id, input));
    } on Object catch (e) {
      return NetworkErrorMapper.map(e);
    }
  }

  @override
  Future<Result<ManagedUser>> setUserStatus(
    String id,
    ManagedUserStatus status,
  ) async {
    try {
      return Success(await _remote.setUserStatus(id, status));
    } on Object catch (e) {
      return NetworkErrorMapper.map(e);
    }
  }

  @override
  Future<Result<ManagedUser>> deleteUser(String id) async {
    try {
      return Success(await _remote.deleteUser(id));
    } on Object catch (e) {
      return NetworkErrorMapper.map(e);
    }
  }

  @override
  Future<Result<void>> resetPassword(String id, String newPassword) async {
    try {
      await _remote.resetPassword(id, newPassword);
      return const Success(null);
    } on Object catch (e) {
      return NetworkErrorMapper.map(e);
    }
  }

  @override
  Future<Result<void>> changeOwnPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _remote.changeOwnPassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return const Success(null);
    } on Object catch (e) {
      return NetworkErrorMapper.map(e);
    }
  }

  @override
  Future<Result<ManagedUser>> uploadAvatar(
    String id,
    AvatarUploadBytes avatar,
  ) async {
    try {
      return Success(await _remote.uploadAvatar(id, avatar));
    } on Object catch (e) {
      return NetworkErrorMapper.map(e);
    }
  }

  @override
  Future<List<PendingUsersAction>> getPendingActions() async =>
      _local.readPendingQueue();

  @override
  Future<Result<int>> syncPendingActions() async => const Success(0);
}
