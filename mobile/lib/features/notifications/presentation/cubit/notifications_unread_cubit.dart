import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/dashboard/domain/entities/role_dashboard_summary.dart';
import 'package:mobile/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:mobile/features/notifications/domain/usecases/notifications_usecases.dart';

class NotificationsUnreadState extends Equatable {
  const NotificationsUnreadState({
    this.count = 0,
    this.isLoading = false,
  });

  final int count;
  final bool isLoading;

  NotificationsUnreadState copyWith({
    int? count,
    bool? isLoading,
  }) {
    return NotificationsUnreadState(
      count: count ?? this.count,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [count, isLoading];
}

/// Shared unread badge state. Presentation listens; data stays in the repository.
class NotificationsUnreadCubit extends Cubit<NotificationsUnreadState> {
  NotificationsUnreadCubit({
    required GetNotificationsUnreadCountUseCase getUnreadCount,
    required NotificationsRepository repository,
    Duration refreshDebounce = const Duration(milliseconds: 400),
  })  : _getUnreadCount = getUnreadCount,
        _repository = repository,
        _refreshDebounce = refreshDebounce,
        super(const NotificationsUnreadState());

  final GetNotificationsUnreadCountUseCase _getUnreadCount;
  // ignore: unused_field
  final NotificationsRepository _repository;
  final Duration _refreshDebounce;

  Timer? _debounceTimer;
  Completer<void>? _scheduled;
  Future<void>? _inFlight;
  var _queuedAfterInFlight = false;

  /// Coalesces bursty FCM + Socket.IO + mark-read callers into one HTTP GET.
  Future<void> refresh() {
    _debounceTimer?.cancel();
    _scheduled ??= Completer<void>();
    final scheduled = _scheduled!;
    _debounceTimer = Timer(_refreshDebounce, () {
      _scheduled = null;
      unawaited(
        _runRefresh().then((_) {
          if (!scheduled.isCompleted) scheduled.complete();
        }).catchError((Object error, StackTrace stackTrace) {
          if (!scheduled.isCompleted) {
            scheduled.completeError(error, stackTrace);
          }
        }),
      );
    });
    return scheduled.future;
  }

  Future<void> _runRefresh() async {
    if (_inFlight != null) {
      _queuedAfterInFlight = true;
      await _inFlight;
      return;
    }

    final run = _refreshNow();
    _inFlight = run;
    try {
      await run;
      if (_queuedAfterInFlight && !isClosed) {
        _queuedAfterInFlight = false;
        await _refreshNow();
      }
    } finally {
      _inFlight = null;
    }
  }

  Future<void> _refreshNow() async {
    final result = await _getUnreadCount();
    if (isClosed) return;
    switch (result) {
      case Failure():
        emit(state.copyWith(isLoading: false));
      case Success(:final data):
        emit(NotificationsUnreadState(count: data));
    }
  }

  /// Applies the dedicated list API's unread meta (avoids a second HTTP GET).
  void applyExactCount(int count) {
    emit(NotificationsUnreadState(count: count < 0 ? 0 : count));
  }

  void adjustBy(int delta) {
    final next = state.count + delta;
    emit(NotificationsUnreadState(count: next < 0 ? 0 : next));
  }

  /// Dashboard live activity is not the inbox. This method must never overwrite
  /// the authoritative unread API count.
  void applyFromDashboardSummary(RoleDashboardSummary _) {
    // Live activity length must never become the badge.
  }

  void clear() {
    emit(const NotificationsUnreadState());
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    final scheduled = _scheduled;
    _scheduled = null;
    if (scheduled != null && !scheduled.isCompleted) {
      scheduled.complete();
    }
    return super.close();
  }
}
