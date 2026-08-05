import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/utils/device_info_provider.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobile/features/auth/domain/usecases/login_usecase.dart';
import 'package:mobile/features/auth/presentation/cubit/login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit({
    required this._loginUseCase,
    required this._localDataSource,
  })  : super(const LoginInitial()) {
    _loadRememberedCredentials();
  }

  final LoginUseCase _loginUseCase;
  final AuthLocalDataSource _localDataSource;

  void _loadRememberedCredentials() {
    final rememberMe = _localDataSource.getRememberMe();
    final email = _localDataSource.getRememberedEmail() ?? '';
    emit(
      LoginInitial(
        email: email,
        rememberMe: rememberMe,
      ),
    );
  }

  void emailChanged(String value) {
    final current = state;
    if (current is LoginInitial) {
      emit(
        current.copyWith(
          email: value,
          clearEmailError: true,
        ),
      );
    }
  }

  void passwordChanged(String value) {
    final current = state;
    if (current is LoginInitial) {
      emit(
        current.copyWith(
          password: value,
          clearPasswordError: true,
        ),
      );
    }
  }

  void rememberMeChanged(bool value) {
    final current = state;
    if (current is LoginInitial) {
      emit(current.copyWith(rememberMe: value));
    }
  }

  void togglePasswordVisibility() {
    final current = state;
    if (current is LoginInitial) {
      emit(current.copyWith(obscurePassword: !current.obscurePassword));
    }
  }

  Future<void> submit() async {
    final current = state;
    if (current is! LoginInitial) {
      return;
    }

    final validation = _validate(current);
    if (validation != null) {
      emit(validation);
      return;
    }

    emit(const LoginLoading());

    final deviceId = await _localDataSource.getDeviceId();
    if (deviceId == null || deviceId.isEmpty) {
      emit(const LoginFailure('deviceRegistrationFailed'));
      emit(current);
      return;
    }

    final result = await _loginUseCase(
      LoginParams(
        email: current.email.trim(),
        password: current.password,
        rememberMe: current.rememberMe,
        deviceId: deviceId,
        deviceInfo: DeviceInfoProvider.current(),
      ),
    );

    switch (result) {
      case Success(data: final user):
        emit(LoginSuccess(user));
        emit(current.copyWith(password: ''));
      case Failure(message: final message, code: _):
        // Do not collapse all transport failures into a single "No internet"
        // message. Dio/network exceptions already map to the most accurate
        // localized key available; preserve it here.
        emit(LoginFailure(message));
        emit(current);
    }
  }

  LoginInitial? _validate(LoginInitial current) {
    String? emailError;
    String? passwordError;

    final email = current.email.trim();
    if (email.isEmpty) {
      emailError = 'emailRequired';
    } else if (!_isValidEmail(email)) {
      emailError = 'emailInvalid';
    }

    if (current.password.isEmpty) {
      passwordError = 'passwordRequired';
    } else if (current.password.length < 8) {
      passwordError = 'passwordMinLength';
    }

    if (emailError != null || passwordError != null) {
      return current.copyWith(
        emailError: emailError,
        passwordError: passwordError,
      );
    }

    return null;
  }

  bool _isValidEmail(String value) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value);
  }
}
