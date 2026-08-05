import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/notifications/domain/entities/app_notification.dart';
import 'package:mobile/features/notifications/domain/repositories/notifications_repository.dart';

class GetNotificationsUseCase {
  GetNotificationsUseCase(this._repository);

  final NotificationsRepository _repository;

  Future<Result<List<AppNotification>>> call() =>
      _repository.getNotifications();
}

class GetNotificationsUnreadCountUseCase {
  GetNotificationsUnreadCountUseCase(this._repository);

  final NotificationsRepository _repository;

  Future<Result<int>> call() => _repository.getUnreadCount();
}

class MarkNotificationReadUseCase {
  MarkNotificationReadUseCase(this._repository);

  final NotificationsRepository _repository;

  Future<Result<void>> call(String id) => _repository.markAsRead(id);
}

class MarkAllNotificationsReadUseCase {
  MarkAllNotificationsReadUseCase(this._repository);

  final NotificationsRepository _repository;

  Future<Result<void>> call(Iterable<String> ids) =>
      _repository.markAllAsRead(ids);
}
