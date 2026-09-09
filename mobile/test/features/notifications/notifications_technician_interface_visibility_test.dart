import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/cache/session_query_cache.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/services/auth_session_service.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/auth/domain/entities/current_user.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobile/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:mobile/features/auth/domain/usecases/logout_all_devices_usecase.dart';
import 'package:mobile/features/auth/domain/usecases/logout_usecase.dart';
import 'package:mobile/features/auth/domain/usecases/restore_session_usecase.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/features/dashboard/domain/entities/role_dashboard_summary.dart';
import 'package:mobile/features/notifications/domain/entities/app_notification.dart';
import 'package:mobile/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:mobile/features/notifications/domain/usecases/notifications_usecases.dart';
import 'package:mobile/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:mobile/features/notifications/presentation/cubit/notifications_unread_cubit.dart';
import 'package:mobile/features/notifications/presentation/pages/notifications_page.dart';
import 'package:mobile/features/notifications/presentation/widgets/notification_list_tile.dart';
import 'package:mobile/features/notifications/presentation/widgets/notifications_desktop_view.dart';
import 'package:mobile/features/settings/data/datasources/technician_interface_local_datasource.dart';
import 'package:mobile/features/settings/domain/entities/settings_entities.dart';
import 'package:mobile/features/settings/domain/repositories/settings_repository.dart';
import 'package:mobile/features/settings/domain/usecases/settings_usecases.dart';
import 'package:mobile/features/settings/presentation/cubit/technician_interface_cubits.dart';
import 'package:mobile/core/storage/preferences_service.dart';

const _technician = CurrentUser(
  id: 'tech-1',
  companyId: 'c1',
  email: 'tech@example.com',
  firstName: 'Field',
  lastName: 'Tech',
  fullName: 'Field Tech',
  roles: ['TECHNICIAN'],
  permissions: [],
);

class _FakeAuthRepo extends Fake implements AuthRepository {}

class _UnreadRepo extends Fake implements NotificationsRepository {
  @override
  Future<Result<int>> getUnreadCount() async => const Success(0);

  @override
  int unreadCountFromActivity(List<DashboardLiveActivityItem> activity) => 0;
}

class _StaticGet implements GetNotificationsUseCase {
  _StaticGet(this.items);

  final List<AppNotification> items;

  @override
  Future<Result<NotificationsPageResult>> call({
    int page = 1,
    int limit = 50,
  }) async {
    return Success(
      (
        items: items,
        unreadCount: 0,
        page: page,
        hasMore: false,
      ),
    );
  }
}

class _NoopMark implements MarkNotificationReadUseCase {
  @override
  Future<Result<void>> call(String id) async => const Success(null);
}

class _NoopMarkAll implements MarkAllNotificationsReadUseCase {
  @override
  Future<Result<void>> call(Iterable<String> ids) async => const Success(null);
}

class _MemoryPreferences implements PreferencesService {
  final Map<String, Object> _store = {};

  @override
  String? getString(String key) => _store[key] as String?;

  @override
  Future<bool> setString(String key, String value) async {
    _store[key] = value;
    return true;
  }

  @override
  bool? getBool(String key) => _store[key] as bool?;

  @override
  Future<bool> setBool(String key, bool value) async {
    _store[key] = value;
    return true;
  }

  @override
  int? getInt(String key) => _store[key] as int?;

  @override
  Future<bool> setInt(String key, int value) async {
    _store[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    _store.remove(key);
    return true;
  }
}

class _FakeSettingsRepo extends Fake implements SettingsRepository {
  _FakeSettingsRepo(this.config);

  TechnicianInterfaceConfig config;

  @override
  Future<Result<TechnicianInterfaceConfig>> getTechnicianInterfaceConfig() async =>
      Success(config);
}

class _ControllableTiCubit extends TechnicianInterfaceCubit {
  _ControllableTiCubit({
    required super.getConfig,
    required super.sessionQueryCache,
    required super.localDataSource,
  });

  void seedReady(TechnicianInterfaceConfig config) {
    emit(
      TechnicianInterfaceState(
        status: TechnicianInterfaceLoadStatus.ready,
        config: config,
      ),
    );
  }

