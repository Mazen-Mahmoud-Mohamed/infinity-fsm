import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/cache/session_query_cache.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/inventory/domain/entities/stock_movement.dart';
import 'package:mobile/features/inventory/domain/usecases/stock_movement_usecases.dart';

enum StockHistoryStatus { initial, loading, loadingMore, success, failure }

class StockHistoryState extends Equatable {
  const StockHistoryState({
    this.status = StockHistoryStatus.initial,
    this.items = const [],
    this.page = 1,
    this.hasMore = true,
    this.search = '',
    this.type,
    this.sparePartId,
    this.message,
    this.isRefreshing = false,
  });

  final StockHistoryStatus status;
  final List<StockMovement> items;
  final int page;
  final bool hasMore;
  final String search;
  final StockMovementType? type;
  final String? sparePartId;
  final String? message;
  final bool isRefreshing;

  StockHistoryState copyWith({
    StockHistoryStatus? status,
    List<StockMovement>? items,
    int? page,
    bool? hasMore,
    String? search,
    StockMovementType? type,
    bool clearType = false,
    String? sparePartId,
    String? message,
    bool? isRefreshing,
  }) {
    return StockHistoryState(
      status: status ?? this.status,
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      search: search ?? this.search,
      type: clearType ? null : (type ?? this.type),
      sparePartId: sparePartId ?? this.sparePartId,
      message: message,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [
        status,
        items,
        page,
        hasMore,
        search,
        type,
        sparePartId,
        message,
        isRefreshing,
      ];
}

class StockHistoryCubit extends Cubit<StockHistoryState> {
  StockHistoryCubit({
    required ListStockMovementsUseCase listMovements,
    required SessionQueryCache sessionCache,
    String? sparePartId,
  })  : _listMovements = listMovements,
        _sessionCache = sessionCache,
        super(StockHistoryState(sparePartId: sparePartId));

  static const int _pageSize = 20;

  final ListStockMovementsUseCase _listMovements;
  final SessionQueryCache _sessionCache;

  String _cacheKey(String search, StockMovementType? type, String? sparePartId) =>
      'inventory:stock_history:p1:s=$search:t=${type?.name ?? ''}:sp=${sparePartId ?? ''}';

  Future<void> loadFirstPage({
    String? search,
    StockMovementType? type,
    bool clearType = false,
  }) async {
    final nextSearch = search ?? state.search;
    final nextType = clearType ? null : (type ?? state.type);
    final sparePartId = state.sparePartId;
    final cacheKey = _cacheKey(nextSearch, nextType, sparePartId);
    final cached = _sessionCache.get<StockMovementPage>(cacheKey);

    if (cached != null) {
      emit(
        StockHistoryState(
          status: StockHistoryStatus.success,
          items: cached.items,
          page: cached.page,
          hasMore: cached.hasMore,
          search: nextSearch,
          type: nextType,
          sparePartId: sparePartId,
          isRefreshing: true,
        ),
      );
    } else if (state.items.isNotEmpty) {
      emit(
        state.copyWith(
          search: nextSearch,
          type: nextType,
          clearType: clearType,
          isRefreshing: true,
          message: null,
        ),
      );
    } else {
      emit(
        StockHistoryState(
          status: StockHistoryStatus.loading,
          search: nextSearch,
          type: nextType,
          sparePartId: sparePartId,
        ),
      );
    }

    final result = await _listMovements(
      page: 1,
      limit: _pageSize,
      search: nextSearch.isEmpty ? null : nextSearch,
      type: nextType,
      sparePartId: sparePartId,
    );

    switch (result) {
      case Success(data: final page):
        _sessionCache.set(cacheKey, page);
        emit(
          StockHistoryState(
            status: StockHistoryStatus.success,
            items: page.items,
            page: page.page,
            hasMore: page.hasMore,
            search: nextSearch,
            type: nextType,
            sparePartId: sparePartId,
          ),
        );
      case Failure(message: final message):
        if (state.items.isNotEmpty) {
          emit(
            state.copyWith(
              status: StockHistoryStatus.success,
              search: nextSearch,
              type: nextType,
              clearType: clearType,
              isRefreshing: false,
              message: message,
            ),
          );
        } else {
          emit(
            StockHistoryState(
              status: StockHistoryStatus.failure,
              search: nextSearch,
              type: nextType,
              sparePartId: sparePartId,
              message: message,
            ),
          );
        }
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore ||
        state.status == StockHistoryStatus.loading ||
        state.status == StockHistoryStatus.loadingMore) {
      return;
    }

    emit(state.copyWith(status: StockHistoryStatus.loadingMore));
    final nextPage = state.page + 1;
    final result = await _listMovements(
      page: nextPage,
      limit: _pageSize,
      search: state.search.isEmpty ? null : state.search,
      type: state.type,
      sparePartId: state.sparePartId,
    );

    switch (result) {
      case Success(data: final page):
        emit(
          state.copyWith(
            status: StockHistoryStatus.success,
            items: [...state.items, ...page.items],
            page: page.page,
            hasMore: page.hasMore,
          ),
        );
      case Failure(message: final message):
        emit(
          state.copyWith(
            status: StockHistoryStatus.success,
            message: message,
          ),
        );
    }
  }

  Future<void> setFilter(StockMovementType? type) {
    return loadFirstPage(type: type, clearType: type == null);
  }

  Future<void> search(String value) => loadFirstPage(search: value);
}
