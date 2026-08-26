import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/dashboard/domain/entities/role_dashboard_summary.dart';
import 'package:mobile/features/notifications/data/datasources/notifications_api_datasource.dart';
import 'package:mobile/features/notifications/data/datasources/notifications_local_datasource.dart';
import 'package:mobile/features/notifications/data/datasources/notifications_remote_datasource.dart';
import 'package:mobile/features/notifications/domain/entities/app_notification.dart';
import 'package:mobile/features/notifications/domain/repositories/notifications_repository.dart';

/// Combines dedicated notifications API (preferred) with dashboard activity
/// fallback, plus local read-state for legacy feed items.
class NotificationsRepositoryImpl implements NotificationsRepository {
  NotificationsRepositoryImpl({
    required NotificationsRemoteDataSource remote,
    required NotificationsLocalDataSource local,
    required NotificationsApiDataSource api,
  })  : _remote = remote,
        _local = local,
        _api = api;

  final NotificationsRemoteDataSource _remote;
  final NotificationsLocalDataSource _local;
  final NotificationsApiDataSource _api;

  @override
  Future<Result<List<AppNotification>>> getNotifications() async {
    final apiResult = await _api.listNotifications();
    switch (apiResult) {
      case Success(:final data):
        return Success(data.items);
      case Failure():
        break;
    }

    final result = await _remote.fetchActivityFeed();
    return switch (result) {
      Failure(:final message, :final code) => Failure(message, code: code),
      Success(:final data) => Success(_mapWithReadState(data)),
    };
  }

  @override
  Future<Result<int>> getUnreadCount() async {
    final apiCount = await _api.unreadCount();
    if (apiCount is Success<int>) {
      return apiCount;
    }
    final result = await getNotifications();
    return switch (result) {
      Failure(:final message, :final code) => Failure(message, code: code),
      Success(:final data) => Success(data.where((n) => !n.isRead).length),
    };
  }

  @override
  int unreadCountFromActivity(List<DashboardLiveActivityItem> activity) {
    return _mapWithReadState(activity).where((n) => !n.isRead).length;
  }

  @override
  Future<Result<void>> markAsRead(String id) async {
    final apiResult = await _api.markAsRead(id);
    await _local.markAsRead(id);
    if (apiResult is Failure) {
      // Local mark still applied for legacy feed items.
      return const Success(null);
    }
    return apiResult;
  }

  @override
  Future<Result<void>> markAllAsRead(Iterable<String> ids) async {
    await _api.markAllAsRead();
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
