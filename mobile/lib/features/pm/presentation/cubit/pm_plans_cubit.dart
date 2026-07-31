import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/cache/session_query_cache.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/pm/domain/entities/pm_entities.dart';
import 'package:mobile/features/pm/domain/usecases/pm_usecases.dart';

enum PmPlansStatus { initial, loading, loadingMore, success, failure }

class PmPlansState extends Equatable {
  const PmPlansState({
    this.status = PmPlansStatus.initial,
    this.items = const [],
    this.page = 1,
    this.hasMore = true,
    this.search = '',
    this.filterStatus,
    this.filterFrequency,
    this.filterPriority,
    this.message,
    this.isRefreshing = false,
  });

  final PmPlansStatus status;
  final List<MaintenancePlan> items;
  final int page;
  final bool hasMore;
  final String search;
  final PmPlanStatus? filterStatus;
  final PmFrequency? filterFrequency;
  final PmPriority? filterPriority;
  final String? message;
  final bool isRefreshing;

  PmPlansState copyWith({
    PmPlansStatus? status,
    List<MaintenancePlan>? items,
    int? page,
    bool? hasMore,
    String? search,
    PmPlanStatus? filterStatus,
    bool clearFilterStatus = false,
    PmFrequency? filterFrequency,
    bool clearFilterFrequency = false,
    PmPriority? filterPriority,
    bool clearFilterPriority = false,
    String? message,
    bool? isRefreshing,
  }) {
    return PmPlansState(
      status: status ?? this.status,
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      search: search ?? this.search,
      filterStatus:
          clearFilterStatus ? null : (filterStatus ?? this.filterStatus),
      filterFrequency: clearFilterFrequency
          ? null
          : (filterFrequency ?? this.filterFrequency),
      filterPriority: clearFilterPriority
          ? null
          : (filterPriority ?? this.filterPriority),
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
        filterFrequency,
        filterPriority,
        message,
        isRefreshing,
      ];
}

class PmPlansCubit extends Cubit<PmPlansState> {
  PmPlansCubit({
    required ListPmPlansUseCase listPlans,
    required SessionQueryCache queryCache,
  })  : _listPlans = listPlans,
        _queryCache = queryCache,
        super(const PmPlansState());

  static const int _pageSize = 20;
  final ListPmPlansUseCase _listPlans;
  final SessionQueryCache _queryCache;

  String _cacheKey({
    required String search,
    PmPlanStatus? status,
    PmFrequency? frequency,
    PmPriority? priority,
  }) {
    return 'pm:plans:p1:s=$search:st=${status?.apiValue ?? ''}'
        ':f=${frequency?.apiValue ?? ''}:pr=${priority?.apiValue ?? ''}';
  }

  Future<void> loadFirstPage({
    String? search,
    PmPlanStatus? status,
    bool clearStatus = false,
    PmFrequency? frequency,
    bool clearFrequency = false,
    PmPriority? priority,
    bool clearPriority = false,
  }) async {
    final nextSearch = search ?? state.search;
    final nextStatus = clearStatus ? null : (status ?? state.filterStatus);
    final nextFrequency =
        clearFrequency ? null : (frequency ?? state.filterFrequency);
    final nextPriority =
        clearPriority ? null : (priority ?? state.filterPriority);

    final key = _cacheKey(
      search: nextSearch,
      status: nextStatus,
      frequency: nextFrequency,
      priority: nextPriority,
    );
    final cached = _queryCache.get<MaintenancePlanPage>(key);

    if (cached != null) {
      emit(PmPlansState(
        status: PmPlansStatus.success,
        items: cached.items,
        page: cached.page,
        hasMore: cached.hasMore,
        search: nextSearch,
        filterStatus: nextStatus,
        filterFrequency: nextFrequency,
        filterPriority: nextPriority,
        isRefreshing: true,
      ));
    } else if (state.items.isNotEmpty) {
      emit(state.copyWith(
        status: PmPlansStatus.success,
        search: nextSearch,
        filterStatus: nextStatus,
        clearFilterStatus: nextStatus == null,
        filterFrequency: nextFrequency,
        clearFilterFrequency: nextFrequency == null,
        filterPriority: nextPriority,
        clearFilterPriority: nextPriority == null,
        isRefreshing: true,
      ));
    } else {
      emit(PmPlansState(
        status: PmPlansStatus.loading,
        search: nextSearch,
        filterStatus: nextStatus,
        filterFrequency: nextFrequency,
        filterPriority: nextPriority,
      ));
    }

    final result = await _listPlans(
      page: 1,
      limit: _pageSize,
      search: nextSearch.isEmpty ? null : nextSearch,
      status: nextStatus,
      frequency: nextFrequency,
      priority: nextPriority,
    );

    switch (result) {
      case Success(data: final page):
        _queryCache.set(key, page);
        emit(PmPlansState(
          status: PmPlansStatus.success,
          items: page.items,
          page: page.page,
          hasMore: page.hasMore,
          search: nextSearch,
          filterStatus: nextStatus,
          filterFrequency: nextFrequency,
          filterPriority: nextPriority,
        ));
      case Failure(message: final message):
        if (state.items.isNotEmpty) {
          emit(state.copyWith(
            status: PmPlansStatus.success,
            search: nextSearch,
            filterStatus: nextStatus,
            clearFilterStatus: nextStatus == null,
            filterFrequency: nextFrequency,
            clearFilterFrequency: nextFrequency == null,
            filterPriority: nextPriority,
            clearFilterPriority: nextPriority == null,
            message: message,
            isRefreshing: false,
          ));
        } else {
          emit(PmPlansState(
            status: PmPlansStatus.failure,
            search: nextSearch,
            filterStatus: nextStatus,
            filterFrequency: nextFrequency,
            filterPriority: nextPriority,
            message: message,
          ));
        }
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore ||
        state.status == PmPlansStatus.loading ||
        state.status == PmPlansStatus.loadingMore ||
        state.isRefreshing) {
      return;
    }
    emit(state.copyWith(status: PmPlansStatus.loadingMore));
    final result = await _listPlans(
      page: state.page + 1,
      limit: _pageSize,
      search: state.search.isEmpty ? null : state.search,
      status: state.filterStatus,
      frequency: state.filterFrequency,
      priority: state.filterPriority,
    );
    switch (result) {
      case Success(data: final page):
        emit(state.copyWith(
          status: PmPlansStatus.success,
          items: [...state.items, ...page.items],
          page: page.page,
          hasMore: page.hasMore,
        ));
      case Failure(message: final message):
        emit(state.copyWith(
          status: PmPlansStatus.success,
          message: message,
        ));
    }
  }

  Future<void> setStatusFilter(PmPlanStatus? status) =>
      loadFirstPage(status: status, clearStatus: status == null);

  Future<void> setFrequencyFilter(PmFrequency? frequency) => loadFirstPage(
        frequency: frequency,
        clearFrequency: frequency == null,
      );

  Future<void> setPriorityFilter(PmPriority? priority) => loadFirstPage(
        priority: priority,
        clearPriority: priority == null,
      );

  Future<void> search(String value) => loadFirstPage(search: value);
}
