import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/cache/session_query_cache.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/inventory/domain/entities/spare_part.dart';
import 'package:mobile/features/inventory/domain/usecases/spare_part_usecases.dart';

enum SparePartsListStatus { initial, loading, loadingMore, success, failure }

class SparePartsListState extends Equatable {
  const SparePartsListState({
    this.status = SparePartsListStatus.initial,
    this.items = const [],
    this.page = 1,
    this.hasMore = true,
    this.search = '',
    this.stockStatus,
    this.message,
    this.isRefreshing = false,
  });

  final SparePartsListStatus status;
  final List<SparePart> items;
  final int page;
  final bool hasMore;
  final String search;
  final StockStatus? stockStatus;
  final String? message;
  final bool isRefreshing;

  SparePartsListState copyWith({
    SparePartsListStatus? status,
    List<SparePart>? items,
    int? page,
    bool? hasMore,
    String? search,
    StockStatus? stockStatus,
    bool clearStockStatus = false,
    String? message,
    bool? isRefreshing,
  }) {
    return SparePartsListState(
      status: status ?? this.status,
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      search: search ?? this.search,
      stockStatus:
          clearStockStatus ? null : (stockStatus ?? this.stockStatus),
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
        stockStatus,
        message,
        isRefreshing,
      ];
}

class SparePartsListCubit extends Cubit<SparePartsListState> {
  SparePartsListCubit({
    required ListSparePartsUseCase listSpareParts,
    required SessionQueryCache sessionCache,
  })  : _listSpareParts = listSpareParts,
        _sessionCache = sessionCache,
        super(const SparePartsListState());

  static const int _pageSize = 20;

  final ListSparePartsUseCase _listSpareParts;
  final SessionQueryCache _sessionCache;

  String _cacheKey(String search, StockStatus? stockStatus) =>
      'inventory:spare_parts:p1:s=$search:st=${stockStatus?.name ?? ''}';

  Future<void> loadFirstPage({
    String? search,
    StockStatus? stockStatus,
    bool clearStockStatus = false,
  }) async {
    final nextSearch = search ?? state.search;
    final nextStatus =
        clearStockStatus ? null : (stockStatus ?? state.stockStatus);
    final cacheKey = _cacheKey(nextSearch, nextStatus);
    final cached = _sessionCache.get<SparePartPage>(cacheKey);

    if (cached != null) {
      emit(
        SparePartsListState(
          status: SparePartsListStatus.success,
          items: cached.items,
          page: cached.page,
          hasMore: cached.hasMore,
          search: nextSearch,
          stockStatus: nextStatus,
          isRefreshing: true,
        ),
      );
    } else if (state.items.isNotEmpty) {
      emit(
        state.copyWith(
          search: nextSearch,
          stockStatus: nextStatus,
          clearStockStatus: clearStockStatus,
          isRefreshing: true,
          message: null,
        ),
      );
    } else {
      emit(
        SparePartsListState(
          status: SparePartsListStatus.loading,
          search: nextSearch,
          stockStatus: nextStatus,
        ),
      );
    }

    final result = await _listSpareParts(
      page: 1,
      limit: _pageSize,
      search: nextSearch.isEmpty ? null : nextSearch,
      stockStatus: nextStatus,
    );

    switch (result) {
      case Success(data: final page):
        _sessionCache.set(cacheKey, page);
        emit(
          SparePartsListState(
            status: SparePartsListStatus.success,
            items: page.items,
            page: page.page,
            hasMore: page.hasMore,
            search: nextSearch,
            stockStatus: nextStatus,
          ),
        );
      case Failure(message: final message):
        if (state.items.isNotEmpty) {
          emit(
            state.copyWith(
              status: SparePartsListStatus.success,
              search: nextSearch,
              stockStatus: nextStatus,
              clearStockStatus: clearStockStatus,
              isRefreshing: false,
              message: message,
            ),
          );
        } else {
          emit(
            SparePartsListState(
              status: SparePartsListStatus.failure,
              search: nextSearch,
              stockStatus: nextStatus,
              message: message,
            ),
          );
        }
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore ||
        state.status == SparePartsListStatus.loading ||
        state.status == SparePartsListStatus.loadingMore) {
      return;
    }

    emit(state.copyWith(status: SparePartsListStatus.loadingMore));
    final nextPage = state.page + 1;
    final result = await _listSpareParts(
      page: nextPage,
      limit: _pageSize,
      search: state.search.isEmpty ? null : state.search,
      stockStatus: state.stockStatus,
    );

    switch (result) {
      case Success(data: final page):
        emit(
          state.copyWith(
            status: SparePartsListStatus.success,
            items: [...state.items, ...page.items],
            page: page.page,
            hasMore: page.hasMore,
          ),
        );
      case Failure(message: final message):
        emit(
          state.copyWith(
            status: SparePartsListStatus.success,
            message: message,
          ),
        );
    }
  }

  Future<void> setFilter(StockStatus? status) {
    return loadFirstPage(
      stockStatus: status,
      clearStockStatus: status == null,
    );
  }

  Future<void> search(String value) => loadFirstPage(search: value);
}
