import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/dashboard/domain/entities/role_dashboard_summary.dart';
import 'package:mobile/features/notifications/data/datasources/notifications_local_datasource.dart';
import 'package:mobile/features/notifications/data/datasources/notifications_remote_datasource.dart';
import 'package:mobile/features/notifications/domain/entities/app_notification.dart';
import 'package:mobile/features/notifications/domain/repositories/notifications_repository.dart';

/// Combines remote activity feed + local read-state into domain notifications.
///
/// Future Notification API: replace [NotificationsRemoteDataSource] only.
/// Local read-state can later move behind the same repository methods.
class NotificationsRepositoryImpl implements NotificationsRepository {
  NotificationsRepositoryImpl({
    required NotificationsRemoteDataSource remote,
    required NotificationsLocalDataSource local,
  })  : _remote = remote,
        _local = local;

  final NotificationsRemoteDataSource _remote;
  final NotificationsLocalDataSource _local;

  @override
  Future<Result<List<AppNotification>>> getNotifications() async {
    final result = await _remote.fetchActivityFeed();
    return switch (result) {
      Failure(:final message, :final code) => Failure(message, code: code),
      Success(:final data) => Success(_mapWithReadState(data)),
    };
  }

  @override
  Future<Result<int>> getUnreadCount() async {
    final result = await getNotifications();
    return switch (result) {
      Failure(:final message, :final code) => Failure(message, code: code),
      Success(:final data) => Success(data.where((n) => !n.isRead).length),
    };
  }

  @override
  Future<Result<void>> markAsRead(String id) async {
    await _local.markAsRead(id);
    return const Success(null);
  }

  @override
  Future<Result<void>> markAllAsRead(Iterable<String> ids) async {
    await _local.markAllAsRead(ids);
    return const Success(null);
  }

  List<AppNotification> _mapWithReadState(
    List<DashboardLiveActivityItem> activity,
  ) {
    final readIds = _local.getReadIds();
    return activity
        .map(
          (item) => AppNotification(
            id: item.id,
            title: item.action,
            body: [
              item.module,
              if (item.actorName != null && item.actorName!.isNotEmpty)
                item.actorName,
            ].join(' · '),
            category: AppNotification.categoryFromModule(item.module),
            module: item.module,
            actorName: item.actorName,
            createdAt: item.createdAt,
            isRead: readIds.contains(item.id),
          ),
        )
        .toList(growable: false);
  }
}
