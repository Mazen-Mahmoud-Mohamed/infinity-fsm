import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/utils/result.dart';
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
  })  : _getUnreadCount = getUnreadCount,
        super(const NotificationsUnreadState());

  final GetNotificationsUnreadCountUseCase _getUnreadCount;

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

  void clear() {
    emit(const NotificationsUnreadState());
  }
}
