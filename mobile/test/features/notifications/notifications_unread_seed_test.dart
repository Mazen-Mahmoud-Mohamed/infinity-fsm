import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/storage/preferences_service.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/dashboard/domain/entities/role_dashboard_summary.dart';
import 'package:mobile/features/dashboard/domain/usecases/get_dashboard_summary_usecase.dart';
import 'package:mobile/features/notifications/data/datasources/notifications_api_datasource.dart';
import 'package:mobile/features/notifications/data/datasources/notifications_local_datasource.dart';
import 'package:mobile/features/notifications/data/datasources/notifications_remote_datasource.dart';
import 'package:mobile/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:mobile/features/notifications/domain/entities/app_notification.dart';
import 'package:mobile/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:mobile/features/notifications/domain/usecases/notifications_usecases.dart';
import 'package:mobile/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:mobile/features/notifications/presentation/cubit/notifications_unread_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeGetSummary extends Fake implements GetDashboardSummaryUseCase {}

class _ControllableApi extends Fake implements NotificationsApiDataSource {
  Result<void> markResult = const Success(null);
  var markCalls = 0;

  @override
  Future<Result<({List<AppNotification> items, int unreadCount, int page, bool hasMore})>>
      listNotifications({
    int page = 1,
    int limit = 50,
  }) async {
    return const Failure('unused', code: 'UNUSED');
  }

  @override
  Future<Result<int>> unreadCount() async => const Success(0);

  @override
  Future<Result<void>> markAsRead(String id) async {
    markCalls++;
    return markResult;
  }

  @override
  Future<Result<void>> markAllAsRead() async => markResult;
}

class _CountingUnreadRepo extends Fake implements NotificationsRepository {
  var unreadCalls = 0;
  int unread = 3;

  @override
  Future<Result<int>> getUnreadCount() async {
    unreadCalls++;
    return Success(unread);
  }

  @override
  int unreadCountFromActivity(List<DashboardLiveActivityItem> activity) =>
      activity.length;
}

class _NoRemote extends NotificationsRemoteDataSource {
  _NoRemote() : super(_FakeGetSummary());

  @override
  Future<Result<List<DashboardLiveActivityItem>>> fetchActivityFeed() async {
    return const Success([]);
  }
}

class _FixedGet implements GetNotificationsUseCase {
  _FixedGet(this.items);
  final List<AppNotification> items;

  @override
  Future<Result<NotificationsPageResult>> call({
    int page = 1,
    int limit = 50,
  }) async {
    return Success(
      (
        items: items,
        unreadCount: items.where((e) => !e.isRead).length,
        page: page,
        hasMore: false,
      ),
    );
  }
}

RoleDashboardSummary _summaryWithActivity(int count) {
  return RoleDashboardSummary(
    viewRole: DashboardViewRole.admin,
    period: DashboardPeriod.month,
    from: DateTime.utc(2026, 8, 1),
    to: DateTime.utc(2026, 8, 31),
    liveActivity: List.generate(
      count,
      (i) => DashboardLiveActivityItem(
        id: 'a$i',
        action: 'Event $i',
        module: 'overtime',
        createdAt: DateTime.utc(2026, 8, 20),
      ),
    ),
  );
}

