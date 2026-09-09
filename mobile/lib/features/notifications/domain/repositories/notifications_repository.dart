import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/dashboard/domain/entities/role_dashboard_summary.dart';
import 'package:mobile/features/notifications/domain/entities/app_notification.dart';

typedef NotificationsPageResult = ({
  List<AppNotification> items,
  int? unreadCount,
  int page,
  bool hasMore,
});

abstract class NotificationsRepository {
  Future<Result<NotificationsPageResult>> getNotifications({
    int page = 1,
    int limit = 50,
  });

  Future<Result<int>> getUnreadCount();

  /// Local unread count from an already-fetched dashboard activity feed.
  /// Avoids a second full dashboard summary request for the badge.
  int unreadCountFromActivity(List<DashboardLiveActivityItem> activity);

  Future<Result<void>> markAsRead(String id);

  Future<Result<void>> markAllAsRead(Iterable<String> ids);
}
