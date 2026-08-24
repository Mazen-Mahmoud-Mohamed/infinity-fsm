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
  })  : _getUnreadCount = getUnreadCount,
        _repository = repository,
        super(const NotificationsUnreadState());

  final GetNotificationsUnreadCountUseCase _getUnreadCount;
  final NotificationsRepository _repository;

  Future<void> refresh() async {
    emit(state.copyWith(isLoading: true));
    final result = await _getUnreadCount();
    switch (result) {
      case Failure():
        emit(state.copyWith(isLoading: false));
      case Success(:final data):
        emit(NotificationsUnreadState(count: data));
    }
  }

  /// Seeds the badge from an already-loaded dashboard summary (no extra HTTP).
  void applyFromDashboardSummary(RoleDashboardSummary summary) {
    final activity = _extractActivity(summary);
    final count = _repository.unreadCountFromActivity(activity);
    emit(NotificationsUnreadState(count: count));
  }

  void clear() {
    emit(const NotificationsUnreadState());
  }

  List<DashboardLiveActivityItem> _extractActivity(
    RoleDashboardSummary summary,
  ) {
    if (summary.liveActivity.isNotEmpty) {
      return List<DashboardLiveActivityItem>.unmodifiable(summary.liveActivity);
    }
    if (summary.teamActivity.isNotEmpty) {
      return List<DashboardLiveActivityItem>.unmodifiable(summary.teamActivity);
    }
    return summary.notifications
        .map(
          (item) {
            final parts = item.body.split('·');
            final module = parts.isEmpty ? 'general' : parts.first.trim();
            final actor = parts.length < 2
                ? null
                : parts.sublist(1).join('·').trim();
            return DashboardLiveActivityItem(
              id: item.id,
              action: item.title,
              module: module,
              actorName: (actor == null || actor.isEmpty) ? null : actor,
              createdAt: item.createdAt,
            );
          },
        )
        .toList(growable: false);
  }
}
