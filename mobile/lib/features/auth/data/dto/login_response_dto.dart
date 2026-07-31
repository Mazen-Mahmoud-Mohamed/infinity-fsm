import 'package:mobile/features/auth/data/dto/auth_tokens_dto.dart';
import 'package:mobile/features/auth/data/models/current_user_model.dart';

class LoginResponseDto {
  const LoginResponseDto({
    required this.tokens,
    required this.user,
  });

  factory LoginResponseDto.fromJson(Map<String, dynamic> json) {
    return LoginResponseDto(
      tokens: AuthTokensDto.fromJson(
        json['tokens'] as Map<String, dynamic>,
      ),
      user: CurrentUserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  final AuthTokensDto tokens;
  final CurrentUserModel user;
}
