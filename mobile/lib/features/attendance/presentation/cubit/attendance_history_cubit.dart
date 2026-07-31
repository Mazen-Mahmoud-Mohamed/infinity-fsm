import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/cache/session_query_cache.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/attendance/data/datasources/attendance_local_datasource.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_summary.dart';
import 'package:mobile/features/attendance/domain/usecases/get_attendance_history_usecase.dart';

enum AttendanceHistoryStatus { initial, loading, loadingMore, success, failure }

class AttendanceHistoryState extends Equatable {
  const AttendanceHistoryState({
    this.status = AttendanceHistoryStatus.initial,
    this.items = const [],
    this.page = 1,
    this.hasMore = true,
    this.isOffline = false,
    this.message,
    this.isRefreshing = false,
  });

  final AttendanceHistoryStatus status;
  final List<AttendanceSummaryEntity> items;
  final int page;
  final bool hasMore;
  final bool isOffline;
  final String? message;
  final bool isRefreshing;

  AttendanceHistoryState copyWith({
    AttendanceHistoryStatus? status,
    List<AttendanceSummaryEntity>? items,
    int? page,
    bool? hasMore,
    bool? isOffline,
    String? message,
    bool? isRefreshing,
  }) {
    return AttendanceHistoryState(
      status: status ?? this.status,
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isOffline: isOffline ?? this.isOffline,
      message: message,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props =>
      [status, items, page, hasMore, isOffline, message, isRefreshing];
}

class _CachedAttendanceHistory {
  const _CachedAttendanceHistory({
    required this.items,
    required this.hasMore,
  });

  final List<AttendanceSummaryEntity> items;
  final bool hasMore;
}

class AttendanceHistoryCubit extends Cubit<AttendanceHistoryState> {
  AttendanceHistoryCubit({
    required GetAttendanceHistoryUseCase useCase,
    required SessionQueryCache sessionQueryCache,
    required AttendanceLocalDataSource localDataSource,
  })  : _useCase = useCase,
        _sessionQueryCache = sessionQueryCache,
        _localDataSource = localDataSource,
        super(const AttendanceHistoryState());

  static const int _pageSize = 20;
  static const String _cacheKey = 'attendance:history:page1';

  final GetAttendanceHistoryUseCase _useCase;
  final SessionQueryCache _sessionQueryCache;
  final AttendanceLocalDataSource _localDataSource;

  Future<void> loadFirstPage({bool forceRefresh = false}) async {
    final cached = _sessionQueryCache.get<_CachedAttendanceHistory>(_cacheKey);
    final localItems = _localDataSource.readHistory();
    final seededItems = cached?.items ??
        (localItems.isNotEmpty ? localItems : state.items);
    final hasData = seededItems.isNotEmpty;

    if (hasData) {
      emit(
        state.copyWith(
          status: AttendanceHistoryStatus.success,
          items: seededItems,
          page: 1,
          hasMore: cached?.hasMore ?? seededItems.length >= _pageSize,
          isRefreshing: true,
        ),
      );
    } else {
      emit(
        state.copyWith(
          status: AttendanceHistoryStatus.loading,
          isRefreshing: false,
        ),
      );
    }

    final result = await _useCase(
      page: 1,
      limit: _pageSize,
      forceRefresh: forceRefresh,
    );

    switch (result) {
      case Success(data: final items):
        final next = _CachedAttendanceHistory(
          items: items,
          hasMore: items.length >= _pageSize,
        );
        _sessionQueryCache.set(_cacheKey, next);
        emit(
          AttendanceHistoryState(
            status: AttendanceHistoryStatus.success,
            items: items,
            page: 1,
            hasMore: next.hasMore,
            isRefreshing: false,
          ),
        );
      case Failure(message: final message, code: final code):
        emit(
          state.copyWith(
            status: hasData
                ? AttendanceHistoryStatus.success
                : AttendanceHistoryStatus.failure,
            message: message,
            isOffline: code == 'OFFLINE',
            isRefreshing: false,
          ),
        );
    }
  }

  Future<void> loadMore() async {
    if (state.status == AttendanceHistoryStatus.loadingMore || !state.hasMore) {
      return;
    }

    emit(state.copyWith(status: AttendanceHistoryStatus.loadingMore));

    final nextPage = state.page + 1;
    final result = await _useCase(page: nextPage, limit: _pageSize);

    switch (result) {
      case Success(data: final items):
        emit(
          state.copyWith(
            status: AttendanceHistoryStatus.success,
            items: [...state.items, ...items],
            page: nextPage,
            hasMore: items.length >= _pageSize,
          ),
        );
      case Failure(message: final message, code: final code):
        emit(
          state.copyWith(
            status: AttendanceHistoryStatus.success,
            message: message,
            isOffline: code == 'OFFLINE',
          ),
        );
    }
  }
}
