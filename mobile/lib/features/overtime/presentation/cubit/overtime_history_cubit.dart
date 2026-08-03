import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/cache/session_query_cache.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/overtime/data/datasources/overtime_local_datasource.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:mobile/features/overtime/domain/usecases/list_my_overtime_usecase.dart';

enum OvertimeHistoryStatus { initial, loading, loadingMore, success, failure }

class OvertimeHistoryState extends Equatable {
  const OvertimeHistoryState({
    this.status = OvertimeHistoryStatus.initial,
    this.items = const [],
    this.page = 1,
    this.hasMore = true,
    this.message,
    this.isOffline = false,
    this.isRefreshing = false,
  });

  final OvertimeHistoryStatus status;
  final List<OvertimeSession> items;
  final int page;
  final bool hasMore;
  final String? message;
  final bool isOffline;
  final bool isRefreshing;

  OvertimeHistoryState copyWith({
    OvertimeHistoryStatus? status,
    List<OvertimeSession>? items,
    int? page,
    bool? hasMore,
    String? message,
    bool? isOffline,
    bool? isRefreshing,
  }) {
    return OvertimeHistoryState(
      status: status ?? this.status,
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      message: message,
      isOffline: isOffline ?? this.isOffline,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props =>
      [status, items, page, hasMore, message, isOffline, isRefreshing];
}

class _CachedOvertimeHistory {
  const _CachedOvertimeHistory({
    required this.items,
    required this.page,
    required this.hasMore,
  });

  final List<OvertimeSession> items;
  final int page;
  final bool hasMore;
}

class OvertimeHistoryCubit extends Cubit<OvertimeHistoryState> {
  OvertimeHistoryCubit({
    required ListMyOvertimeUseCase listMine,
    required SessionQueryCache sessionQueryCache,
    required OvertimeLocalDataSource localDataSource,
  })  : _listMine = listMine,
        _sessionQueryCache = sessionQueryCache,
        _localDataSource = localDataSource,
        super(const OvertimeHistoryState());

  static const int _pageSize = 20;
  static const String _cacheKey = 'overtime:history:mine:page1';

  final ListMyOvertimeUseCase _listMine;
  final SessionQueryCache _sessionQueryCache;
  final OvertimeLocalDataSource _localDataSource;

  Future<void> loadFirstPage() async {
    final cached = _sessionQueryCache.get<_CachedOvertimeHistory>(_cacheKey);
    final localItems = _localDataSource.readHistory();
    // Prefer durable local pending sessions over a stale empty memory cache.
    // Empty cached remote results previously hid offline sessions on History open.
    final seededItems = localItems.isNotEmpty
        ? localItems
        : (cached?.items ?? state.items);
    final hasData = seededItems.isNotEmpty;

    if (hasData) {
      emit(
        state.copyWith(
          status: OvertimeHistoryStatus.success,
          items: seededItems,
          page: cached?.page ?? 1,
          hasMore: cached?.hasMore ?? seededItems.length >= _pageSize,
          isRefreshing: true,
        ),
      );
    } else {
      emit(
        state.copyWith(
          status: OvertimeHistoryStatus.loading,
          isRefreshing: false,
        ),
      );
    }

    final result = await _listMine(page: 1, limit: _pageSize);
    switch (result) {
      case Success(data: final page):
        // Prefer merged page from repository (includes local pending-sync
        // sessions). Never replace a non-empty local seed with an empty
        // remote-only payload if pending offline work still exists.
        final pendingQueue = _localDataSource.readQueue();
        final latestLocal = _localDataSource.readHistory();
        final resolvedItems = page.items.isNotEmpty
            ? page.items
            : (pendingQueue.isNotEmpty ||
                    latestLocal.any((s) => s.id.startsWith('local-')))
                ? (latestLocal.isNotEmpty ? latestLocal : seededItems)
                : page.items;
        final next = _CachedOvertimeHistory(
          items: resolvedItems,
          page: page.page,
          hasMore: page.hasMore && page.items.isNotEmpty,
        );
        _sessionQueryCache.set(_cacheKey, next);
        emit(
          OvertimeHistoryState(
            status: OvertimeHistoryStatus.success,
            items: resolvedItems,
            page: page.page,
            hasMore: next.hasMore,
            isOffline: false,
            isRefreshing: false,
          ),
        );
      case Failure(message: final message, code: final code):
        final offline = code == 'OFFLINE' ||
            code == 'TIMEOUT' ||
            code == 'NETWORK_ERROR';
        final fallbackItems = localItems.isNotEmpty
            ? localItems
            : (state.items.isNotEmpty ? state.items : seededItems);
        emit(
          state.copyWith(
            status: (offline || fallbackItems.isNotEmpty)
                ? OvertimeHistoryStatus.success
                : OvertimeHistoryStatus.failure,
            items: fallbackItems.isNotEmpty ? fallbackItems : state.items,
            message: offline ? null : message,
            isOffline: offline,
            isRefreshing: false,
          ),
        );
    }
  }

  Future<void> loadMore() async {
    if (state.status == OvertimeHistoryStatus.loadingMore || !state.hasMore) {
      return;
    }

    emit(state.copyWith(status: OvertimeHistoryStatus.loadingMore));

    final nextPage = state.page + 1;
    final result = await _listMine(page: nextPage, limit: _pageSize);

    switch (result) {
      case Success(data: final page):
        emit(
          state.copyWith(
            status: OvertimeHistoryStatus.success,
            items: [...state.items, ...page.items],
            page: page.page,
            hasMore: page.hasMore,
            isOffline: false,
          ),
        );
      case Failure(message: final message, code: final code):
        final offline = code == 'OFFLINE' ||
            code == 'TIMEOUT' ||
            code == 'NETWORK_ERROR';
        emit(
          state.copyWith(
            status: OvertimeHistoryStatus.success,
            message: offline ? null : message,
            isOffline: offline,
          ),
        );
    }
  }
}
