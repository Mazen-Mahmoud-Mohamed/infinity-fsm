import 'package:mobile/features/auth/domain/entities/auth_tokens.dart';

class AuthTokensDto extends AuthTokens {
  const AuthTokensDto({
    required super.accessToken,
    required super.refreshToken,
    required super.expiresIn,
  });

  factory AuthTokensDto.fromJson(Map<String, dynamic> json) {
    return AuthTokensDto(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresIn: json['expiresIn'] as int? ?? 0,
    );
  }
}
