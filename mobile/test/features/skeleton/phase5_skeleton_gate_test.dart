import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/core/cache/session_query_cache.dart';
import 'package:mobile/core/constants/permissions.dart';
import 'package:mobile/core/geo/gps_snapshot.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/services/auth_session_service.dart';
import 'package:mobile/core/storage/preferences_service.dart';
import 'package:mobile/core/widgets/app_refresh_bar.dart';
import 'package:mobile/core/widgets/skeleton/skeleton.dart';
import 'package:mobile/features/auth/domain/entities/current_user.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobile/features/auth/domain/services/permission_checker.dart';
import 'package:mobile/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:mobile/features/auth/domain/usecases/logout_all_devices_usecase.dart';
import 'package:mobile/features/auth/domain/usecases/logout_usecase.dart';
import 'package:mobile/features/auth/domain/usecases/restore_session_usecase.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/features/global_search/domain/entities/global_search_hit.dart';
import 'package:mobile/features/global_search/domain/repositories/global_search_repository.dart';
import 'package:mobile/features/global_search/domain/usecases/search_globally_usecase.dart';
import 'package:mobile/features/global_search/presentation/cubit/global_search_cubit.dart';
import 'package:mobile/features/global_search/presentation/widgets/global_search_dialog.dart';
import 'package:mobile/features/global_search/presentation/widgets/global_search_results_skeleton.dart';
import 'package:mobile/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:mobile/features/notifications/domain/usecases/notifications_usecases.dart';
import 'package:mobile/features/notifications/presentation/cubit/notifications_unread_cubit.dart';
import 'package:mobile/features/organization/domain/entities/company.dart';
import 'package:mobile/features/organization/domain/entities/organization_context.dart';
import 'package:mobile/features/organization/domain/repositories/organization_repository.dart';
import 'package:mobile/features/organization/presentation/cubit/profile_cubit.dart';
import 'package:mobile/features/organization/presentation/widgets/profile_skeleton.dart';
import 'package:mobile/features/overtime/data/datasources/overtime_local_datasource.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_status.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_technician_summary.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_type.dart';
import 'package:mobile/features/overtime/domain/repositories/overtime_repository.dart';
import 'package:mobile/features/overtime/domain/usecases/list_admin_overtime_usecase.dart';
import 'package:mobile/features/overtime/domain/usecases/list_my_overtime_usecase.dart';
import 'package:mobile/features/overtime/presentation/cubit/overtime_admin_cubit.dart';
import 'package:mobile/features/overtime/presentation/cubit/overtime_history_cubit.dart';
import 'package:mobile/features/overtime/presentation/pages/overtime_admin_page.dart';
import 'package:mobile/features/overtime/presentation/pages/overtime_history_page.dart';
import 'package:mobile/features/overtime/presentation/widgets/overtime_list_skeleton.dart';
import 'package:mobile/features/settings/domain/entities/settings_entities.dart';
import 'package:mobile/features/settings/domain/repositories/settings_repository.dart';
import 'package:mobile/features/settings/domain/usecases/settings_usecases.dart';
import 'package:mobile/features/settings/presentation/cubit/settings_cubits.dart';
import 'package:mobile/features/settings/presentation/pages/organization_settings_page.dart';
import 'package:mobile/features/settings/presentation/pages/settings_hub_page.dart';
import 'package:mobile/features/settings/presentation/widgets/settings_form_skeleton.dart';
import 'package:mobile/shared/presentation/pages/profile_page.dart';

class _FakeAuthRepo extends Fake implements AuthRepository {}

class _FakeOrgRepo extends Fake implements OrganizationRepository {}

class _FakeSettingsRepo extends Fake implements SettingsRepository {}

class _FakeSearchRepo extends Fake implements GlobalSearchRepository {}

class _FakeNotifRepo extends Fake implements NotificationsRepository {}

class _FakeOtRepo extends Fake implements OvertimeRepository {}

