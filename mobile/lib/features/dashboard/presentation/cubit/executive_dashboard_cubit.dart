import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/cache/session_query_cache.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/dashboard/domain/entities/role_dashboard_summary.dart';
import 'package:mobile/features/dashboard/domain/usecases/get_dashboard_summary_usecase.dart';

enum ExecutiveDashboardStatus { initial, loading, success, failure }

class ExecutiveDashboardState extends Equatable {
  const ExecutiveDashboardState({
    this.status = ExecutiveDashboardStatus.initial,
    this.summary,
    this.period = DashboardPeriod.month,
    this.customFrom,
    this.customTo,
    this.message,
    this.isRefreshing = false,
    this.hasLoadedOnce = false,
  });

  final ExecutiveDashboardStatus status;
  final RoleDashboardSummary? summary;
  final DashboardPeriod period;
  final DateTime? customFrom;
  final DateTime? customTo;
  final String? message;
  final bool isRefreshing;
  final bool hasLoadedOnce;

  ExecutiveDashboardState copyWith({
    ExecutiveDashboardStatus? status,
    RoleDashboardSummary? summary,
    DashboardPeriod? period,
    DateTime? customFrom,
    DateTime? customTo,
    bool clearCustomRange = false,
    String? message,
    bool clearMessage = false,
    bool? isRefreshing,
    bool? hasLoadedOnce,
  }) {
    return ExecutiveDashboardState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      period: period ?? this.period,
      customFrom: clearCustomRange ? null : (customFrom ?? this.customFrom),
      customTo: clearCustomRange ? null : (customTo ?? this.customTo),
      message: clearMessage ? null : (message ?? this.message),
      isRefreshing: isRefreshing ?? this.isRefreshing,
      hasLoadedOnce: hasLoadedOnce ?? this.hasLoadedOnce,
    );
  }

  @override
  List<Object?> get props => [
        status,
        summary,
        period,
        customFrom,
        customTo,
        message,
        isRefreshing,
        hasLoadedOnce,
      ];
}

class ExecutiveDashboardCubit extends Cubit<ExecutiveDashboardState> {
  ExecutiveDashboardCubit({
    required GetDashboardSummaryUseCase getDashboardSummary,
    required SessionQueryCache sessionQueryCache,
  })  : _getDashboardSummary = getDashboardSummary,
        _sessionQueryCache = sessionQueryCache,
        super(const ExecutiveDashboardState());

  final GetDashboardSummaryUseCase _getDashboardSummary;
  final SessionQueryCache _sessionQueryCache;


  String _cacheKey({
    DashboardPeriod? period,
    DateTime? from,
    DateTime? to,
  }) {
    final p = period ?? state.period;
    final f = from ?? state.customFrom;
    final t = to ?? state.customTo;
    final fromKey = f?.toIso8601String() ?? '';
    final toKey = t?.toIso8601String() ?? '';
    return 'dashboard:summary:${p.name}:$fromKey:$toKey';
  }

  Future<void> setPeriod(DashboardPeriod period) async {
    if (period == DashboardPeriod.custom) return;
    if (state.period == period &&
        state.customFrom == null &&
        state.customTo == null &&
        state.hasLoadedOnce) {
      await load();
      return;
    }
    emit(
      state.copyWith(
        period: period,
        clearCustomRange: true,
        clearMessage: true,
      ),
    );
    await load();
  }

  Future<void> setCustomRange(DateTime from, DateTime to) async {
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day, 23, 59, 59, 999);
    emit(
      state.copyWith(
        period: DashboardPeriod.custom,
        customFrom: start,
        customTo: end,
        clearMessage: true,
      ),
    );
    await load();
  }

  Future<void> load() async {
    final cacheKey = _cacheKey();
    final cached = _sessionQueryCache.get<RoleDashboardSummary>(cacheKey);
    final hasData =
        state.hasLoadedOnce || cached != null || state.summary != null;

    debugPrint(
      'DashboardCubit.load start key=$cacheKey '
      'hasData=$hasData cached=${cached != null} '
      'period=${state.period.name}',
    );

    if (cached != null && !state.hasLoadedOnce) {
      emit(
        state.copyWith(
          status: ExecutiveDashboardStatus.success,
          summary: cached,
          isRefreshing: true,
          hasLoadedOnce: true,
          clearMessage: true,
        ),
      );
    } else if (hasData) {
      emit(
        state.copyWith(
          status: ExecutiveDashboardStatus.success,
          isRefreshing: true,
          clearMessage: true,
        ),
      );
    } else {
      emit(
        state.copyWith(
          status: ExecutiveDashboardStatus.loading,
          isRefreshing: false,
          clearMessage: true,
        ),
      );
    }

    try {
      debugPrint('DashboardCubit.load API request…');
      final result = await _getDashboardSummary(
        period: state.period,
        from: state.customFrom,
        to: state.customTo,
      );

      switch (result) {
        case Success<RoleDashboardSummary>(data: final data):
          debugPrint(
            'DashboardCubit.load API success viewRole=${data.viewRole}',
          );
          _sessionQueryCache.set(cacheKey, data);
          emit(
            ExecutiveDashboardState(
              status: ExecutiveDashboardStatus.success,
              summary: data,
              period: state.period,
              customFrom: state.customFrom,
              customTo: state.customTo,
              isRefreshing: false,
              hasLoadedOnce: true,
            ),
          );
        case Failure(:final message):
          debugPrint('DashboardCubit.load API failure message=$message');
          if (state.summary != null || cached != null) {
            emit(
              state.copyWith(
                status: ExecutiveDashboardStatus.success,
                summary: state.summary ?? cached,
                isRefreshing: false,
                message: message,
                hasLoadedOnce: true,
              ),
            );
          } else {
            emit(
              ExecutiveDashboardState(
                status: ExecutiveDashboardStatus.failure,
                period: state.period,
                customFrom: state.customFrom,
                customTo: state.customTo,
                message: message,
                isRefreshing: false,
                hasLoadedOnce: true,
              ),
            );
          }
      }
    } catch (e, st) {
      debugPrint('DashboardCubit.load exception: $e\n$st');
      emit(
        ExecutiveDashboardState(
          status: ExecutiveDashboardStatus.failure,
          period: state.period,
          customFrom: state.customFrom,
          customTo: state.customTo,
          message: e.toString(),
          isRefreshing: false,
          hasLoadedOnce: true,
          summary: state.summary ?? cached,
        ),
      );
    }
  }
}
