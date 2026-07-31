import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/cache/session_query_cache.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/assets/domain/entities/asset_category.dart';
import 'package:mobile/features/assets/domain/usecases/assets_usecases.dart';

enum AssetCategoriesStatus { initial, loading, loadingMore, success, failure }

class AssetCategoriesState extends Equatable {
  const AssetCategoriesState({
    this.status = AssetCategoriesStatus.initial,
    this.items = const [],
    this.page = 1,
    this.hasMore = true,
    this.search = '',
    this.message,
    this.isRefreshing = false,
  });

  final AssetCategoriesStatus status;
  final List<AssetCategory> items;
  final int page;
  final bool hasMore;
  final String search;
  final String? message;
  final bool isRefreshing;

  AssetCategoriesState copyWith({
    AssetCategoriesStatus? status,
    List<AssetCategory>? items,
    int? page,
    bool? hasMore,
    String? search,
    String? message,
    bool? isRefreshing,
  }) {
    return AssetCategoriesState(
      status: status ?? this.status,
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      search: search ?? this.search,
      message: message,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props =>
      [status, items, page, hasMore, search, message, isRefreshing];
}

class AssetCategoriesCubit extends Cubit<AssetCategoriesState> {
  AssetCategoriesCubit({
    required ListAssetCategoriesUseCase listCategories,
    required CreateAssetCategoryUseCase createCategory,
    required UpdateAssetCategoryUseCase updateCategory,
    required DeleteAssetCategoryUseCase deleteCategory,
    required SessionQueryCache sessionCache,
  })  : _listCategories = listCategories,
        _createCategory = createCategory,
        _updateCategory = updateCategory,
        _deleteCategory = deleteCategory,
        _sessionCache = sessionCache,
        super(const AssetCategoriesState());

  static const int _pageSize = 20;
  final ListAssetCategoriesUseCase _listCategories;
  final CreateAssetCategoryUseCase _createCategory;
  final UpdateAssetCategoryUseCase _updateCategory;
  final DeleteAssetCategoryUseCase _deleteCategory;
  final SessionQueryCache _sessionCache;

  String _cacheKey(String search) => 'assets:categories:p1:s=$search';

  Future<void> loadFirstPage({String? search}) async {
    final nextSearch = search ?? state.search;
    final cacheKey = _cacheKey(nextSearch);
    final cached = _sessionCache.get<AssetCategoryPage>(cacheKey);

    if (cached != null) {
      emit(AssetCategoriesState(
        status: AssetCategoriesStatus.success,
        items: cached.items,
        page: cached.page,
        hasMore: cached.hasMore,
        search: nextSearch,
        isRefreshing: true,
      ));
    } else if (state.items.isNotEmpty) {
      emit(state.copyWith(
        search: nextSearch,
        isRefreshing: true,
        message: null,
      ));
    } else {
      emit(AssetCategoriesState(
        status: AssetCategoriesStatus.loading,
        search: nextSearch,
      ));
    }

    final result = await _listCategories(
      page: 1,
      limit: _pageSize,
      search: nextSearch.isEmpty ? null : nextSearch,
    );
    switch (result) {
      case Success(data: final page):
        _sessionCache.set(cacheKey, page);
        emit(AssetCategoriesState(
          status: AssetCategoriesStatus.success,
          items: page.items,
          page: page.page,
          hasMore: page.hasMore,
          search: nextSearch,
        ));
      case Failure(message: final message):
        if (state.items.isNotEmpty) {
          emit(state.copyWith(
            status: AssetCategoriesStatus.success,
            search: nextSearch,
            isRefreshing: false,
            message: message,
          ));
        } else {
          emit(AssetCategoriesState(
            status: AssetCategoriesStatus.failure,
            search: nextSearch,
            message: message,
          ));
        }
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore ||
        state.status == AssetCategoriesStatus.loading ||
        state.status == AssetCategoriesStatus.loadingMore) {
      return;
    }
    emit(state.copyWith(status: AssetCategoriesStatus.loadingMore));
    final result = await _listCategories(
      page: state.page + 1,
      limit: _pageSize,
      search: state.search.isEmpty ? null : state.search,
    );
    switch (result) {
      case Success(data: final page):
        emit(state.copyWith(
          status: AssetCategoriesStatus.success,
          items: [...state.items, ...page.items],
          page: page.page,
          hasMore: page.hasMore,
        ));
      case Failure(message: final message):
        emit(state.copyWith(
          status: AssetCategoriesStatus.success,
          message: message,
        ));
    }
  }

  Future<void> search(String value) => loadFirstPage(search: value);

  Future<Result<AssetCategory>> create(AssetCategoryUpsertInput input) =>
      _createCategory(input);

  Future<Result<AssetCategory>> update(
    String id,
    AssetCategoryUpsertInput input,
  ) =>
      _updateCategory(id, input);

  Future<Result<AssetCategory>> delete(String id) => _deleteCategory(id);
}