  void seedNotReady() {
    emit(const TechnicianInterfaceState());
  }
}

AuthCubit _authCubit(CurrentUser user) {
  final session = AuthSessionService();
  final cubit = AuthCubit(
    restoreSessionUseCase: RestoreSessionUseCase(_FakeAuthRepo()),
    getCurrentUserUseCase: GetCurrentUserUseCase(_FakeAuthRepo()),
    logoutUseCase: LogoutUseCase(_FakeAuthRepo()),
    logoutAllDevicesUseCase: LogoutAllDevicesUseCase(_FakeAuthRepo()),
    authSessionService: session,
    sessionQueryCache: SessionQueryCache(),
  );
  cubit.emit(
    cubit.state.copyWith(
      status: AuthStatus.authenticated,
      user: user,
    ),
  );
  return cubit;
}

({
  NotificationsCubit cubit,
  NotificationsUnreadCubit unread,
}) _notificationCubits(List<AppNotification> items) {
  final unread = NotificationsUnreadCubit(
    getUnreadCount: GetNotificationsUnreadCountUseCase(_UnreadRepo()),
    repository: _UnreadRepo(),
    refreshDebounce: Duration.zero,
  );
  final cubit = NotificationsCubit(
    getNotifications: _StaticGet(items),
    markNotificationRead: _NoopMark(),
    markAllNotificationsRead: _NoopMarkAll(),
    unreadCubit: unread,
  );
  return (cubit: cubit, unread: unread);
}

_ControllableTiCubit _tiCubit(TechnicianInterfaceConfig config) {
  final cache = SessionQueryCache();
  final repo = _FakeSettingsRepo(config);
  final cubit = _ControllableTiCubit(
    getConfig: GetTechnicianInterfaceConfigUseCase(repo),
    sessionQueryCache: cache,
    localDataSource: TechnicianInterfaceLocalDataSource(_MemoryPreferences()),
  );
  cubit.seedReady(config);
  return cubit;
}

const _wo = AppNotification(
  id: 'n-wo',
  title: 'WO Assigned',
  body: 'Body',
  category: NotificationCategory.workOrders,
  module: 'work_orders',
  entityType: 'work_order',
  entityId: 'wo1',
);

const _update = AppNotification(
  id: 'n-upd',
  title: 'App Update',
  body: 'New build',
  category: NotificationCategory.settings,
  module: 'app_update',
  entityType: 'app_update',
);

Widget _wrap({
  required Widget child,
  required AuthCubit auth,
  required _ControllableTiCubit ti,
  required NotificationsCubit notifications,
  required NotificationsUnreadCubit unread,
}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>.value(value: auth),
        BlocProvider<TechnicianInterfaceCubit>.value(value: ti),
        BlocProvider.value(value: notifications),
        BlocProvider.value(value: unread),
      ],
      child: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'desktop notifications back pops to previous route',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final auth = _authCubit(_technician);
      final ti = _tiCubit(TechnicianInterfaceConfig.defaults);
      final setup = _notificationCubits(const [_wo]);
      await setup.cubit.load();
      final search = TextEditingController();
      addTearDown(() async {
        search.dispose();
        await setup.cubit.close();
        await setup.unread.close();
        await ti.close();
        await auth.close();
      });

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: MultiBlocProvider(
            providers: [
              BlocProvider<AuthCubit>.value(value: auth),
              BlocProvider<TechnicianInterfaceCubit>.value(value: ti),
              BlocProvider.value(value: setup.cubit),
              BlocProvider.value(value: setup.unread),
            ],
            child: Builder(
              builder: (context) {
                return Scaffold(
                  body: Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => MultiBlocProvider(
                              providers: [
                                BlocProvider<AuthCubit>.value(value: auth),
                                BlocProvider<TechnicianInterfaceCubit>.value(
                                  value: ti,
                                ),
                                BlocProvider.value(value: setup.cubit),
                                BlocProvider.value(value: setup.unread),
                              ],
                              child: Scaffold(
                                body: NotificationsDesktopView(
                                  searchController: search,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      child: const Text('open-notifications'),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('open-notifications'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('notifications-desktop-back')), findsOneWidget);

      await tester.tap(find.byKey(const Key('notifications-desktop-back')));
      await tester.pumpAndSettle();

      expect(find.text('open-notifications'), findsOneWidget);
      expect(find.byKey(const Key('notifications-desktop-back')), findsNothing);
    },
  );

  testWidgets(
    'mobile notifications keeps AppBar and omits desktop back',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final auth = _authCubit(_technician);
      final ti = _tiCubit(TechnicianInterfaceConfig.defaults);
      final setup = _notificationCubits(const [_wo]);
      await setup.cubit.load();
      addTearDown(() async {
        await setup.cubit.close();
        await setup.unread.close();
        await ti.close();
        await auth.close();
      });

      await tester.pumpWidget(
        _wrap(
          auth: auth,
          ti: ti,
          notifications: setup.cubit,
          unread: setup.unread,
          child: NotificationsPage(cubit: setup.cubit),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('notifications-mobile-app-bar')), findsOneWidget);
      expect(find.byKey(const Key('notifications-desktop-back')), findsNothing);
      expect(find.byType(AppBar), findsOneWidget);
    },
  );

  testWidgets(
    'TI config change while notifications open updates filtering',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final auth = _authCubit(_technician);
      final ti = _tiCubit(
        const TechnicianInterfaceConfig(
          workOrders: true,
          overtime: true,
          profile: true,
        ),
      );
      final setup = _notificationCubits(const [_wo, _update]);
      await setup.cubit.load();
      final search = TextEditingController();
      addTearDown(() async {
        search.dispose();
        await setup.cubit.close();
        await setup.unread.close();
        await ti.close();
        await auth.close();
      });

      await tester.pumpWidget(
        _wrap(
          auth: auth,
          ti: ti,
          notifications: setup.cubit,
          unread: setup.unread,
          child: Scaffold(
            body: NotificationsDesktopView(searchController: search),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('WO Assigned'), findsWidgets);
      expect(find.text('App Update'), findsWidgets);

      ti.seedReady(
        const TechnicianInterfaceConfig(
          workOrders: false,
          overtime: true,
          profile: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('WO Assigned'), findsNothing);
      expect(find.text('App Update'), findsWidgets);

      ti.seedReady(
        const TechnicianInterfaceConfig(
          workOrders: true,
          overtime: true,
          profile: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('WO Assigned'), findsWidgets);
    },
  );

  testWidgets(
    'no TI config yet fails open and shows work order notification',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final auth = _authCubit(_technician);
      final ti = _tiCubit(TechnicianInterfaceConfig.defaults)..seedNotReady();
      final setup = _notificationCubits(const [_wo]);
      await setup.cubit.load();
      final search = TextEditingController();
      addTearDown(() async {
        search.dispose();
        await setup.cubit.close();
        await setup.unread.close();
        await ti.close();
        await auth.close();
      });

      await tester.pumpWidget(
        _wrap(
          auth: auth,
          ti: ti,
          notifications: setup.cubit,
          unread: setup.unread,
          child: Scaffold(
            body: NotificationsDesktopView(searchController: search),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('WO Assigned'), findsWidgets);
      expect(find.byType(NotificationListTile), findsOneWidget);
    },
  );
}
