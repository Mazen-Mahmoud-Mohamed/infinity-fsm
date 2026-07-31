import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/cache/session_query_cache.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/auth/domain/entities/current_user.dart';
import 'package:mobile/features/organization/domain/entities/organization_context.dart';
import 'package:mobile/features/organization/domain/repositories/organization_repository.dart';

enum ProfileStatus {
  initial,
  loading,
  success,
  failure,
}

class ProfileState extends Equatable {
  const ProfileState({
    this.status = ProfileStatus.initial,
    this.user,
    this.context,
    this.isOffline = false,
    this.message,
    this.isRefreshing = false,
  });

  final ProfileStatus status;
  final CurrentUser? user;
  final OrganizationContext? context;
  final bool isOffline;
  final String? message;
  final bool isRefreshing;

  ProfileState copyWith({
    ProfileStatus? status,
    CurrentUser? user,
    OrganizationContext? context,
    bool? isOffline,
    String? message,
    bool? isRefreshing,
  }) {
    return ProfileState(
      status: status ?? this.status,
      user: user ?? this.user,
      context: context ?? this.context,
      isOffline: isOffline ?? this.isOffline,
      message: message,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props =>
      [status, user, context, isOffline, message, isRefreshing];
}

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({
    required OrganizationRepository repository,
    required SessionQueryCache sessionQueryCache,
  })  : _repository = repository,
        _sessionQueryCache = sessionQueryCache,
        super(const ProfileState());

  static const String _cacheKey = 'profile:context';

  final OrganizationRepository _repository;
  final SessionQueryCache _sessionQueryCache;

  Future<void> load(CurrentUser? user, {bool forceRefresh = false}) async {
    final cached = _sessionQueryCache.get<OrganizationContext>(_cacheKey);
    final hasData = cached != null || state.context != null;

    if (hasData) {
      emit(
        state.copyWith(
          status: ProfileStatus.success,
          user: user,
          context: cached ?? state.context,
          isRefreshing: true,
        ),
      );
    } else {
      emit(
        state.copyWith(
          status: ProfileStatus.loading,
          user: user,
          isRefreshing: false,
        ),
      );
    }

    final result = await _repository.getMyContext(forceRefresh: forceRefresh);
    switch (result) {
      case Success(data: final context):
        _sessionQueryCache.set(_cacheKey, context);
        emit(
          state.copyWith(
            status: ProfileStatus.success,
            user: user,
            context: context,
            isOffline: false,
            message: null,
            isRefreshing: false,
          ),
        );
      case Failure(message: final message, code: final code):
        final offline = code == 'OFFLINE' ||
            code == 'TIMEOUT' ||
            code == 'NETWORK_ERROR';
        emit(
          state.copyWith(
            status: hasData ? ProfileStatus.success : ProfileStatus.failure,
            user: user,
            isOffline: offline,
            message: offline ? null : message,
            isRefreshing: false,
          ),
        );
    }
  }
}
