import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/cache/session_query_cache.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order_status.dart';
import 'package:mobile/features/work_orders/domain/usecases/list_my_work_orders_usecase.dart';
import 'package:mobile/features/work_orders/domain/usecases/list_work_orders_usecase.dart';

enum WorkOrdersListStatus { initial, loading, loadingMore, success, failure }

class WorkOrdersListState extends Equatable {
  const WorkOrdersListState({
    this.status = WorkOrdersListStatus.initial,
    this.items = const [],
    this.page = 1,
    this.hasMore = true,
    this.filterStatus,
    this.search = '',
    this.isAdminMode = false,
    this.message,
    this.isRefreshing = false,
  });

  final WorkOrdersListStatus status;
  final List<WorkOrder> items;
  final int page;
  final bool hasMore;
  final WorkOrderStatus? filterStatus;
  final String search;
  final bool isAdminMode;
  final String? message;
  final bool isRefreshing;

  WorkOrdersListState copyWith({
    WorkOrdersListStatus? status,
    List<WorkOrder>? items,
    int? page,
    bool? hasMore,
    WorkOrderStatus? filterStatus,
    bool clearFilterStatus = false,
    String? search,
    bool? isAdminMode,
    String? message,
    bool? isRefreshing,
  }) {
    return WorkOrdersListState(
      status: status ?? this.status,
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      filterStatus:
          clearFilterStatus ? null : (filterStatus ?? this.filterStatus),
      search: search ?? this.search,
      isAdminMode: isAdminMode ?? this.isAdminMode,
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
        filterStatus,
        search,
        isAdminMode,
        message,
        isRefreshing,
      ];
}

class WorkOrdersListCubit extends Cubit<WorkOrdersListState> {
  WorkOrdersListCubit({
    required ListWorkOrdersUseCase listWorkOrders,
    required ListMyWorkOrdersUseCase listMyWorkOrders,
    required SessionQueryCache sessionQueryCache,
  })  : _listWorkOrders = listWorkOrders,
        _listMyWorkOrders = listMyWorkOrders,
        _sessionQueryCache = sessionQueryCache,
        super(const WorkOrdersListState());

  static const int _pageSize = 20;

  final ListWorkOrdersUseCase _listWorkOrders;
  final ListMyWorkOrdersUseCase _listMyWorkOrders;
  final SessionQueryCache _sessionQueryCache;

  String _cacheKey({
    required bool isAdminMode,
    WorkOrderStatus? status,
    required String search,
  }) =>
      'work_orders:admin=$isAdminMode:status=${status?.name ?? ''}:search=$search';

  Future<void> loadFirstPage({
    required bool isAdminMode,
    WorkOrderStatus? status,
    bool clearStatus = false,
    String? search,
  }) async {
    final nextStatus = clearStatus ? null : (status ?? state.filterStatus);
    final nextSearch = search ?? state.search;
    final cacheKey = _cacheKey(
      isAdminMode: isAdminMode,
      status: nextStatus,
      search: nextSearch,
    );
    final cached = _sessionQueryCache.get<WorkOrderPage>(cacheKey);

    if (cached != null) {
      emit(
        WorkOrdersListState(
          status: WorkOrdersListStatus.success,
          items: cached.items,
          page: cached.page,
          hasMore: cached.hasMore,
          filterStatus: nextStatus,
          search: nextSearch,
          isAdminMode: isAdminMode,
          isRefreshing: true,
        ),
      );
    } else if (state.items.isNotEmpty) {
      emit(
        state.copyWith(
          isRefreshing: true,
          filterStatus: nextStatus,
          clearFilterStatus: nextStatus == null,
          search: nextSearch,
          isAdminMode: isAdminMode,
          message: null,
        ),
      );
    } else {
      emit(
        WorkOrdersListState(
          status: WorkOrdersListStatus.loading,
          filterStatus: nextStatus,
          search: nextSearch,
          isAdminMode: isAdminMode,
        ),
      );
    }

    final result = await _fetch(
      isAdminMode: isAdminMode,
      page: 1,
      status: nextStatus,
      search: nextSearch,
    );

    switch (result) {
      case Success(data: final page):
        _sessionQueryCache.set(cacheKey, page);
        emit(
          WorkOrdersListState(
            status: WorkOrdersListStatus.success,
            items: page.items,
            page: page.page,
            hasMore: page.hasMore,
            filterStatus: nextStatus,
            search: nextSearch,
            isAdminMode: isAdminMode,
            isRefreshing: false,
          ),
        );
      case Failure(message: final message):
        if (state.items.isNotEmpty) {
          emit(
            state.copyWith(
              status: WorkOrdersListStatus.success,
              isRefreshing: false,
              message: message,
            ),
          );
        } else {
          emit(
            WorkOrdersListState(
              status: WorkOrdersListStatus.failure,
              filterStatus: nextStatus,
              search: nextSearch,
              isAdminMode: isAdminMode,
              message: message,
              isRefreshing: false,
            ),
          );
        }
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore ||
        state.status == WorkOrdersListStatus.loading ||
        state.status == WorkOrdersListStatus.loadingMore ||
        state.isRefreshing) {
      return;
    }

    emit(state.copyWith(status: WorkOrdersListStatus.loadingMore));

    final nextPage = state.page + 1;
    final result = await _fetch(
      isAdminMode: state.isAdminMode,
      page: nextPage,
      status: state.filterStatus,
      search: state.search,
    );

    switch (result) {
      case Success(data: final page):
        emit(
          state.copyWith(
            status: WorkOrdersListStatus.success,
            items: [...state.items, ...page.items],
            page: page.page,
            hasMore: page.hasMore,
          ),
        );
      case Failure(message: final message):
        emit(
          state.copyWith(
            status: WorkOrdersListStatus.success,
            message: message,
          ),
        );
    }
  }

  Future<void> setFilter(WorkOrderStatus? status) {
    return loadFirstPage(
      isAdminMode: state.isAdminMode,
      status: status,
      clearStatus: status == null,
    );
  }

  Future<void> search(String value) {
    return loadFirstPage(
      isAdminMode: state.isAdminMode,
      search: value.trim(),
    );
  }

  Future<void> refresh() {
    return loadFirstPage(
      isAdminMode: state.isAdminMode,
      status: state.filterStatus,
      search: state.search,
    );
  }

  Future<Result<WorkOrderPage>> _fetch({
    required bool isAdminMode,
    required int page,
    WorkOrderStatus? status,
    String? search,
  }) {
    if (isAdminMode) {
      return _listWorkOrders(
        page: page,
        limit: _pageSize,
        status: status,
        search: search,
      );
    }
    return _listMyWorkOrders(
      page: page,
      limit: _pageSize,
      status: status,
      search: search,
    );
  }
}
