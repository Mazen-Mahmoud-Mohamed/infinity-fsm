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
import 'package:mobile/features/notifications/presentation/cubit/notifications_unread_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeGetSummary extends Fake implements GetDashboardSummaryUseCase {}

class _TrackingApi extends Fake implements NotificationsApiDataSource {
  var unreadCalls = 0;
  var listCalls = 0;

  @override
  Future<
      Result<
          ({
            List<AppNotification> items,
            int unreadCount,
            int page,
            bool hasMore,
          })>> listNotifications({
    int page = 1,
    int limit = 50,
  }) async {
    listCalls++;
    return const Failure('api unavailable', code: 'API_DOWN');
  }

  @override
  Future<Result<int>> unreadCount() async {
    unreadCalls++;
    return const Failure('api down', code: 'API_DOWN');
  }

  @override
  Future<Result<void>> markAsRead(String id) async => const Success(null);

  @override
  Future<Result<void>> markAllAsRead() async => const Success(null);
}

class _TrackingRemote extends NotificationsRemoteDataSource {
  _TrackingRemote() : super(_FakeGetSummary());

  var feedCalls = 0;

  @override
  Future<Result<List<DashboardLiveActivityItem>>> fetchActivityFeed() async {
    feedCalls++;
    return const Success([]);
  }
}

class _CountingUnreadRepo extends Fake implements NotificationsRepository {
  var unreadCalls = 0;

  @override
  Future<Result<int>> getUnreadCount() async {
    unreadCalls++;
    return const Success(4);
  }

  @override
  int unreadCountFromActivity(List<DashboardLiveActivityItem> activity) => 0;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('getUnreadCount uses dedicated API and never loads dashboard feed',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final api = _TrackingApi();
    final remote = _TrackingRemote();
    final repo = NotificationsRepositoryImpl(
      remote: remote,
      local: NotificationsLocalDataSource(PreferencesService(prefs)),
      api: api,
    );

    final result = await repo.getUnreadCount();

    expect(result, isA<Failure<int>>());
    expect(api.unreadCalls, 1);
    expect(api.listCalls, 0);
    expect(remote.feedCalls, 0);
  });

  test('list success returns API unreadCount without a second unread GET',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final api = _SuccessListApi();
    final remote = _TrackingRemote();
    final repo = NotificationsRepositoryImpl(
      remote: remote,
      local: NotificationsLocalDataSource(PreferencesService(prefs)),
      api: api,
    );

    final result = await repo.getNotifications();
    expect(result, isA<Success<NotificationsPageResult>>());
    final data = (result as Success<NotificationsPageResult>).data;
    expect(data.unreadCount, 9);
    expect(data.items, hasLength(1));
    expect(remote.feedCalls, 0);
    expect(api.unreadCalls, 0);
  });

  test('unread refresh coalesces bursty callers into one HTTP GET', () async {
    final repo = _CountingUnreadRepo();
    final cubit = NotificationsUnreadCubit(
      getUnreadCount: GetNotificationsUnreadCountUseCase(repo),
      repository: repo,
      refreshDebounce: Duration.zero,
    );

    final first = cubit.refresh();
    final second = cubit.refresh();
    final third = cubit.refresh();
    await Future.wait([first, second, third]);

    expect(repo.unreadCalls, 1);
    expect(cubit.state.count, 4);

    await cubit.close();
  });
}

class _SuccessListApi extends Fake implements NotificationsApiDataSource {
  var unreadCalls = 0;

  @override
  Future<Result<({List<AppNotification> items, int unreadCount, int page, bool hasMore})>>
      listNotifications({
    int page = 1,
    int limit = 50,
  }) async {
    return Success(
      (
        items: [
          AppNotification(
            id: 'n1',
            title: 'Assigned',
            body: 'WO',
            category: NotificationCategory.workOrders,
            module: 'work_orders',
            createdAt: DateTime.utc(2026, 9, 1),
            isRead: false,
          ),
        ],
        unreadCount: 9,
        page: page,
        hasMore: false,
      ),
    );
  }

  @override
  Future<Result<int>> unreadCount() async {
    unreadCalls++;
    return const Success(9);
  }
}
