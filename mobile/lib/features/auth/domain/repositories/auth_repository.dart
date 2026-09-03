import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/auth/domain/entities/current_user.dart';

class LoginParams {
  const LoginParams({
    required this.email,
    required this.password,
    required this.rememberMe,
    required this.deviceId,
    required this.deviceInfo,
  });

  final String email;
  final String password;
  final bool rememberMe;
  final String deviceId;
  final Map<String, String> deviceInfo;
}

abstract class AuthRepository {
  Future<Result<bool>> hasSession();

  Future<Result<CurrentUser>> login(LoginParams params);

  Future<Result<CurrentUser>> restoreSession();

  Future<Result<CurrentUser>> getCurrentUser();

  Future<Result<void>> logout();

  Future<Result<void>> logoutAllDevices();

  Future<Result<void>> refreshTokens();
}
