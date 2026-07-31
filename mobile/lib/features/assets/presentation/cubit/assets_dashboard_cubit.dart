import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/cache/session_query_cache.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/assets/domain/entities/assets_dashboard.dart';
import 'package:mobile/features/assets/domain/usecases/assets_usecases.dart';

enum AssetsDashboardStatus { initial, loading, success, failure }

class AssetsDashboardState extends Equatable {
  const AssetsDashboardState({
    this.status = AssetsDashboardStatus.initial,
    this.dashboard,
    this.message,
    this.isRefreshing = false,
  });

  final AssetsDashboardStatus status;
  final AssetsDashboard? dashboard;
  final String? message;
  final bool isRefreshing;

  AssetsDashboardState copyWith({
    AssetsDashboardStatus? status,
    AssetsDashboard? dashboard,
    String? message,
    bool? isRefreshing,
  }) {
    return AssetsDashboardState(
      status: status ?? this.status,
      dashboard: dashboard ?? this.dashboard,
      message: message,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [status, dashboard, message, isRefreshing];
}

class AssetsDashboardCubit extends Cubit<AssetsDashboardState> {
  AssetsDashboardCubit({
    required GetAssetsDashboardUseCase getDashboard,
    required SessionQueryCache sessionCache,
  })  : _getDashboard = getDashboard,
        _sessionCache = sessionCache,
        super(const AssetsDashboardState());

  static const _cacheKey = 'assets:dashboard';

  final GetAssetsDashboardUseCase _getDashboard;
  final SessionQueryCache _sessionCache;

  Future<void> load() async {
    final cached = _sessionCache.get<AssetsDashboard>(_cacheKey);

    if (cached != null) {
      emit(AssetsDashboardState(
        status: AssetsDashboardStatus.success,
        dashboard: cached,
        isRefreshing: true,
      ));
    } else if (state.dashboard != null) {
      emit(state.copyWith(isRefreshing: true, message: null));
    } else {
      emit(state.copyWith(status: AssetsDashboardStatus.loading));
    }

    final result = await _getDashboard();
    switch (result) {
      case Success(data: final data):
        _sessionCache.set(_cacheKey, data);
        emit(AssetsDashboardState(
          status: AssetsDashboardStatus.success,
          dashboard: data,
        ));
      case Failure(message: final message):
        if (state.dashboard != null) {
          emit(state.copyWith(
            status: AssetsDashboardStatus.success,
            isRefreshing: false,
            message: message,
          ));
        } else {
          emit(AssetsDashboardState(
            status: AssetsDashboardStatus.failure,
            message: message,
          ));
        }
    }
  }
}
