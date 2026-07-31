import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/cache/session_query_cache.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/assets/domain/entities/asset.dart';
import 'package:mobile/features/assets/domain/usecases/assets_usecases.dart';

enum AssetsListStatus { initial, loading, loadingMore, success, failure }

class AssetsListState extends Equatable {
  const AssetsListState({
    this.status = AssetsListStatus.initial,
    this.items = const [],
    this.page = 1,
    this.hasMore = true,
    this.search = '',
    this.filterStatus,
    this.message,
    this.isRefreshing = false,
  });

  final AssetsListStatus status;
  final List<Asset> items;
  final int page;
  final bool hasMore;
  final String search;
  final AssetStatus? filterStatus;
  final String? message;
  final bool isRefreshing;

  AssetsListState copyWith({
    AssetsListStatus? status,
    List<Asset>? items,
    int? page,
    bool? hasMore,
    String? search,
    AssetStatus? filterStatus,
    bool clearFilterStatus = false,
    String? message,
    bool? isRefreshing,
  }) {
    return AssetsListState(
      status: status ?? this.status,
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      search: search ?? this.search,
      filterStatus:
          clearFilterStatus ? null : (filterStatus ?? this.filterStatus),
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
        filterStatus,
        message,
        isRefreshing,
      ];
}

class AssetsListCubit extends Cubit<AssetsListState> {
  AssetsListCubit({
    required ListAssetsUseCase listAssets,
    required SessionQueryCache sessionCache,
  })  : _listAssets = listAssets,
        _sessionCache = sessionCache,
        super(const AssetsListState());

  static const int _pageSize = 20;
  final ListAssetsUseCase _listAssets;
  final SessionQueryCache _sessionCache;

  String _cacheKey(String search, AssetStatus? status) =>
      'assets:list:p1:s=$search:st=${status?.name ?? ''}';

  Future<void> loadFirstPage({
    String? search,
    AssetStatus? status,
    bool clearStatus = false,
  }) async {
    final nextSearch = search ?? state.search;
    final nextStatus =
        clearStatus ? null : (status ?? state.filterStatus);
    final cacheKey = _cacheKey(nextSearch, nextStatus);
    final cached = _sessionCache.get<AssetPage>(cacheKey);

    if (cached != null) {
      emit(AssetsListState(
        status: AssetsListStatus.success,
        items: cached.items,
        page: cached.page,
        hasMore: cached.hasMore,
        search: nextSearch,
        filterStatus: nextStatus,
        isRefreshing: true,
      ));
    } else if (state.items.isNotEmpty) {
      emit(state.copyWith(
        search: nextSearch,
        filterStatus: nextStatus,
        clearFilterStatus: clearStatus,
        isRefreshing: true,
        message: null,
      ));
    } else {
      emit(AssetsListState(
        status: AssetsListStatus.loading,
        search: nextSearch,
        filterStatus: nextStatus,
      ));
    }

    final result = await _listAssets(
      page: 1,
      limit: _pageSize,
      search: nextSearch.isEmpty ? null : nextSearch,
      status: nextStatus,
    );
    switch (result) {
      case Success(data: final page):
        _sessionCache.set(cacheKey, page);
        emit(AssetsListState(
          status: AssetsListStatus.success,
          items: page.items,
          page: page.page,
          hasMore: page.hasMore,
          search: nextSearch,
          filterStatus: nextStatus,
        ));
      case Failure(message: final message):
        if (state.items.isNotEmpty) {
          emit(state.copyWith(
            status: AssetsListStatus.success,
            search: nextSearch,
            filterStatus: nextStatus,
            clearFilterStatus: clearStatus,
            isRefreshing: false,
            message: message,
          ));
        } else {
          emit(AssetsListState(
            status: AssetsListStatus.failure,
            search: nextSearch,
            filterStatus: nextStatus,
            message: message,
          ));
        }
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore ||
        state.status == AssetsListStatus.loading ||
        state.status == AssetsListStatus.loadingMore) {
      return;
    }
    emit(state.copyWith(status: AssetsListStatus.loadingMore));
    final result = await _listAssets(
      page: state.page + 1,
      limit: _pageSize,
      search: state.search.isEmpty ? null : state.search,
      status: state.filterStatus,
    );
    switch (result) {
      case Success(data: final page):
        emit(state.copyWith(
          status: AssetsListStatus.success,
          items: [...state.items, ...page.items],
          page: page.page,
          hasMore: page.hasMore,
        ));
      case Failure(message: final message):
        emit(state.copyWith(
          status: AssetsListStatus.success,
          message: message,
        ));
    }
  }

  Future<void> setFilter(AssetStatus? status) =>
      loadFirstPage(status: status, clearStatus: status == null);

  Future<void> search(String value) => loadFirstPage(search: value);
}
