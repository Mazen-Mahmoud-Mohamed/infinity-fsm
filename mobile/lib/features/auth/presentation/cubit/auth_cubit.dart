import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/cache/session_query_cache.dart';
import 'package:mobile/core/services/auth_session_service.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/auth/domain/entities/current_user.dart';
import 'package:mobile/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:mobile/features/auth/domain/usecases/logout_usecase.dart';
import 'package:mobile/features/auth/domain/usecases/restore_session_usecase.dart';

enum AuthStatus {
  unknown,
  authenticated,
  unauthenticated,
}

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.message,
    this.isOffline = false,
  });

  final AuthStatus status;
  final CurrentUser? user;
  final String? message;
  final bool isOffline;

  AuthState copyWith({
    AuthStatus? status,
    CurrentUser? user,
    String? message,
    bool clearUser = false,
    bool? isOffline,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : user ?? this.user,
      message: message,
      isOffline: isOffline ?? this.isOffline,
    );
  }

  @override
  List<Object?> get props => [status, user, message, isOffline];
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required RestoreSessionUseCase restoreSessionUseCase,
    required GetCurrentUserUseCase getCurrentUserUseCase,
    required LogoutUseCase logoutUseCase,
    required AuthSessionService authSessionService,
    required SessionQueryCache sessionQueryCache,
  })  : _restoreSessionUseCase = restoreSessionUseCase,
        _getCurrentUserUseCase = getCurrentUserUseCase,
        _logoutUseCase = logoutUseCase,
        _authSessionService = authSessionService,
        _sessionQueryCache = sessionQueryCache,
        super(const AuthState()) {
    _sessionSubscription =
        _authSessionService.onSessionExpired.listen((_) {
      _sessionQueryCache.clear();
      emit(
        const AuthState(
          status: AuthStatus.unauthenticated,
          message: 'sessionExpired',
        ),
      );
    });
  }

  final RestoreSessionUseCase _restoreSessionUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final LogoutUseCase _logoutUseCase;
  final AuthSessionService _authSessionService;
  final SessionQueryCache _sessionQueryCache;
  StreamSubscription<void>? _sessionSubscription;

  Future<void> restoreSession() async {
    final result = await _restoreSessionUseCase();

    switch (result) {
      case Success(data: final user):
        emit(
          AuthState(
            status: AuthStatus.authenticated,
            user: user,
          ),
        );
      case Failure(code: final code):
        emit(
          AuthState(
            status: AuthStatus.unauthenticated,
            isOffline: code == 'OFFLINE',
          ),
        );
    }
  }

  Future<void> checkSession() => restoreSession();

  void setAuthenticated(CurrentUser user) {
    emit(
      AuthState(
        status: AuthStatus.authenticated,
        user: user,
      ),
    );
  }

  Future<void> refreshCurrentUser() async {
    final result = await _getCurrentUserUseCase();

    switch (result) {
      case Success(data: final user):
        emit(
          state.copyWith(
            status: AuthStatus.authenticated,
            user: user,
            isOffline: false,
          ),
        );
      case Failure(message: final message, code: final code):
        // Stay signed in when the failure is connectivity-related.
        if (code == 'OFFLINE' ||
            code == 'TIMEOUT' ||
            code == 'NETWORK_ERROR') {
          if (state.user != null) {
            emit(state.copyWith(isOffline: true));
            return;
          }
        }
        emit(
          AuthState(
            status: AuthStatus.unauthenticated,
            message: message,
          ),
        );
    }
  }

  Future<void> logout() async {
    final result = await _logoutUseCase();
    _sessionQueryCache.clear();

    switch (result) {
      case Success():
        emit(
          const AuthState(
            status: AuthStatus.unauthenticated,
          ),
        );
      case Failure(message: final message):
        emit(
          AuthState(
            status: AuthStatus.unauthenticated,
            message: message,
          ),
        );
    }
  }

  @override
  Future<void> close() {
    unawaited(_sessionSubscription?.cancel());
    return super.close();
  }
}