class _TestProfileCubit extends ProfileCubit {
  _TestProfileCubit(ProfileState initial)
      : super(
          repository: _FakeOrgRepo(),
          sessionQueryCache: SessionQueryCache(),
        ) {
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    emit(initial);
  }
}

class _TestOrgSettingsCubit extends OrganizationSettingsCubit {
  _TestOrgSettingsCubit(OrganizationSettingsState initial)
      : super(
          getSettings: GetOrganizationSettingsUseCase(_FakeSettingsRepo()),
          updateSettings:
              UpdateOrganizationSettingsUseCase(_FakeSettingsRepo()),
          uploadLogo: UploadOrganizationLogoUseCase(_FakeSettingsRepo()),
          sessionQueryCache: SessionQueryCache(),
        ) {
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    emit(initial);
  }
}

class _TestSearchCubit extends GlobalSearchCubit {
  _TestSearchCubit(GlobalSearchState initial)
      : super(
          searchGlobally: SearchGloballyUseCase(_FakeSearchRepo()),
          permissionsProvider: () => const PermissionChecker([]),
        ) {
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    emit(initial);
  }
}

class _TestHistoryCubit extends OvertimeHistoryCubit {
  _TestHistoryCubit(
    OvertimeHistoryState initial,
    OvertimeLocalDataSource local,
  ) : super(
          listMine: ListMyOvertimeUseCase(_FakeOtRepo()),
          sessionQueryCache: SessionQueryCache(),
          localDataSource: local,
        ) {
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    emit(initial);
  }
}

class _TestAdminCubit extends OvertimeAdminCubit {
  _TestAdminCubit(OvertimeAdminState initial)
      : super(
          listAdmin: ListAdminOvertimeUseCase(_FakeOtRepo()),
          sessionQueryCache: SessionQueryCache(),
        ) {
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    emit(initial);
  }
}

const _orgSettings = OrganizationSettings(
  id: 'o1',
  name: 'Acme FSM',
  slug: 'acme',
  workingHours: WorkingHoursSettings(
    start: '08:00',
    end: '17:00',
    timezone: 'Asia/Riyadh',
  ),
  address: CompanyAddressSettings(city: 'Riyadh'),
);

final _gps = GpsSnapshot(
  latitude: 24.7,
  longitude: 46.7,
  accuracy: 8,
  recordedAt: DateTime.utc(2026, 1, 2, 8),
);

OvertimeSession _session({
  String id = 'ot1',
  String techName = 'Pat Field',
}) {
  return OvertimeSession(
    id: id,
    companyId: 'c1',
    userId: 'u1',
    type: OvertimeType.normal,
    status: OvertimeStatus.approved,
    startAt: DateTime.utc(2026, 1, 2, 8),
    startGps: _gps,
    startDeviceId: 'dev-1',
    technician: OvertimeTechnicianSummary(
      id: 'u1',
      fullName: techName,
    ),
  );
}

