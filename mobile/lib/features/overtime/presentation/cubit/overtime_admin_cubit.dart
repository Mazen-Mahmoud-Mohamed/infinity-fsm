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
    this.changeToken = 0,
  });

  final OvertimeAdminStatus status;
  final List<OvertimeSession> items;
  final int page;
  final bool hasMore;
  final OvertimeStatus? filterStatus;
  final String search;
  final String? message;
  final bool isRefreshing;
  final int changeToken;

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
    int? changeToken,
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
      changeToken: changeToken ?? this.changeToken,
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
        changeToken,
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
  int _loadFirstPageToken = 0;

  String _cacheKey(OvertimeStatus? status, String search) {
    return 'overtime:admin:${status?.name ?? 'all'}:${search.trim()}';
  }

  bool _isLatestLoadFirstPage(int token) =>
      !isClosed && token == _loadFirstPageToken;

  Future<void> loadFirstPage({
    OvertimeStatus? status,
    bool clearStatus = false,
    String? search,
  }) async {
    final token = ++_loadFirstPageToken;
    final nextStatus = clearStatus ? null : (status ?? state.filterStatus);
    final nextSearch = search ?? state.search;
    final key = _cacheKey(nextStatus, nextSearch);
    final cached = _sessionQueryCache.get<_CachedOvertimeAdmin>(key);
    final sameQuery = state.filterStatus == nextStatus &&
        state.search == nextSearch &&
        state.items.isNotEmpty;
    final seeded = _overlayMutations(
      cached?.items ?? (sameQuery ? state.items : const []),
      consumeIfMatched: false,
    );
    final hasData = seeded.isNotEmpty;

    if (!_isLatestLoadFirstPage(token)) return;

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

    if (!_isLatestLoadFirstPage(token)) return;

    switch (result) {
      case Success(data: final page):
        final items = _overlayMutations(page.items, consumeIfMatched: true);
        final next = _CachedOvertimeAdmin(
          items: items,
          page: page.page,
          hasMore: page.hasMore,
          filterStatus: nextStatus,
          search: nextSearch,
        );
        _sessionQueryCache.set(key, next);
        emit(
          OvertimeAdminState(
            status: OvertimeAdminStatus.success,
            items: items,
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

  static const _mutationOverlayKey = 'overtime:admin:mutation-overlay';

  /// Replaces a loaded list item with the authoritative mutation result.
  ///
  /// Does not insert missing ids, reload pages, or change pagination.
  void applyUpdated(OvertimeSession session) {
    if (session.id.isEmpty) return;
    syncReviewedSession(_sessionQueryCache, session);

    final index = state.items.indexWhere((item) => item.id == session.id);
    if (index < 0) return;
    if (isClosed) return;

    final next = [...state.items];
    next[index] = session;
    emit(
      state.copyWith(
        status: state.status == OvertimeAdminStatus.initial
            ? OvertimeAdminStatus.success
            : state.status,
        items: next,
        changeToken: state.changeToken + 1,
      ),
    );
  }

  /// Persists a review result so a remounted list cubit seeds the new status.
  static void syncReviewedSession(
    SessionQueryCache cache,
    OvertimeSession session,
  ) {
    if (session.id.isEmpty) return;
    final overlay = _readOverlay(cache);
    overlay[session.id] = session;
    _writeOverlay(cache, overlay);
    cache.updatePrefix<_CachedOvertimeAdmin>('overtime:admin:', (cached) {
      final index = cached.items.indexWhere((item) => item.id == session.id);
      if (index < 0) return cached;
      final items = [...cached.items];
      items[index] = session;
      return _CachedOvertimeAdmin(
        items: items,
        page: cached.page,
        hasMore: cached.hasMore,
        filterStatus: cached.filterStatus,
        search: cached.search,
      );
    });
  }

  List<OvertimeSession> _overlayMutations(
    List<OvertimeSession> items, {
    bool consumeIfMatched = true,
  }) {
    final overlay = _readOverlay(_sessionQueryCache);
    if (overlay.isEmpty) return items;
    var changed = false;
    final next = <OvertimeSession>[];
    for (final item in items) {
      final reviewed = overlay[item.id];
      if (reviewed == null) {
        next.add(item);
        continue;
      }
      if (_sameReviewState(reviewed, item)) {
        if (consumeIfMatched) {
          overlay.remove(item.id);
          changed = true;
        }
        next.add(item);
        continue;
      }
      next.add(reviewed);
      changed = true;
    }
    if (changed) {
      _writeOverlay(_sessionQueryCache, overlay);
    }
    return next;
  }

  static bool _sameReviewState(OvertimeSession a, OvertimeSession b) {
    return a.status == b.status &&
        a.approvedHours == b.approvedHours &&
        a.rejectionReason == b.rejectionReason;
  }

  static Map<String, OvertimeSession> _readOverlay(SessionQueryCache cache) {
    final stored = cache.get<Map<String, OvertimeSession>>(_mutationOverlayKey);
    if (stored == null) return <String, OvertimeSession>{};
    return Map<String, OvertimeSession>.from(stored);
  }

  static void _writeOverlay(
    SessionQueryCache cache,
    Map<String, OvertimeSession> overlay,
  ) {
    if (overlay.isEmpty) {
      cache.invalidate(_mutationOverlayKey);
      return;
    }
    cache.set(_mutationOverlayKey, overlay);
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
            items: _overlayMutations(
              [...state.items, ...page.items],
              consumeIfMatched: true,
            ),
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
