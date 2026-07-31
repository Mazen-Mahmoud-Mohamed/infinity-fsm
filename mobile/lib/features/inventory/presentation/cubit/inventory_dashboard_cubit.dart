import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/cache/session_query_cache.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/inventory/domain/entities/inventory_dashboard.dart';
import 'package:mobile/features/inventory/domain/usecases/get_inventory_dashboard_usecase.dart';

enum InventoryDashboardStatus { initial, loading, success, failure }

class InventoryDashboardState extends Equatable {
  const InventoryDashboardState({
    this.status = InventoryDashboardStatus.initial,
    this.dashboard,
    this.message,
    this.isRefreshing = false,
  });

  final InventoryDashboardStatus status;
  final InventoryDashboard? dashboard;
  final String? message;
  final bool isRefreshing;

  InventoryDashboardState copyWith({
    InventoryDashboardStatus? status,
    InventoryDashboard? dashboard,
    String? message,
    bool? isRefreshing,
  }) {
    return InventoryDashboardState(
      status: status ?? this.status,
      dashboard: dashboard ?? this.dashboard,
      message: message,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [status, dashboard, message, isRefreshing];
}

class InventoryDashboardCubit extends Cubit<InventoryDashboardState> {
  InventoryDashboardCubit({
    required GetInventoryDashboardUseCase getDashboard,
    required SessionQueryCache sessionCache,
  })  : _getDashboard = getDashboard,
        _sessionCache = sessionCache,
        super(const InventoryDashboardState());

  static const _cacheKey = 'inventory:dashboard';

  final GetInventoryDashboardUseCase _getDashboard;
  final SessionQueryCache _sessionCache;

  Future<void> load() async {
    final cached = _sessionCache.get<InventoryDashboard>(_cacheKey);

    if (cached != null) {
      emit(
        InventoryDashboardState(
          status: InventoryDashboardStatus.success,
          dashboard: cached,
          isRefreshing: true,
        ),
      );
    } else if (state.dashboard != null) {
      emit(state.copyWith(isRefreshing: true, message: null));
    } else {
      emit(state.copyWith(status: InventoryDashboardStatus.loading));
    }

    final result = await _getDashboard();
    switch (result) {
      case Success(data: final data):
        _sessionCache.set(_cacheKey, data);
        emit(
          InventoryDashboardState(
            status: InventoryDashboardStatus.success,
            dashboard: data,
          ),
        );
      case Failure(message: final message):
        if (state.dashboard != null) {
          emit(
            state.copyWith(
              status: InventoryDashboardStatus.success,
              isRefreshing: false,
              message: message,
            ),
          );
        } else {
          emit(
            InventoryDashboardState(
              status: InventoryDashboardStatus.failure,
              message: message,
            ),
          );
        }
    }
  }
}
