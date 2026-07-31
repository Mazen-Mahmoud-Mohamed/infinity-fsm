import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/cache/session_query_cache.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/pm/domain/entities/pm_entities.dart';
import 'package:mobile/features/pm/domain/usecases/pm_usecases.dart';

enum PmSchedulesStatus { initial, loading, loadingMore, success, failure }

class PmSchedulesState extends Equatable {
  const PmSchedulesState({
    this.status = PmSchedulesStatus.initial,
    this.items = const [],
    this.page = 1,
    this.hasMore = true,
    this.search = '',
    this.filterStatus,
    this.planId,
    this.message,
    this.isRefreshing = false,
  });

  final PmSchedulesStatus status;
  final List<MaintenanceSchedule> items;
  final int page;
  final bool hasMore;
  final String search;
  final PmScheduleStatus? filterStatus;
  final String? planId;
  final String? message;
  final bool isRefreshing;

  PmSchedulesState copyWith({
    PmSchedulesStatus? status,
    List<MaintenanceSchedule>? items,
    int? page,
    bool? hasMore,
    String? search,
    PmScheduleStatus? filterStatus,
    bool clearFilterStatus = false,
    String? planId,
    bool clearPlanId = false,
    String? message,
    bool? isRefreshing,
  }) {
    return PmSchedulesState(
      status: status ?? this.status,
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      search: search ?? this.search,
      filterStatus:
          clearFilterStatus ? null : (filterStatus ?? this.filterStatus),
      planId: clearPlanId ? null : (planId ?? this.planId),
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
        planId,
        message,
        isRefreshing,
      ];
}

class PmSchedulesCubit extends Cubit<PmSchedulesState> {
  PmSchedulesCubit({
    required ListPmSchedulesUseCase listSchedules,
    required CompletePmScheduleUseCase completeSchedule,
    required CancelPmScheduleUseCase cancelSchedule,
    required SessionQueryCache queryCache,
    String? planId,
    PmScheduleStatus? initialStatus,
  })  : _listSchedules = listSchedules,
        _completeSchedule = completeSchedule,
        _cancelSchedule = cancelSchedule,
        _queryCache = queryCache,
        super(PmSchedulesState(
          planId: planId,
          filterStatus: initialStatus,
        ));

  static const int _pageSize = 20;
  final ListPmSchedulesUseCase _listSchedules;
  final CompletePmScheduleUseCase _completeSchedule;
  final CancelPmScheduleUseCase _cancelSchedule;
  final SessionQueryCache _queryCache;

  String _cacheKey({
    required String search,
    PmScheduleStatus? status,
    String? planId,
  }) {
    return 'pm:schedules:p1:plan=${planId ?? ''}:s=$search'
        ':st=${status?.apiValue ?? ''}';
  }

  Future<void> loadFirstPage({
    String? search,
    PmScheduleStatus? status,
    bool clearStatus = false,
  }) async {
    final nextSearch = search ?? state.search;
    final nextStatus = clearStatus ? null : (status ?? state.filterStatus);
    final planId = state.planId;
    final key = _cacheKey(
      search: nextSearch,
      status: nextStatus,
      planId: planId,
    );
    final cached = _queryCache.get<MaintenanceSchedulePage>(key);

    if (cached != null) {
      emit(PmSchedulesState(
        status: PmSchedulesStatus.success,
        items: cached.items,
        page: cached.page,
        hasMore: cached.hasMore,
        search: nextSearch,
        filterStatus: nextStatus,
        planId: planId,
        isRefreshing: true,
      ));
    } else if (state.items.isNotEmpty) {
      emit(state.copyWith(
        status: PmSchedulesStatus.success,
        search: nextSearch,
        filterStatus: nextStatus,
        clearFilterStatus: nextStatus == null,
        isRefreshing: true,
      ));
    } else {
      emit(PmSchedulesState(
        status: PmSchedulesStatus.loading,
        search: nextSearch,
        filterStatus: nextStatus,
        planId: planId,
      ));
    }

    final result = await _listSchedules(
      page: 1,
      limit: _pageSize,
      search: nextSearch.isEmpty ? null : nextSearch,
      status: nextStatus,
      planId: planId,
    );

    switch (result) {
      case Success(data: final page):
        _queryCache.set(key, page);
        emit(PmSchedulesState(
          status: PmSchedulesStatus.success,
          items: page.items,
          page: page.page,
          hasMore: page.hasMore,
          search: nextSearch,
          filterStatus: nextStatus,
          planId: planId,
        ));
      case Failure(message: final message):
        if (state.items.isNotEmpty) {
          emit(state.copyWith(
            status: PmSchedulesStatus.success,
            search: nextSearch,
            filterStatus: nextStatus,
            clearFilterStatus: nextStatus == null,
            message: message,
            isRefreshing: false,
          ));
        } else {
          emit(PmSchedulesState(
            status: PmSchedulesStatus.failure,
            search: nextSearch,
            filterStatus: nextStatus,
            planId: planId,
            message: message,
          ));
        }
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore ||
        state.status == PmSchedulesStatus.loading ||
        state.status == PmSchedulesStatus.loadingMore ||
        state.isRefreshing) {
      return;
    }
    emit(state.copyWith(status: PmSchedulesStatus.loadingMore));
    final result = await _listSchedules(
      page: state.page + 1,
      limit: _pageSize,
      search: state.search.isEmpty ? null : state.search,
      status: state.filterStatus,
      planId: state.planId,
    );
    switch (result) {
      case Success(data: final page):
        emit(state.copyWith(
          status: PmSchedulesStatus.success,
          items: [...state.items, ...page.items],
          page: page.page,
          hasMore: page.hasMore,
        ));
      case Failure(message: final message):
        emit(state.copyWith(
          status: PmSchedulesStatus.success,
          message: message,
        ));
    }
  }

