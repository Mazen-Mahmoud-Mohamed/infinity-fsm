import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/cache/session_query_cache.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_record.dart';
import 'package:mobile/features/attendance/domain/entities/attendance_status.dart';
import 'package:mobile/features/attendance/domain/usecases/list_admin_attendance_usecase.dart';
import 'package:mobile/features/dashboard/domain/entities/role_dashboard_summary.dart';
import 'package:mobile/features/dashboard/presentation/utils/dashboard_period_range.dart';

enum AttendanceAdminStatus { initial, loading, loadingMore, success, failure }

class AttendanceAdminState extends Equatable {
  const AttendanceAdminState({
    this.status = AttendanceAdminStatus.initial,
    this.items = const [],
    this.page = 1,
    this.hasMore = true,
    this.filterStatus,
    this.filterRole,
    this.search = '',
    this.period = DashboardPeriod.today,
    this.customFrom,
    this.customTo,
    this.message,
    this.isRefreshing = false,
  });

  final AttendanceAdminStatus status;
  final List<AttendanceRecord> items;
  final int page;
  final bool hasMore;
  final AttendanceStatus? filterStatus;
  final String? filterRole;
  final String search;
  final DashboardPeriod period;
  final DateTime? customFrom;
  final DateTime? customTo;
  final String? message;
  final bool isRefreshing;

  AttendanceAdminState copyWith({
    AttendanceAdminStatus? status,
    List<AttendanceRecord>? items,
    int? page,
    bool? hasMore,
    AttendanceStatus? filterStatus,
    bool clearFilterStatus = false,
    String? filterRole,
    bool clearFilterRole = false,
    String? search,
    DashboardPeriod? period,
    DateTime? customFrom,
    DateTime? customTo,
    bool clearCustomRange = false,
    String? message,
    bool? isRefreshing,
  }) {
    return AttendanceAdminState(
      status: status ?? this.status,
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      filterStatus:
          clearFilterStatus ? null : (filterStatus ?? this.filterStatus),
      filterRole: clearFilterRole ? null : (filterRole ?? this.filterRole),
      search: search ?? this.search,
      period: period ?? this.period,
      customFrom: clearCustomRange ? null : (customFrom ?? this.customFrom),
      customTo: clearCustomRange ? null : (customTo ?? this.customTo),
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
        filterRole,
        search,
        period,
        customFrom,
        customTo,
        message,
        isRefreshing,
      ];
}

class _CachedAttendanceAdmin {
  const _CachedAttendanceAdmin({
    required this.items,
    required this.page,
    required this.hasMore,
    required this.filterStatus,
    required this.filterRole,
    required this.search,
    required this.period,
    required this.customFrom,
    required this.customTo,
  });

  final List<AttendanceRecord> items;
  final int page;
  final bool hasMore;
  final AttendanceStatus? filterStatus;
  final String? filterRole;
  final String search;
  final DashboardPeriod period;
  final DateTime? customFrom;
  final DateTime? customTo;
}

class AttendanceAdminCubit extends Cubit<AttendanceAdminState> {
  AttendanceAdminCubit({
    required ListAdminAttendanceUseCase listAdmin,
    required SessionQueryCache sessionQueryCache,
  })  : _listAdmin = listAdmin,
        _sessionQueryCache = sessionQueryCache,
        super(const AttendanceAdminState());

  static const int _pageSize = 20;

  final ListAdminAttendanceUseCase _listAdmin;
  final SessionQueryCache _sessionQueryCache;

  String _cacheKey({
    required AttendanceStatus? status,
    required String? role,
    required String search,
    required DashboardPeriod period,
    required DateTime? customFrom,
    required DateTime? customTo,
  }) {
    final from = customFrom?.toIso8601String().substring(0, 10) ?? '';
    final to = customTo?.toIso8601String().substring(0, 10) ?? '';
    return 'attendance:admin:${status?.name ?? 'all'}:'
        '${role ?? 'all'}:${search.trim()}:${period.name}:$from:$to';
  }

  ({DateTime? startDate, DateTime? endDate}) _dateRange({
    required DashboardPeriod period,
    DateTime? customFrom,
    DateTime? customTo,
  }) {
    final range = DashboardPeriodRange.resolveLocal(
      period: period,
      customFrom: customFrom,
      customTo: customTo,
    );
    return (startDate: range.from, endDate: range.to);
  }

