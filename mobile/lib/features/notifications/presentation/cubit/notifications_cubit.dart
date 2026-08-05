import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/notifications/domain/entities/app_notification.dart';
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
  });

  final NotificationsStatus status;
  final List<AppNotification> items;
  final NotificationCategory category;
  final String searchQuery;
  final String? message;
  final bool isRefreshing;

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

  int get unreadCount => items.where((n) => !n.isRead).length;

  bool get hasUnread => unreadCount > 0;

  NotificationsState copyWith({
    NotificationsStatus? status,
    List<AppNotification>? items,
    NotificationCategory? category,
    String? searchQuery,
    String? message,
    bool clearMessage = false,
    bool? isRefreshing,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      items: items ?? this.items,
      category: category ?? this.category,
      searchQuery: searchQuery ?? this.searchQuery,
      message: clearMessage ? null : (message ?? this.message),
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props =>
      [status, items, category, searchQuery, message, isRefreshing];
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

  Future<void> load() async {
    emit(
      state.copyWith(
        status: state.items.isEmpty
            ? NotificationsStatus.loading
            : state.status,
        isRefreshing: state.items.isNotEmpty,
        clearMessage: true,
      ),
    );

    final result = await _getNotifications();
    switch (result) {
      case Failure(:final message):
        emit(
          state.copyWith(
            status: NotificationsStatus.failure,
            message: message,
            isRefreshing: false,
          ),
        );
      case Success(:final data):
        emit(
          state.copyWith(
            status: NotificationsStatus.ready,
            items: data,
            clearMessage: true,
            isRefreshing: false,
          ),
        );
        await _unreadCubit.refresh();
    }
  }

  void setCategory(NotificationCategory category) {
    if (state.category == category) return;
    emit(state.copyWith(category: category));
  }

  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  Future<void> markAsRead(String id) async {
    final result = await _markNotificationRead(id);
    if (result is Failure) return;
    final next = state.items
        .map((item) => item.id == id ? item.copyWith(isRead: true) : item)
        .toList(growable: false);
    emit(state.copyWith(items: next));
    await _unreadCubit.refresh();
  }

  Future<void> markAllAsRead() async {
    final ids = state.items.map((e) => e.id);
    final result = await _markAllNotificationsRead(ids);
    if (result is Failure) return;
    final next = state.items
        .map((item) => item.copyWith(isRead: true))
        .toList(growable: false);
    emit(state.copyWith(items: next));
    await _unreadCubit.refresh();
  }
}