  Future<void> setFilter(PmScheduleStatus? status) =>
      loadFirstPage(status: status, clearStatus: status == null);

  Future<void> search(String value) => loadFirstPage(search: value);

  Future<Result<MaintenanceSchedule>> complete(
    String id, {
    String? notes,
  }) async {
    final result = await _completeSchedule(id, notes: notes);
    if (result is Success<MaintenanceSchedule>) {
      _queryCache.invalidatePrefix('pm:schedules:');
      _queryCache.invalidatePrefix('pm:history:');
      _queryCache.invalidate('pm:dashboard');
      await loadFirstPage();
    }
    return result;
  }

  Future<Result<MaintenanceSchedule>> cancel(
    String id, {
    String? notes,
  }) async {
    final result = await _cancelSchedule(id, notes: notes);
    if (result is Success<MaintenanceSchedule>) {
      _queryCache.invalidatePrefix('pm:schedules:');
      _queryCache.invalidatePrefix('pm:history:');
      _queryCache.invalidate('pm:dashboard');
      await loadFirstPage();
    }
    return result;
  }
}

enum PmHistoryStatus { initial, loading, loadingMore, success, failure }

class PmHistoryState extends Equatable {
  const PmHistoryState({
    this.status = PmHistoryStatus.initial,
    this.items = const [],
    this.page = 1,
    this.hasMore = true,
    this.search = '',
    this.planId,
    this.message,
    this.isRefreshing = false,
  });

  final PmHistoryStatus status;
  final List<MaintenanceSchedule> items;
  final int page;
  final bool hasMore;
  final String search;
  final String? planId;
  final String? message;
  final bool isRefreshing;

  PmHistoryState copyWith({
    PmHistoryStatus? status,
    List<MaintenanceSchedule>? items,
    int? page,
    bool? hasMore,
    String? search,
    String? planId,
    String? message,
    bool? isRefreshing,
  }) {
    return PmHistoryState(
      status: status ?? this.status,
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      search: search ?? this.search,
      planId: planId ?? this.planId,
      message: message,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props =>
      [status, items, page, hasMore, search, planId, message, isRefreshing];
}

class PmHistoryCubit extends Cubit<PmHistoryState> {
  PmHistoryCubit({
    required ListPmHistoryUseCase listHistory,
    required SessionQueryCache queryCache,
    String? planId,
  })  : _listHistory = listHistory,
        _queryCache = queryCache,
        super(PmHistoryState(planId: planId));

  static const int _pageSize = 20;
  final ListPmHistoryUseCase _listHistory;
  final SessionQueryCache _queryCache;

  String _cacheKey({required String search, String? planId}) =>
      'pm:history:p1:plan=${planId ?? ''}:s=$search';

  Future<void> loadFirstPage({String? search}) async {
    final nextSearch = search ?? state.search;
    final planId = state.planId;
    final key = _cacheKey(search: nextSearch, planId: planId);
    final cached = _queryCache.get<MaintenanceSchedulePage>(key);

    if (cached != null) {
      emit(PmHistoryState(
        status: PmHistoryStatus.success,
        items: cached.items,
        page: cached.page,
        hasMore: cached.hasMore,
        search: nextSearch,
        planId: planId,
        isRefreshing: true,
      ));
    } else if (state.items.isNotEmpty) {
      emit(state.copyWith(
        status: PmHistoryStatus.success,
        search: nextSearch,
        isRefreshing: true,
      ));
    } else {
      emit(PmHistoryState(
        status: PmHistoryStatus.loading,
        search: nextSearch,
        planId: planId,
      ));
    }

    final result = await _listHistory(
      page: 1,
      limit: _pageSize,
      search: nextSearch.isEmpty ? null : nextSearch,
      planId: planId,
    );
    switch (result) {
      case Success(data: final page):
        _queryCache.set(key, page);
        emit(PmHistoryState(
          status: PmHistoryStatus.success,
          items: page.items,
          page: page.page,
          hasMore: page.hasMore,
          search: nextSearch,
          planId: planId,
        ));
      case Failure(message: final message):
        if (state.items.isNotEmpty) {
          emit(state.copyWith(
            status: PmHistoryStatus.success,
            search: nextSearch,
            message: message,
            isRefreshing: false,
          ));
        } else {
          emit(PmHistoryState(
            status: PmHistoryStatus.failure,
            search: nextSearch,
            planId: planId,
            message: message,
          ));
        }
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore ||
        state.status == PmHistoryStatus.loading ||
        state.status == PmHistoryStatus.loadingMore ||
        state.isRefreshing) {
      return;
    }
    emit(state.copyWith(status: PmHistoryStatus.loadingMore));
    final result = await _listHistory(
      page: state.page + 1,
      limit: _pageSize,
      search: state.search.isEmpty ? null : state.search,
      planId: state.planId,
    );
    switch (result) {
      case Success(data: final page):
        emit(state.copyWith(
          status: PmHistoryStatus.success,
          items: [...state.items, ...page.items],
          page: page.page,
          hasMore: page.hasMore,
        ));
      case Failure(message: final message):
        emit(state.copyWith(
          status: PmHistoryStatus.success,
          message: message,
        ));
    }
  }

  Future<void> search(String value) => loadFirstPage(search: value);
}