void main() {
  late AuthCubit authCubit;
  late AuthSessionService session;
  late NotificationsUnreadCubit unreadCubit;
  late OvertimeLocalDataSource overtimeLocal;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    overtimeLocal = OvertimeLocalDataSource(
      PreferencesService(await SharedPreferences.getInstance()),
    );
  });

  setUp(() {
    session = AuthSessionService();
    final fake = _FakeAuthRepo();
    authCubit = AuthCubit(
      restoreSessionUseCase: RestoreSessionUseCase(fake),
      getCurrentUserUseCase: GetCurrentUserUseCase(fake),
      logoutUseCase: LogoutUseCase(fake),
      logoutAllDevicesUseCase: LogoutAllDevicesUseCase(fake),
      authSessionService: session,
      sessionQueryCache: SessionQueryCache(),
    );
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    authCubit.emit(
      const AuthState(
        status: AuthStatus.authenticated,
        user: CurrentUser(
          id: 'a1',
          companyId: 'c1',
          email: 'a@x.com',
          firstName: 'A',
          lastName: 'B',
          fullName: 'A B',
          roles: ['ADMIN'],
          permissions: [
            Permissions.overtimeViewAll,
            Permissions.settingsManage,
          ],
        ),
      ),
    );
    unreadCubit = NotificationsUnreadCubit(
      getUnreadCount: GetNotificationsUnreadCountUseCase(_FakeNotifRepo()),
      repository: _FakeNotifRepo(),
    );
  });

  tearDown(() async {
    await unreadCubit.close();
    await authCubit.close();
    session.dispose();
  });

  Future<void> pumpPage(
    WidgetTester tester,
    Widget page, {
    double width = 400,
    TextDirection direction = TextDirection.ltr,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Directionality(
          textDirection: direction,
          child: MediaQuery(
            data: MediaQueryData(size: Size(width, 2200)),
            child: MultiBlocProvider(
              providers: [
                BlocProvider<AuthCubit>.value(value: authCubit),
                BlocProvider<NotificationsUnreadCubit>.value(
                  value: unreadCubit,
                ),
              ],
              child: page,
            ),
          ),
        ),
      ),
    );
  }

  group('Profile gates', () {
    testWidgets('initial no-data shows skeleton', (tester) async {
      final cubit = _TestProfileCubit(
        const ProfileState(status: ProfileStatus.loading),
      );
      addTearDown(cubit.close);
      await pumpPage(tester, ProfilePage(debugCubit: cubit));
      await tester.pump();
      expect(find.byType(ProfileSkeleton), findsOneWidget);
    });

    testWidgets('cached profile remains during refresh', (tester) async {
      final cubit = _TestProfileCubit(
        const ProfileState(
          status: ProfileStatus.success,
          isRefreshing: true,
          context: OrganizationContext(
            company: Company(
              id: 'c1',
              code: 'ACM',
              name: 'Acme',
              status: 'ACTIVE',
            ),
          ),
        ),
      );
      addTearDown(cubit.close);
      await pumpPage(tester, ProfilePage(debugCubit: cubit));
      await tester.pump();
      expect(find.byType(ProfileSkeleton), findsNothing);
      expect(find.text('Acme'), findsOneWidget);
      expect(find.byType(AppRefreshBar), findsOneWidget);
    });

    testWidgets('desktop and RTL keep content on refresh', (tester) async {
      final cubit = _TestProfileCubit(
        const ProfileState(
          status: ProfileStatus.success,
          isRefreshing: true,
          context: OrganizationContext(
            company: Company(
              id: 'c1',
              code: 'ACM',
              name: 'Acme',
              status: 'ACTIVE',
            ),
          ),
        ),
      );
      addTearDown(cubit.close);
      await pumpPage(
        tester,
        ProfilePage(debugCubit: cubit),
        width: 900,
        direction: TextDirection.rtl,
      );
      await tester.pump();
      expect(find.byType(ProfileSkeleton), findsNothing);
      expect(find.text('Acme'), findsOneWidget);
    });

    testWidgets('failure without org shows content not skeleton', (tester) async {
      final cubit = _TestProfileCubit(
        const ProfileState(status: ProfileStatus.failure, message: 'ERR'),
      );
      addTearDown(cubit.close);
      await pumpPage(tester, ProfilePage(debugCubit: cubit));
      await tester.pump();
      expect(find.byType(ProfileSkeleton), findsNothing);
    });
  });

  group('Settings gates', () {
    testWidgets('hub stays static with no form skeleton', (tester) async {
      await pumpPage(tester, const SettingsHubPage());
      await tester.pump();
      expect(find.byType(SettingsFormSkeleton), findsNothing);
      expect(find.text('Language'), findsWidgets);
    });

    testWidgets('org settings first-load skeleton', (tester) async {
      final cubit = _TestOrgSettingsCubit(
        const OrganizationSettingsState(
          status: OrganizationSettingsStatus.loading,
        ),
      );
      addTearDown(cubit.close);
      await pumpPage(
        tester,
        OrganizationSettingsPage(debugCubit: cubit),
      );
      await tester.pump();
      expect(find.byType(SettingsFormSkeleton), findsOneWidget);
    });

    testWidgets('org settings save uses progress not skeleton', (tester) async {
      final cubit = _TestOrgSettingsCubit(
        const OrganizationSettingsState(
          status: OrganizationSettingsStatus.saving,
          settings: _orgSettings,
        ),
      );
      addTearDown(cubit.close);
      expect(cubit.state.status, OrganizationSettingsStatus.saving);
      await pumpPage(
        tester,
        OrganizationSettingsPage(debugCubit: cubit),
      );
      await tester.pump();
      expect(find.byType(SettingsFormSkeleton), findsNothing);
      expect(find.byType(Form), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsWidgets);
    });
  });

  group('Global Search gates', () {
    Future<void> pumpSearch(
      WidgetTester tester,
      GlobalSearchCubit cubit, {
      double width = 400,
      TextDirection direction = TextDirection.ltr,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Directionality(
            textDirection: direction,
            child: MediaQuery(
              data: MediaQueryData(size: Size(width, 900)),
              child: BlocProvider<GlobalSearchCubit>.value(
                value: cubit,
                child: const GlobalSearchDialog(),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('first query loading with no hits shows results skeleton',
        (tester) async {
      final cubit = _TestSearchCubit(
        const GlobalSearchState(
          status: GlobalSearchStatus.loading,
          query: 'wo',
        ),
      );
      addTearDown(cubit.close);
      await pumpSearch(tester, cubit);
      await tester.pump();
      expect(find.byType(GlobalSearchResultsSkeleton), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(SkeletonListTile), findsNWidgets(6));
    });

    testWidgets('existing hits remain during new search', (tester) async {
      final cubit = _TestSearchCubit(
        const GlobalSearchState(
          status: GlobalSearchStatus.loading,
          query: 'pump',
          hits: [
            GlobalSearchHit(
              id: 'wo1',
              module: GlobalSearchModule.workOrders,
              title: 'WO-100',
              route: '/work-orders/wo1',
            ),
          ],
        ),
      );
      addTearDown(cubit.close);
      await pumpSearch(tester, cubit);
      await tester.pump();
      expect(find.byType(GlobalSearchResultsSkeleton), findsNothing);
      expect(find.text('WO-100'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('empty results use existing empty copy', (tester) async {
      final cubit = _TestSearchCubit(
        const GlobalSearchState(
          status: GlobalSearchStatus.ready,
          query: 'zz',
        ),
      );
      addTearDown(cubit.close);
      await pumpSearch(tester, cubit);
      await tester.pump();
      expect(find.byType(GlobalSearchResultsSkeleton), findsNothing);
      expect(find.text('No results found.'), findsOneWidget);
    });

    testWidgets('error uses existing failure copy', (tester) async {
      final cubit = _TestSearchCubit(
        const GlobalSearchState(
          status: GlobalSearchStatus.failure,
          query: 'wo',
          message: 'boom',
        ),
      );
      addTearDown(cubit.close);
      await pumpSearch(tester, cubit);
      await tester.pump();
      expect(find.byType(GlobalSearchResultsSkeleton), findsNothing);
      expect(find.text('boom'), findsOneWidget);
    });

    testWidgets('desktop RTL loading skeleton keeps field', (tester) async {
      final cubit = _TestSearchCubit(
        const GlobalSearchState(
          status: GlobalSearchStatus.loading,
          query: 'as',
        ),
      );
      addTearDown(cubit.close);
      await pumpSearch(
        tester,
        cubit,
        width: 900,
        direction: TextDirection.rtl,
      );
      await tester.pump();
      expect(find.byType(GlobalSearchResultsSkeleton), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });
  });

  group('Overtime history/admin gates', () {
    testWidgets('history first-load skeleton', (tester) async {
      final cubit = _TestHistoryCubit(
        const OvertimeHistoryState(status: OvertimeHistoryStatus.loading),
        overtimeLocal,
      );
      addTearDown(cubit.close);
      await pumpPage(tester, OvertimeHistoryPage(debugCubit: cubit));
      await tester.pump();
      expect(find.byType(OvertimeListSkeleton), findsOneWidget);
    });

    testWidgets('history refresh keeps existing cards', (tester) async {
      final cubit = _TestHistoryCubit(
        OvertimeHistoryState(
          status: OvertimeHistoryStatus.loading,
          isRefreshing: true,
          items: [_session(id: 'local-ot1')],
        ),
        overtimeLocal,
      );
      addTearDown(cubit.close);
      await pumpPage(tester, OvertimeHistoryPage(debugCubit: cubit));
      await tester.pump();
      expect(find.byType(OvertimeListSkeleton), findsNothing);
      expect(find.text('Normal Overtime'), findsOneWidget);
    });

    testWidgets('history empty uses existing empty copy', (tester) async {
      final cubit = _TestHistoryCubit(
        const OvertimeHistoryState(status: OvertimeHistoryStatus.success),
        overtimeLocal,
      );
      addTearDown(cubit.close);
      await pumpPage(tester, OvertimeHistoryPage(debugCubit: cubit));
      await tester.pump();
      expect(find.byType(OvertimeListSkeleton), findsNothing);
      expect(find.text('No overtime history yet.'), findsOneWidget);
    });

    testWidgets('history error uses retry', (tester) async {
      final cubit = _TestHistoryCubit(
        const OvertimeHistoryState(
          status: OvertimeHistoryStatus.failure,
          message: 'down',
        ),
        overtimeLocal,
      );
      addTearDown(cubit.close);
      await pumpPage(tester, OvertimeHistoryPage(debugCubit: cubit));
      await tester.pump();
      expect(find.byType(OvertimeListSkeleton), findsNothing);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('admin first-load skeleton keeps search chrome', (tester) async {
      final cubit = _TestAdminCubit(
        const OvertimeAdminState(status: OvertimeAdminStatus.loading),
      );
      addTearDown(cubit.close);
      await pumpPage(tester, OvertimeAdminPage(debugCubit: cubit));
      await tester.pump();
      expect(find.byType(OvertimeListSkeleton), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('admin records remain during refresh', (tester) async {
      final cubit = _TestAdminCubit(
        OvertimeAdminState(
          status: OvertimeAdminStatus.success,
          isRefreshing: true,
          items: [_session()],
        ),
      );
      addTearDown(cubit.close);
      await pumpPage(
        tester,
        OvertimeAdminPage(debugCubit: cubit),
        width: 900,
      );
      await tester.pump();
      expect(find.byType(OvertimeListSkeleton), findsNothing);
      expect(find.text('Pat Field'), findsOneWidget);
      expect(find.byType(AppRefreshBar), findsOneWidget);
    });

    testWidgets('admin empty and desktop RTL', (tester) async {
      final cubit = _TestAdminCubit(
        const OvertimeAdminState(status: OvertimeAdminStatus.success),
      );
      addTearDown(cubit.close);
      await pumpPage(
        tester,
        OvertimeAdminPage(debugCubit: cubit),
        width: 900,
        direction: TextDirection.rtl,
      );
      await tester.pump();
      expect(find.byType(OvertimeListSkeleton), findsNothing);
      expect(find.text('No overtime sessions found.'), findsOneWidget);
    });

    testWidgets('admin error uses retry', (tester) async {
      final cubit = _TestAdminCubit(
        const OvertimeAdminState(status: OvertimeAdminStatus.failure),
      );
      addTearDown(cubit.close);
      await pumpPage(tester, OvertimeAdminPage(debugCubit: cubit));
      await tester.pump();
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
