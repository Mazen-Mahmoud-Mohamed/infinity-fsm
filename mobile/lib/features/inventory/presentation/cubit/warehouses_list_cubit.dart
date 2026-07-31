import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/cache/session_query_cache.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/inventory/domain/entities/warehouse.dart';
import 'package:mobile/features/inventory/domain/usecases/list_warehouses_usecase.dart';
import 'package:mobile/features/inventory/domain/usecases/warehouse_mutations_usecase.dart';

enum WarehousesListStatus { initial, loading, loadingMore, success, failure }

class WarehousesListState extends Equatable {
  const WarehousesListState({
    this.status = WarehousesListStatus.initial,
    this.items = const [],
    this.page = 1,
    this.hasMore = true,
    this.search = '',
    this.message,
    this.isRefreshing = false,
  });

  final WarehousesListStatus status;
  final List<Warehouse> items;
  final int page;
  final bool hasMore;
  final String search;
  final String? message;
  final bool isRefreshing;

  WarehousesListState copyWith({
    WarehousesListStatus? status,
    List<Warehouse>? items,
    int? page,
    bool? hasMore,
    String? search,
    String? message,
    bool? isRefreshing,
  }) {
    return WarehousesListState(
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

class WarehousesListCubit extends Cubit<WarehousesListState> {
  WarehousesListCubit({
    required ListWarehousesUseCase listWarehouses,
    required CreateWarehouseUseCase createWarehouse,
    required UpdateWarehouseUseCase updateWarehouse,
    required DeleteWarehouseUseCase deleteWarehouse,
    required SessionQueryCache sessionCache,
  })  : _listWarehouses = listWarehouses,
        _createWarehouse = createWarehouse,
        _updateWarehouse = updateWarehouse,
        _deleteWarehouse = deleteWarehouse,
        _sessionCache = sessionCache,
        super(const WarehousesListState());

  static const int _pageSize = 20;

  final ListWarehousesUseCase _listWarehouses;
  final CreateWarehouseUseCase _createWarehouse;
  final UpdateWarehouseUseCase _updateWarehouse;
  final DeleteWarehouseUseCase _deleteWarehouse;
  final SessionQueryCache _sessionCache;

  String _cacheKey(String search) => 'inventory:warehouses:p1:s=$search';

  Future<void> loadFirstPage({String? search}) async {
    final nextSearch = search ?? state.search;
    final cacheKey = _cacheKey(nextSearch);
    final cached = _sessionCache.get<WarehousePage>(cacheKey);

    if (cached != null) {
      emit(
        WarehousesListState(
          status: WarehousesListStatus.success,
          items: cached.items,
          page: cached.page,
          hasMore: cached.hasMore,
          search: nextSearch,
          isRefreshing: true,
        ),
      );
    } else if (state.items.isNotEmpty) {
      emit(
        state.copyWith(
          search: nextSearch,
          isRefreshing: true,
          message: null,
        ),
      );
    } else {
      emit(
        WarehousesListState(
          status: WarehousesListStatus.loading,
          search: nextSearch,
        ),
      );
    }

    final result = await _listWarehouses(
      page: 1,
      limit: _pageSize,
      search: nextSearch.isEmpty ? null : nextSearch,
    );
    switch (result) {
      case Success(data: final page):
        _sessionCache.set(cacheKey, page);
        emit(
          WarehousesListState(
            status: WarehousesListStatus.success,
            items: page.items,
            page: page.page,
            hasMore: page.hasMore,
            search: nextSearch,
          ),
        );
      case Failure(message: final message):
        if (state.items.isNotEmpty) {
          emit(
            state.copyWith(
              status: WarehousesListStatus.success,
              search: nextSearch,
              isRefreshing: false,
              message: message,
            ),
          );
        } else {
          emit(
            WarehousesListState(
              status: WarehousesListStatus.failure,
              search: nextSearch,
              message: message,
            ),
          );
        }
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore ||
        state.status == WarehousesListStatus.loading ||
        state.status == WarehousesListStatus.loadingMore) {
      return;
    }
    emit(state.copyWith(status: WarehousesListStatus.loadingMore));
    final nextPage = state.page + 1;
    final result = await _listWarehouses(
      page: nextPage,
      limit: _pageSize,
      search: state.search.isEmpty ? null : state.search,
    );
    switch (result) {
      case Success(data: final page):
        emit(
          state.copyWith(
            status: WarehousesListStatus.success,
            items: [...state.items, ...page.items],
            page: page.page,
            hasMore: page.hasMore,
          ),
        );
      case Failure(message: final message):
        emit(
          state.copyWith(
            status: WarehousesListStatus.success,
            message: message,
          ),
        );
    }
  }

  Future<void> search(String value) => loadFirstPage(search: value);

  Future<Result<Warehouse>> create(WarehouseUpsertInput input) {
    return _createWarehouse(input);
  }

  Future<Result<Warehouse>> update(String id, WarehouseUpsertInput input) {
    return _updateWarehouse(id, input);
  }

  Future<Result<Warehouse>> delete(String id) {
    return _deleteWarehouse(id);
  }
}
