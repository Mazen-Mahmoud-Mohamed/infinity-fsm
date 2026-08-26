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
import 'package:mobile/features/notifications/domain/usecases/notifications_usecases.dart';
import 'package:mobile/features/notifications/presentation/cubit/notifications_unread_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeGetSummary extends Fake implements GetDashboardSummaryUseCase {}

class _FakeApi extends Fake implements NotificationsApiDataSource {
  @override
  Future<Result<({List<AppNotification> items, int unreadCount})>>
      listNotifications({
    int page = 1,
    int limit = 50,
  }) async {
    return const Failure('api unavailable', code: 'API_DOWN');
  }

  @override
  Future<Result<int>> unreadCount() async {
    return const Failure('api unavailable', code: 'API_DOWN');
  }

  @override
  Future<Result<void>> markAsRead(String id) async => const Success(null);

  @override
  Future<Result<void>> markAllAsRead() async => const Success(null);
}
class _NoRemoteCalls extends NotificationsRemoteDataSource {
  _NoRemoteCalls() : super(_FakeGetSummary());

  @override
  Future<Result<List<DashboardLiveActivityItem>>> fetchActivityFeed() {
    return Future.error(
      StateError('remote must not be called when seeding from summary'),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('applyFromDashboardSummary updates unread without remote fetch',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final local = NotificationsLocalDataSource(PreferencesService(prefs));
    final repo = NotificationsRepositoryImpl(
      remote: _NoRemoteCalls(),
      local: local,
      api: _FakeApi(),
    );
    final cubit = NotificationsUnreadCubit(
      getUnreadCount: GetNotificationsUnreadCountUseCase(repo),
      repository: repo,
    );

    final summary = RoleDashboardSummary(
      viewRole: DashboardViewRole.admin,
      period: DashboardPeriod.month,
      from: DateTime.utc(2026, 8, 1),
      to: DateTime.utc(2026, 8, 31),
      liveActivity: [
        DashboardLiveActivityItem(
          id: 'a1',
          action: 'Overtime rejected',
          module: 'overtime',
          createdAt: DateTime.utc(2026, 8, 20),
        ),
        DashboardLiveActivityItem(
          id: 'a2',
          action: 'Clock in',
          module: 'attendance',
          createdAt: DateTime.utc(2026, 8, 20),
        ),
      ],
    );

    cubit.applyFromDashboardSummary(summary);
    expect(cubit.state.count, 2);

    await repo.markAsRead('a1');
    cubit.applyFromDashboardSummary(summary);
    expect(cubit.state.count, 1);

    await cubit.close();
  });
}
