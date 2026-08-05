import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/notifications/domain/entities/app_notification.dart';

abstract class NotificationsRepository {
  Future<Result<List<AppNotification>>> getNotifications();

  Future<Result<int>> getUnreadCount();

  Future<Result<void>> markAsRead(String id);

  Future<Result<void>> markAllAsRead(Iterable<String> ids);
}