  Future<void> loadFirstPage({
    AttendanceStatus? status,
    bool clearStatus = false,
    String? role,
    bool clearRole = false,
    String? search,
    DashboardPeriod? period,
    DateTime? customFrom,
    DateTime? customTo,
    bool clearCustomRange = false,
  }) async {
    final nextStatus = clearStatus ? null : (status ?? state.filterStatus);
    final nextRole = clearRole ? null : (role ?? state.filterRole);
    final nextSearch = search ?? state.search;
    final nextPeriod = period ?? state.period;
    final nextCustomFrom =
        clearCustomRange ? null : (customFrom ?? state.customFrom);
    final nextCustomTo =
        clearCustomRange ? null : (customTo ?? state.customTo);
    final key = _cacheKey(
      status: nextStatus,
      role: nextRole,
      search: nextSearch,
      period: nextPeriod,
      customFrom: nextCustomFrom,
      customTo: nextCustomTo,
    );
    final cached = _sessionQueryCache.get<_CachedAttendanceAdmin>(key);
    final sameQuery = state.filterStatus == nextStatus &&
        state.filterRole == nextRole &&
        state.search == nextSearch &&
        state.period == nextPeriod &&
        state.customFrom == nextCustomFrom &&
        state.customTo == nextCustomTo &&
        state.items.isNotEmpty;
    final seeded = cached?.items ?? (sameQuery ? state.items : const []);
    final hasData = seeded.isNotEmpty;

    if (hasData) {
      emit(
        state.copyWith(
          status: AttendanceAdminStatus.success,
          items: seeded,
          page: cached?.page ?? state.page,
          hasMore: cached?.hasMore ?? state.hasMore,
          filterStatus: nextStatus,
          clearFilterStatus: nextStatus == null,
          filterRole: nextRole,
          clearFilterRole: nextRole == null,
          search: nextSearch,
          period: nextPeriod,
          customFrom: nextCustomFrom,
          customTo: nextCustomTo,
          clearCustomRange: clearCustomRange,
          isRefreshing: true,
        ),
      );
    } else {
      emit(
        AttendanceAdminState(
          status: AttendanceAdminStatus.loading,
          filterStatus: nextStatus,
          filterRole: nextRole,
          search: nextSearch,
          period: nextPeriod,
          customFrom: nextCustomFrom,
          customTo: nextCustomTo,
          isRefreshing: false,
        ),
      );
    }

    final dates = _dateRange(
      period: nextPeriod,
      customFrom: nextCustomFrom,
      customTo: nextCustomTo,
    );

    final result = await _listAdmin(
      page: 1,
      limit: _pageSize,
      status: nextStatus,
      search: nextSearch,
      startDate: dates.startDate,
      endDate: dates.endDate,
      role: nextRole,
    );

    switch (result) {
      case Success(data: final page):
        final next = _CachedAttendanceAdmin(
          items: page.items,
          page: page.page,
          hasMore: page.hasMore,
          filterStatus: nextStatus,
          filterRole: nextRole,
          search: nextSearch,
          period: nextPeriod,
          customFrom: nextCustomFrom,
          customTo: nextCustomTo,
        );
        _sessionQueryCache.set(key, next);
        emit(
          AttendanceAdminState(
            status: AttendanceAdminStatus.success,
            items: page.items,
            page: page.page,
            hasMore: page.hasMore,
            filterStatus: nextStatus,
            filterRole: nextRole,
            search: nextSearch,
            period: nextPeriod,
            customFrom: nextCustomFrom,
            customTo: nextCustomTo,
            isRefreshing: false,
          ),
        );
      case Failure(message: final message):
        emit(
          AttendanceAdminState(
            status: hasData
                ? AttendanceAdminStatus.success
                : AttendanceAdminStatus.failure,
            items: hasData ? seeded : const [],
            page: hasData ? (cached?.page ?? 1) : 1,
            hasMore: hasData ? (cached?.hasMore ?? true) : true,
            filterStatus: nextStatus,
            filterRole: nextRole,
            search: nextSearch,
            period: nextPeriod,
            customFrom: nextCustomFrom,
            customTo: nextCustomTo,
            message: message,
            isRefreshing: false,
          ),
        );
    }
  }

  Future<void> setFilter(AttendanceStatus? status) {
    return loadFirstPage(status: status, clearStatus: status == null);
  }

  Future<void> setRole(String? role) {
    return loadFirstPage(role: role, clearRole: role == null);
  }

  Future<void> setPeriod(DashboardPeriod period) {
    return loadFirstPage(
      period: period,
      clearCustomRange: period != DashboardPeriod.custom,
    );
  }

  Future<void> setCustomRange(DateTime from, DateTime to) {
    return loadFirstPage(
      period: DashboardPeriod.custom,
      customFrom: from,
      customTo: to,
    );
  }

  Future<void> search(String query) {
    return loadFirstPage(search: query);
  }

  Future<void> loadMore() async {
    if (state.status == AttendanceAdminStatus.loadingMore || !state.hasMore) {
      return;
    }

    emit(state.copyWith(status: AttendanceAdminStatus.loadingMore));

    final nextPage = state.page + 1;
    final dates = _dateRange(
      period: state.period,
      customFrom: state.customFrom,
      customTo: state.customTo,
    );
    final result = await _listAdmin(
      page: nextPage,
      limit: _pageSize,
      status: state.filterStatus,
      search: state.search,
      startDate: dates.startDate,
      endDate: dates.endDate,
      role: state.filterRole,
    );

    switch (result) {
      case Success(data: final page):
        emit(
          state.copyWith(
            status: AttendanceAdminStatus.success,
            items: [...state.items, ...page.items],
            page: page.page,
            hasMore: page.hasMore,
          ),
        );
      case Failure(message: final message):
        emit(
          state.copyWith(
            status: AttendanceAdminStatus.success,
            message: message,
          ),
        );
    }
  }
}