AppNotification get _unreadItem => AppNotification(
      id: 'n1',
      title: 'Assigned',
      body: 'WO',
      category: NotificationCategory.workOrders,
      module: 'work_orders',
      isRead: false,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('live activity count cannot overwrite unread count', () async {
    final repo = _CountingUnreadRepo();
    final cubit = NotificationsUnreadCubit(
      getUnreadCount: GetNotificationsUnreadCountUseCase(repo),
      repository: repo,
    );

    cubit.applyExactCount(7);
    cubit.applyFromDashboardSummary(_summaryWithActivity(2));
    expect(cubit.state.count, 7);

    await cubit.close();
  });

  test('unread count remains correct after realtime refresh', () async {
    final repo = _CountingUnreadRepo()..unread = 4;
    final cubit = NotificationsUnreadCubit(
      getUnreadCount: GetNotificationsUnreadCountUseCase(repo),
      repository: repo,
      refreshDebounce: Duration.zero,
    );

    cubit.applyExactCount(3);
    await cubit.refresh();
    expect(cubit.state.count, 4);

    cubit.applyFromDashboardSummary(_summaryWithActivity(99));
    expect(cubit.state.count, 4);

    await cubit.close();
  });

  test('unread count remains correct after dashboard summary refresh', () async {
    final repo = _CountingUnreadRepo();
    final cubit = NotificationsUnreadCubit(
      getUnreadCount: GetNotificationsUnreadCountUseCase(repo),
      repository: repo,
    );

    cubit.applyExactCount(8);
    cubit.applyFromDashboardSummary(_summaryWithActivity(2));
    cubit.applyFromDashboardSummary(_summaryWithActivity(15));
    expect(cubit.state.count, 8);

    await cubit.close();
  });

  test('successful markAsRead updates local unread and list', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final local = NotificationsLocalDataSource(PreferencesService(prefs));
    await local.bindUser('user-a');
    final api = _ControllableApi();
    final repo = NotificationsRepositoryImpl(
      remote: _NoRemote(),
      local: local,
      api: api,
    );

    final unread = NotificationsUnreadCubit(
      getUnreadCount: GetNotificationsUnreadCountUseCase(repo),
      repository: repo,
    )..applyExactCount(1);

    final cubit = NotificationsCubit(
      getNotifications: _FixedGet([_unreadItem]),
      markNotificationRead: MarkNotificationReadUseCase(repo),
      markAllNotificationsRead: MarkAllNotificationsReadUseCase(repo),
      unreadCubit: unread,
    );
    await cubit.load();
    await cubit.markAsRead('n1');

    expect(api.markCalls, 1);
    expect(cubit.state.items.single.isRead, isTrue);
    expect(unread.state.count, 0);
    expect(local.getReadIds(), {'n1'});

    await cubit.close();
    await unread.close();
  });

  test('failed API keeps notification unread', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final local = NotificationsLocalDataSource(PreferencesService(prefs));
    await local.bindUser('user-a');
    final api = _ControllableApi()
      ..markResult = const Failure('server', code: 'HTTP_500');
    final repo = NotificationsRepositoryImpl(
      remote: _NoRemote(),
      local: local,
      api: api,
    );

    final unread = NotificationsUnreadCubit(
      getUnreadCount: GetNotificationsUnreadCountUseCase(repo),
      repository: repo,
    )..applyExactCount(1);

    final cubit = NotificationsCubit(
      getNotifications: _FixedGet([_unreadItem]),
      markNotificationRead: MarkNotificationReadUseCase(repo),
      markAllNotificationsRead: MarkAllNotificationsReadUseCase(repo),
      unreadCubit: unread,
    );
    await cubit.load();
    await cubit.markAsRead('n1');

    expect(cubit.state.items.single.isRead, isFalse);
    expect(unread.state.count, 1);
    expect(local.getReadIds(), isEmpty);

    await cubit.close();
    await unread.close();
  });

  test('network exception keeps notification unread', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final local = NotificationsLocalDataSource(PreferencesService(prefs));
    await local.bindUser('user-a');
    final api = _ControllableApi()
      ..markResult = const Failure('network', code: 'NETWORK');
    final repo = NotificationsRepositoryImpl(
      remote: _NoRemote(),
      local: local,
      api: api,
    );

    final result = await repo.markAsRead('n1');
    expect(result, isA<Failure<void>>());
    expect(local.getReadIds(), isEmpty);
  });

  test('retry after failure works', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final local = NotificationsLocalDataSource(PreferencesService(prefs));
    await local.bindUser('user-a');
    final api = _ControllableApi()
      ..markResult = const Failure('down', code: 'NETWORK');
    final repo = NotificationsRepositoryImpl(
      remote: _NoRemote(),
      local: local,
      api: api,
    );

    final unread = NotificationsUnreadCubit(
      getUnreadCount: GetNotificationsUnreadCountUseCase(repo),
      repository: repo,
    )..applyExactCount(1);

    final cubit = NotificationsCubit(
      getNotifications: _FixedGet([_unreadItem]),
      markNotificationRead: MarkNotificationReadUseCase(repo),
      markAllNotificationsRead: MarkAllNotificationsReadUseCase(repo),
      unreadCubit: unread,
    );
    await cubit.load();
    await cubit.markAsRead('n1');
    expect(cubit.state.items.single.isRead, isFalse);
    expect(unread.state.count, 1);
    expect(local.getReadIds(), isEmpty);

    api.markResult = const Success(null);
    await cubit.markAsRead('n1');
    expect(cubit.state.items.single.isRead, isTrue);
    expect(unread.state.count, 0);
    expect(api.markCalls, 2);
    expect(local.getReadIds(), {'n1'});

    await cubit.close();
    await unread.close();
  });
}
