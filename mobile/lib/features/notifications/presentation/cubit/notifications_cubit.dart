import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/notifications/domain/entities/app_notification.dart';
import 'package:mobile/features/notifications/domain/entities/app_notification_realtime.dart';
import 'package:mobile/features/notifications/domain/usecases/notifications_usecases.dart';
import 'package:mobile/features/notifications/presentation/cubit/notifications_unread_cubit.dart';

enum NotificationsStatus { initial, loading, ready, failure }

class NotificationsState extends Equatable {
  const NotificationsState({
    this.status = NotificationsStatus.initial,
    this.items = const [],
    this.category = NotificationCategory.all,
    this.searchQuery = '',
    this.message,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.page = 1,
    this.hasMore = false,
  });

  final NotificationsStatus status;
  final List<AppNotification> items;
  final NotificationCategory category;
  final String searchQuery;
  final String? message;
  final bool isRefreshing;
  final bool isLoadingMore;
  final int page;
  final bool hasMore;

  /// Client-side search has no matches, but older server pages may still exist.
  bool get showSearchLoadMore {
    return searchQuery.trim().isNotEmpty && visibleItems.isEmpty && hasMore;
  }

  List<AppNotification> get visibleItems {
    final query = searchQuery.trim().toLowerCase();
    return items.where((item) {
      final categoryOk = category == NotificationCategory.all ||
          item.category == category;
      if (!categoryOk) return false;
      if (query.isEmpty) return true;
      return item.title.toLowerCase().contains(query) ||
          item.body.toLowerCase().contains(query) ||
          item.module.toLowerCase().contains(query) ||
          (item.actorName?.toLowerCase().contains(query) ?? false);
    }).toList(growable: false);
  }

