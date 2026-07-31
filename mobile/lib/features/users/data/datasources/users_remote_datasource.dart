import 'package:dio/dio.dart';
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/features/users/data/models/user_management_models.dart';
import 'package:mobile/features/users/domain/entities/user_management_entities.dart';

class UsersRemoteDataSource {
  UsersRemoteDataSource(this._client);
  final DioClient _client;

  Future<UsersDashboard> getDashboard() async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.usersDashboard,
    );
    return UsersDashboardModel.fromJson(
      response.data?['data'] as Map<String, dynamic>? ?? const {},
    );
  }

  Future<ManagedUserPage> listUsers({
    int page = 1,
    int limit = 20,
    String? search,
    ManagedUserStatus? status,
    String? role,
    String? departmentId,
    String? branchId,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiConstants.users,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (status != null) 'status': status.apiValue,
        if (role != null) 'role': role,
        if (departmentId != null) 'departmentId': departmentId,
        if (branchId != null) 'branchId': branchId,
      },
    );
    return _mapPage(response.data);
  }

  Future<ManagedUserModel> getUserById(String id) async {
    final response = await _client.get<Map<String, dynamic>>(
      '${ApiConstants.users}/$id',
    );
    return ManagedUserModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<ManagedUserModel> createUser(ManagedUserUpsertInput input) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.users,
      data: _body(input, includePassword: true),
    );
    return ManagedUserModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<ManagedUserModel> updateUser(
    String id,
    ManagedUserUpsertInput input,
  ) async {
    final response = await _client.put<Map<String, dynamic>>(
      '${ApiConstants.users}/$id',
      data: _body(input, includePassword: false),
    );
    return ManagedUserModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<ManagedUserModel> setUserStatus(
    String id,
    ManagedUserStatus status,
  ) async {
    final response = await _client.patch<Map<String, dynamic>>(
      '${ApiConstants.users}/$id/status',
      data: {'status': status.apiValue},
    );
    return ManagedUserModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<ManagedUserModel> deleteUser(String id) async {
    final response = await _client.delete<Map<String, dynamic>>(
      '${ApiConstants.users}/$id',
    );
    return ManagedUserModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Future<void> resetPassword(String id, String newPassword) async {
    await _client.post<Map<String, dynamic>>(
      '${ApiConstants.users}/$id/reset-password',
      data: {'newPassword': newPassword},
    );
  }

  Future<void> changeOwnPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _client.post<Map<String, dynamic>>(
      ApiConstants.usersChangePassword,
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }

  Future<ManagedUserModel> uploadAvatar(
    String id,
    AvatarUploadBytes avatar,
  ) async {
    final formData = FormData.fromMap({
      'avatar': MultipartFile.fromBytes(
        avatar.bytes,
        filename: avatar.fileName,
      ),
    });
    final response = await _client.post<Map<String, dynamic>>(
      '${ApiConstants.users}/$id/avatar',
      data: formData,
    );
    return ManagedUserModel.fromJson(
      response.data?['data'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> _body(
    ManagedUserUpsertInput input, {
    required bool includePassword,
  }) =>
      {
        'firstName': input.firstName,
        'lastName': input.lastName,
        'username': input.username,
        'email': input.email,
        if (includePassword && input.password != null)
          'password': input.password,
        if (input.phone != null) 'phone': input.phone,
        if (input.jobTitle != null) 'jobTitle': input.jobTitle,
        if (input.employeeId != null) 'employeeId': input.employeeId,
        'roles': input.roles,
        'branchId': input.branchId,
        'regionId': input.regionId,
        'cityId': input.cityId,
        'departmentId': input.departmentId,
        if (input.teamId != null) 'teamId': input.teamId,
        if (input.positionId != null) 'positionId': input.positionId,
        'status': input.status.apiValue,
      };

  ManagedUserPage _mapPage(Map<String, dynamic>? body) {
    final meta = body?['meta'];
    final pagination = meta is Map<String, dynamic>
        ? meta['pagination'] as Map<String, dynamic>?
        : null;
    final data = body?['data'];
    final items = data is List
        ? data
            .whereType<Map<String, dynamic>>()
            .map(ManagedUserModel.fromJson)
            .toList()
        : <ManagedUser>[];
    return ManagedUserPage(
      items: items,
      page: (pagination?['page'] as num?)?.toInt() ?? 1,
      limit: (pagination?['limit'] as num?)?.toInt() ?? 20,
      total: (pagination?['total'] as num?)?.toInt() ?? 0,
      totalPages: (pagination?['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}
