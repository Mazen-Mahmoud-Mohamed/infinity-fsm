import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/cache/session_query_cache.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_status.dart';
import 'package:mobile/features/overtime/domain/usecases/list_admin_overtime_usecase.dart';

enum OvertimeAdminStatus { initial, loading, loadingMore, success, failure }

class OvertimeAdminState extends Equatable {
  const OvertimeAdminState({
    this.status = OvertimeAdminStatus.initial,
    this.items = const [],
    this.page = 1,
    this.hasMore = true,
    this.filterStatus,
    this.search = '',
    this.message,
    this.isRefreshing = false,
  });

  final OvertimeAdminStatus status;
  final List<OvertimeSession> items;
  final int page;
  final bool hasMore;
  final OvertimeStatus? filterStatus;
  final String search;
  final String? message;
  final bool isRefreshing;

  OvertimeAdminState copyWith({
    OvertimeAdminStatus? status,
    List<OvertimeSession>? items,
    int? page,
    bool? hasMore,
    OvertimeStatus? filterStatus,
    bool clearFilterStatus = false,
    String? search,
    String? message,
    bool? isRefreshing,
  }) {
    return OvertimeAdminState(
      status: status ?? this.status,
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      filterStatus:
          clearFilterStatus ? null : (filterStatus ?? this.filterStatus),
      search: search ?? this.search,
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
        message,
        isRefreshing,
      ];
}

class _CachedOvertimeAdmin {
  const _CachedOvertimeAdmin({
    required this.items,
    required this.page,
    required this.hasMore,
    required this.filterStatus,
    required this.search,
  });

  final List<OvertimeSession> items;
  final int page;
  final bool hasMore;
  final OvertimeStatus? filterStatus;
  final String search;
}

class OvertimeAdminCubit extends Cubit<OvertimeAdminState> {
  OvertimeAdminCubit({
    required ListAdminOvertimeUseCase listAdmin,
    required SessionQueryCache sessionQueryCache,
  })  : _listAdmin = listAdmin,
        _sessionQueryCache = sessionQueryCache,
        super(const OvertimeAdminState());

  static const int _pageSize = 20;

  final ListAdminOvertimeUseCase _listAdmin;
  final SessionQueryCache _sessionQueryCache;

  String _cacheKey(OvertimeStatus? status, String search) {
    return 'overtime:admin:${status?.name ?? 'all'}:${search.trim()}';
  }

  Future<void> loadFirstPage({
    OvertimeStatus? status,
    bool clearStatus = false,
    String? search,
  }) async {
    final nextStatus = clearStatus ? null : (status ?? state.filterStatus);
    final nextSearch = search ?? state.search;
    final key = _cacheKey(nextStatus, nextSearch);
    final cached = _sessionQueryCache.get<_CachedOvertimeAdmin>(key);
    final sameQuery = state.filterStatus == nextStatus &&
        state.search == nextSearch &&
        state.items.isNotEmpty;
    final seeded = cached?.items ?? (sameQuery ? state.items : const []);
    final hasData = seeded.isNotEmpty;

    if (hasData) {
      emit(
        state.copyWith(
          status: OvertimeAdminStatus.success,
          items: seeded,
          page: cached?.page ?? state.page,
          hasMore: cached?.hasMore ?? state.hasMore,
          filterStatus: nextStatus,
          clearFilterStatus: nextStatus == null,
          search: nextSearch,
          isRefreshing: true,
        ),
      );
    } else {
      emit(
        OvertimeAdminState(
          status: OvertimeAdminStatus.loading,
          filterStatus: nextStatus,
          search: nextSearch,
          isRefreshing: false,
        ),
      );
    }

    final result = await _listAdmin(
      page: 1,
      limit: _pageSize,
      status: nextStatus,
      search: nextSearch,
    );

    switch (result) {
      case Success(data: final page):
        final next = _CachedOvertimeAdmin(
          items: page.items,
          page: page.page,
          hasMore: page.hasMore,
          filterStatus: nextStatus,
          search: nextSearch,
        );
        _sessionQueryCache.set(key, next);
        emit(
          OvertimeAdminState(
            status: OvertimeAdminStatus.success,
            items: page.items,
            page: page.page,
            hasMore: page.hasMore,
            filterStatus: nextStatus,
            search: nextSearch,
            isRefreshing: false,
          ),
        );
      case Failure(message: final message):
        emit(
          OvertimeAdminState(
            status: hasData
                ? OvertimeAdminStatus.success
                : OvertimeAdminStatus.failure,
            items: hasData ? seeded : const [],
            page: hasData ? (cached?.page ?? 1) : 1,
            hasMore: hasData ? (cached?.hasMore ?? true) : true,
            filterStatus: nextStatus,
            search: nextSearch,
            message: message,
            isRefreshing: false,
          ),
        );
    }
  }

  Future<void> setFilter(OvertimeStatus? status) {
    return loadFirstPage(status: status, clearStatus: status == null);
  }

  Future<void> search(String query) {
    return loadFirstPage(search: query);
  }

  Future<void> loadMore() async {
    if (state.status == OvertimeAdminStatus.loadingMore || !state.hasMore) {
      return;
    }

    emit(state.copyWith(status: OvertimeAdminStatus.loadingMore));

    final nextPage = state.page + 1;
    final result = await _listAdmin(
      page: nextPage,
      limit: _pageSize,
      status: state.filterStatus,
      search: state.search,
    );

    switch (result) {
      case Success(data: final page):
        emit(
          state.copyWith(
            status: OvertimeAdminStatus.success,
            items: [...state.items, ...page.items],
            page: page.page,
            hasMore: page.hasMore,
          ),
        );
      case Failure(message: final message):
        emit(
          state.copyWith(
            status: OvertimeAdminStatus.success,
            message: message,
          ),
        );
    }
  }
}