  NotificationsState copyWith({
    NotificationsStatus? status,
    List<AppNotification>? items,
    NotificationCategory? category,
    String? searchQuery,
    String? message,
    bool clearMessage = false,
    bool? isRefreshing,
    bool? isLoadingMore,
    int? page,
    bool? hasMore,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      items: items ?? this.items,
      category: category ?? this.category,
      searchQuery: searchQuery ?? this.searchQuery,
      message: clearMessage ? null : (message ?? this.message),
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  @override
  List<Object?> get props => [
        status,
        items,
        category,
        searchQuery,
        message,
        isRefreshing,
        isLoadingMore,
        page,
        hasMore,
      ];
}

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit({
    required GetNotificationsUseCase getNotifications,
    required MarkNotificationReadUseCase markNotificationRead,
    required MarkAllNotificationsReadUseCase markAllNotificationsRead,
    required NotificationsUnreadCubit unreadCubit,
  })  : _getNotifications = getNotifications,
        _markNotificationRead = markNotificationRead,
        _markAllNotificationsRead = markAllNotificationsRead,
        _unreadCubit = unreadCubit,
        super(const NotificationsState());

  final GetNotificationsUseCase _getNotifications;
  final MarkNotificationReadUseCase _markNotificationRead;
  final MarkAllNotificationsReadUseCase _markAllNotificationsRead;
  final NotificationsUnreadCubit _unreadCubit;

  int _generation = 0;
  bool _loadMoreInFlight = false;
  bool _pageLoadInFlight = false;
  final List<AppNotification> _pendingRealtime = [];
  String? _authenticatedUserId;

  static const int pageSize = 50;

  Future<void> load() async {
    final generation = ++_generation;
    _pageLoadInFlight = true;
    emit(
      state.copyWith(
        status: state.items.isEmpty
            ? NotificationsStatus.loading
            : state.status,
        isRefreshing: state.items.isNotEmpty,
        isLoadingMore: false,
        page: 1,
        clearMessage: true,
      ),
    );

    final result = await _getNotifications(page: 1, limit: pageSize);
    if (isClosed) {
      _pageLoadInFlight = false;
      return;
    }
    if (generation != _generation) {
      return;
    }

    switch (result) {
      case Failure(:final message):
        _pageLoadInFlight = false;
        emit(
          state.copyWith(
            status: NotificationsStatus.failure,
            message: message,
            isRefreshing: false,
            isLoadingMore: false,
          ),
        );
        _flushPendingRealtime();
      case Success(:final data):
        _pageLoadInFlight = false;
        emit(
          state.copyWith(
            status: NotificationsStatus.ready,
            items: data.items,
            page: data.page,
            hasMore: data.hasMore,
            clearMessage: true,
            isRefreshing: false,
            isLoadingMore: false,
          ),
        );
        _applyUnreadMeta(data.unreadCount);
        _flushPendingRealtime();
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore ||
        state.isLoadingMore ||
        state.isRefreshing ||
        _loadMoreInFlight ||
        _pageLoadInFlight ||
        (state.status == NotificationsStatus.loading && state.items.isEmpty)) {
      return;
    }

    _loadMoreInFlight = true;
    final generation = _generation;
    emit(state.copyWith(isLoadingMore: true, clearMessage: true));

    final nextPage = state.page + 1;
    final result =
        await _getNotifications(page: nextPage, limit: pageSize);
    if (isClosed) {
      _loadMoreInFlight = false;
      return;
    }
    if (generation != _generation) {
      _loadMoreInFlight = false;
      return;
    }

    switch (result) {
      case Failure(:final message):
        _loadMoreInFlight = false;
        emit(
          state.copyWith(
            isLoadingMore: false,
            message: message,
          ),
        );
      case Success(:final data):
        _loadMoreInFlight = false;
        emit(
          state.copyWith(
            status: NotificationsStatus.ready,
            items: mergeNotificationsById(
              primary: state.items,
              secondary: data.items,
            ),
            page: data.page,
            hasMore: data.hasMore,
            isLoadingMore: false,
            clearMessage: true,
          ),
        );
        _flushPendingRealtime();
    }
  }

  /// Binds inbox ingest to the signed-in user. Cleared on [reset].
  void bindAuthenticatedUser(String? userId) {
    final next = userId?.trim() ?? '';
    final bound = next.isEmpty ? null : next;
    if (bound != _authenticatedUserId) {
      _pendingRealtime.clear();
    }
    _authenticatedUserId = bound;
  }

  /// Inserts a realtime notification at the top without reloading the inbox.
  ///
  /// Fail-closed: [recipientUserId] and [authenticatedUserId] must both be
  /// present, equal each other, and match the user bound at login.
  void ingestRealtime(
    AppNotification notification, {
    String? recipientUserId,
    String? authenticatedUserId,
  }) {
    if (notification.id.isEmpty) return;
    if (!_canIngestRealtime(
      recipientUserId: recipientUserId,
      authenticatedUserId: authenticatedUserId,
    )) {
      return;
    }

    if (state.isRefreshing || _pageLoadInFlight) {
      _queuePendingRealtime(notification);
      return;
    }

    _prependRealtime(notification);
  }

  /// Parses a socket payload and ingest it. Returns false when the payload is
  /// incomplete or fail-closed so the caller keeps unread-refresh only.
  bool ingestRealtimePayload(
    Map<String, dynamic> raw, {
    required String localeCode,
    String? authenticatedUserId,
  }) {
    final parsed = appNotificationFromRealtime(raw, localeCode: localeCode);
    if (parsed == null) return false;
    final recipient = realtimeRecipientUserId(raw);
    if (!_canIngestRealtime(
      recipientUserId: recipient,
      authenticatedUserId: authenticatedUserId,
    )) {
      return false;
    }
    ingestRealtime(
      parsed,
      recipientUserId: recipient,
      authenticatedUserId: authenticatedUserId,
    );
    return true;
  }

  void reset() {
    _generation++;
    _loadMoreInFlight = false;
    _pageLoadInFlight = false;
    _pendingRealtime.clear();
    _authenticatedUserId = null;
    if (!isClosed) {
      emit(const NotificationsState());
    }
  }

  void setCategory(NotificationCategory category) {
    if (state.category == category) return;
    emit(state.copyWith(category: category));
    unawaited(load());
  }

  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  Future<void> markAsRead(String id) async {
    final wasUnread =
        state.items.any((item) => item.id == id && !item.isRead);
    final result = await _markNotificationRead(id);
    if (result is Failure) return;
    final next = state.items
        .map((item) => item.id == id ? item.copyWith(isRead: true) : item)
        .toList(growable: false);
    emit(state.copyWith(items: next));
    if (wasUnread) {
      _unreadCubit.adjustBy(-1);
    }
  }

  Future<void> markAllAsRead() async {
    final ids = state.items.map((e) => e.id);
    final result = await _markAllNotificationsRead(ids);
    if (result is Failure) return;
    final next = state.items
        .map((item) => item.copyWith(isRead: true))
        .toList(growable: false);
    emit(state.copyWith(items: next));
    _unreadCubit.applyExactCount(0);
  }

  void _queuePendingRealtime(AppNotification notification) {
    _pendingRealtime.removeWhere((item) => item.id == notification.id);
    _pendingRealtime.add(notification);
  }

  void _flushPendingRealtime() {
    if (_pendingRealtime.isEmpty || isClosed) return;
    if (state.isRefreshing || _pageLoadInFlight) return;
    var items = state.items;
    for (final pending in _pendingRealtime) {
      if (items.any((item) => item.id == pending.id)) continue;
      items = mergeNotificationsById(primary: [pending], secondary: items);
    }
    _pendingRealtime.clear();
    emit(state.copyWith(items: items));
  }

  void _prependRealtime(AppNotification notification) {
    if (state.items.any((item) => item.id == notification.id)) {
      return;
    }
    emit(
      state.copyWith(
        status: NotificationsStatus.ready,
        items: mergeNotificationsById(
          primary: [notification],
          secondary: state.items,
        ),
      ),
    );
  }

  bool _canIngestRealtime({
    String? recipientUserId,
    String? authenticatedUserId,
  }) {
    final recipient = recipientUserId?.trim() ?? '';
    final captured = authenticatedUserId?.trim() ?? '';
    final bound = _authenticatedUserId?.trim() ?? '';
    if (recipient.isEmpty || captured.isEmpty || bound.isEmpty) {
      return false;
    }
    return recipient == captured && captured == bound;
  }

  void _applyUnreadMeta(int? unreadCount) {
    if (unreadCount != null) {
      _unreadCubit.applyExactCount(unreadCount);
    } else {
      _unreadCubit.refresh();
    }
  }
}
