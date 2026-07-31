import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/cache/session_query_cache.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/pm/domain/entities/pm_entities.dart';
import 'package:mobile/features/pm/domain/usecases/pm_usecases.dart';

enum PmDashboardStatus { initial, loading, success, failure }

class PmDashboardState extends Equatable {
  const PmDashboardState({
    this.status = PmDashboardStatus.initial,
    this.dashboard,
    this.message,
    this.isRefreshing = false,
  });

  final PmDashboardStatus status;
  final PmDashboard? dashboard;
  final String? message;
  final bool isRefreshing;

  PmDashboardState copyWith({
    PmDashboardStatus? status,
    PmDashboard? dashboard,
    String? message,
    bool? isRefreshing,
  }) {
    return PmDashboardState(
      status: status ?? this.status,
      dashboard: dashboard ?? this.dashboard,
      message: message,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [status, dashboard, message, isRefreshing];
}

class PmDashboardCubit extends Cubit<PmDashboardState> {
  PmDashboardCubit({
    required GetPmDashboardUseCase getDashboard,
    required SessionQueryCache queryCache,
  })  : _getDashboard = getDashboard,
        _queryCache = queryCache,
        super(const PmDashboardState());

  static const _cacheKey = 'pm:dashboard';

  final GetPmDashboardUseCase _getDashboard;
  final SessionQueryCache _queryCache;

  Future<void> load() async {
    final cached = _queryCache.get<PmDashboard>(_cacheKey);
    if (cached != null) {
      emit(PmDashboardState(
        status: PmDashboardStatus.success,
        dashboard: cached,
        isRefreshing: true,
      ));
    } else if (state.dashboard != null) {
      emit(state.copyWith(
        status: PmDashboardStatus.success,
        isRefreshing: true,
      ));
    } else {
      emit(const PmDashboardState(status: PmDashboardStatus.loading));
    }

    final result = await _getDashboard();
    switch (result) {
      case Success(data: final data):
        _queryCache.set(_cacheKey, data);
        emit(PmDashboardState(
          status: PmDashboardStatus.success,
          dashboard: data,
        ));
      case Failure(message: final message):
        if (state.dashboard != null) {
          emit(PmDashboardState(
            status: PmDashboardStatus.success,
            dashboard: state.dashboard,
            message: message,
          ));
        } else {
          emit(PmDashboardState(
            status: PmDashboardStatus.failure,
            message: message,
          ));
        }
    }
  }
}
