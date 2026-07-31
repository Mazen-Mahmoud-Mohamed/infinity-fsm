import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/network/dio_client.dart';
import 'package:mobile/features/auth/data/dto/auth_tokens_dto.dart';
import 'package:mobile/features/auth/data/dto/login_request_dto.dart';
import 'package:mobile/features/auth/data/dto/login_response_dto.dart';
import 'package:mobile/features/auth/data/models/current_user_model.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._client);

  final DioClient _client;

  Future<LoginResponseDto> login(LoginRequestDto request) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.authLogin,
      data: request.toJson(),
    );
    final data = response.data?['data'] as Map<String, dynamic>;
    return LoginResponseDto.fromJson(data);
  }

  Future<AuthTokensDto> refresh({
    required String refreshToken,
    required String deviceId,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      ApiConstants.authRefresh,
      data: {
        'refreshToken': refreshToken,
        'deviceId': deviceId,
      },
    );
    final data = response.data?['data'] as Map<String, dynamic>;
    final tokens = data['tokens'] as Map<String, dynamic>? ?? data;
    return AuthTokensDto.fromJson(tokens);
  }

  Future<CurrentUserModel> getCurrentUser() async {
    final response =
        await _client.get<Map<String, dynamic>>(ApiConstants.authMe);
    final data = response.data?['data'] as Map<String, dynamic>;
    return CurrentUserModel.fromJson(data);
  }

  Future<void> logout({
    required String refreshToken,
    required String deviceId,
  }) async {
    await _client.post<Map<String, dynamic>>(
      ApiConstants.authLogout,
      data: {
        'refreshToken': refreshToken,
        'deviceId': deviceId,
      },
    );
  }
}
