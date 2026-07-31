import 'package:equatable/equatable.dart';
import 'package:mobile/features/auth/domain/entities/current_user.dart';

sealed class LoginState extends Equatable {
  const LoginState();

  @override
  List<Object?> get props => [];
}

final class LoginInitial extends LoginState {
  const LoginInitial({
    this.email = '',
    this.password = '',
    this.rememberMe = false,
    this.obscurePassword = true,
    this.emailError,
    this.passwordError,
  });

  final String email;
  final String password;
  final bool rememberMe;
  final bool obscurePassword;
  final String? emailError;
  final String? passwordError;

  LoginInitial copyWith({
    String? email,
    String? password,
    bool? rememberMe,
    bool? obscurePassword,
    String? emailError,
    String? passwordError,
    bool clearEmailError = false,
    bool clearPasswordError = false,
  }) {
    return LoginInitial(
      email: email ?? this.email,
      password: password ?? this.password,
      rememberMe: rememberMe ?? this.rememberMe,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      emailError: clearEmailError ? null : emailError ?? this.emailError,
      passwordError:
          clearPasswordError ? null : passwordError ?? this.passwordError,
    );
  }

  @override
  List<Object?> get props => [
        email,
        password,
        rememberMe,
        obscurePassword,
        emailError,
        passwordError,
      ];
}

final class LoginLoading extends LoginState {
  const LoginLoading();
}

final class LoginSuccess extends LoginState {
  const LoginSuccess(this.user);

  final CurrentUser user;

  @override
  List<Object?> get props => [user];
}

final class LoginFailure extends LoginState {
  const LoginFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
