import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/cache/session_query_cache.dart';
import 'package:mobile/core/constants/permissions.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/services/auth_session_service.dart';
import 'package:mobile/core/widgets/app_loader.dart';
import 'package:mobile/core/widgets/app_refresh_bar.dart';
import 'package:mobile/features/assets/domain/repositories/assets_repository.dart';
import 'package:mobile/features/assets/domain/usecases/assets_usecases.dart';
import 'package:mobile/features/auth/domain/entities/current_user.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobile/features/auth/domain/services/permission_checker.dart';
import 'package:mobile/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:mobile/features/auth/domain/usecases/logout_all_devices_usecase.dart';
import 'package:mobile/features/auth/domain/usecases/logout_usecase.dart';
import 'package:mobile/features/auth/domain/usecases/restore_session_usecase.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:mobile/features/inventory/domain/usecases/spare_part_usecases.dart';
import 'package:mobile/features/overtime/domain/repositories/overtime_repository.dart';
import 'package:mobile/features/overtime/domain/usecases/list_admin_overtime_usecase.dart';
import 'package:mobile/features/pm/domain/repositories/pm_repository.dart';
import 'package:mobile/features/pm/domain/usecases/pm_usecases.dart';
import 'package:mobile/features/reports_center/domain/entities/report_list_row.dart';
import 'package:mobile/features/reports_center/domain/entities/reports_center_module.dart';
import 'package:mobile/features/reports_center/presentation/cubit/reports_center_cubit.dart';
import 'package:mobile/features/reports_center/presentation/pages/reports_center_page.dart';
import 'package:mobile/features/reports_center/presentation/widgets/reports_center_results_skeleton.dart';
import 'package:mobile/features/reports_center/presentation/widgets/reports_center_widgets.dart';
import 'package:mobile/features/roles/domain/entities/role_entities.dart';
import 'package:mobile/features/roles/domain/repositories/roles_repository.dart';
import 'package:mobile/features/roles/domain/usecases/roles_usecases.dart';
import 'package:mobile/features/roles/presentation/cubit/roles_cubits.dart';
import 'package:mobile/features/roles/presentation/pages/role_detail_page.dart';
import 'package:mobile/features/roles/presentation/pages/role_form_page.dart';
import 'package:mobile/features/roles/presentation/pages/roles_dashboard_page.dart';
import 'package:mobile/features/roles/presentation/pages/roles_list_page.dart';
import 'package:mobile/features/roles/presentation/widgets/roles_permissions_skeleton.dart';
import 'package:mobile/features/service_reports/domain/entities/service_report_entities.dart';
import 'package:mobile/features/service_reports/domain/repositories/service_reports_repository.dart';
import 'package:mobile/features/service_reports/domain/usecases/service_reports_usecases.dart';
import 'package:mobile/features/service_reports/presentation/cubit/service_reports_cubits.dart';
import 'package:mobile/features/service_reports/presentation/pages/service_report_detail_page.dart';
import 'package:mobile/features/service_reports/presentation/pages/service_reports_dashboard_page.dart';
import 'package:mobile/features/service_reports/presentation/pages/service_reports_list_page.dart';
import 'package:mobile/features/service_reports/presentation/widgets/service_reports_skeleton.dart';
import 'package:mobile/features/users/domain/entities/user_management_entities.dart';
import 'package:mobile/features/users/domain/repositories/users_repository.dart';
import 'package:mobile/features/users/domain/usecases/users_usecases.dart';
import 'package:mobile/features/users/presentation/cubit/users_cubits.dart';
import 'package:mobile/features/users/presentation/pages/user_detail_page.dart';
import 'package:mobile/features/users/presentation/pages/users_dashboard_page.dart';
import 'package:mobile/features/users/presentation/pages/users_list_page.dart';
import 'package:mobile/features/users/presentation/widgets/user_management_skeleton.dart';
import 'package:mobile/features/work_orders/domain/repositories/work_order_repository.dart';
import 'package:mobile/features/work_orders/domain/usecases/list_my_work_orders_usecase.dart';
import 'package:mobile/features/work_orders/domain/usecases/list_work_orders_usecase.dart';

class _FakeAuthRepo extends Fake implements AuthRepository {}

class _FakeUsersRepo extends Fake implements UsersRepository {}

class _FakeRolesRepo extends Fake implements RolesRepository {}

class _FakeSrRepo extends Fake implements ServiceReportsRepository {}

class _FakeOtRepo extends Fake implements OvertimeRepository {}

class _FakeWoRepo extends Fake implements WorkOrderRepository {}

class _FakeAssetsRepo extends Fake implements AssetsRepository {}

class _FakeInvRepo extends Fake implements InventoryRepository {}

class _FakePmRepo extends Fake implements PmRepository {}

const _user = ManagedUser(
  id: 'u1',
  email: 'jane@x.com',
  firstName: 'Jane',
  lastName: 'Doe',
  fullName: 'Jane Doe',
  status: ManagedUserStatus.active,
  roles: ['TECHNICIAN'],
);

const _role = RoleEntity(
  id: 'r1',
  name: 'Field Lead',
  slug: 'field-lead',
  permissions: ['reports:view'],
  isSystem: false,
  isActive: true,
);

const _report = ServiceReport(
  id: 'sr1',
  reportNumber: 'SR-100',
  status: ServiceReportStatus.generated,
  reportQrCode: 'qr',
);

const _usersDash = UsersDashboard(
  totalUsers: 4,
  activeUsers: 3,
  disabledUsers: 1,
  lockedUsers: 0,
);

const _rolesDash = RolesDashboard(
  totalRoles: 6,
  activeRoles: 5,
  systemRoles: 2,
  customRoles: 4,
);

const _srDash = ServiceReportsDashboard(
  totalReports: 8,
  generated: 5,
  downloaded: 3,
  totalSignatures: 2,
);

class _TestUsersDashboardCubit extends UsersDashboardCubit {
  _TestUsersDashboardCubit(UsersDashboardState initial)
      : super(
          getDashboard: GetUsersDashboardUseCase(_FakeUsersRepo()),
          queryCache: SessionQueryCache(),
        ) {
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    emit(initial);
  }
}

class _TestUsersListCubit extends UsersListCubit {
  _TestUsersListCubit(UsersListState initial)
      : super(
          listUsers: ListManagedUsersUseCase(_FakeUsersRepo()),
          queryCache: SessionQueryCache(),
        ) {
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    emit(initial);
  }
}

class _TestUserDetailCubit extends UserDetailCubit {
  _TestUserDetailCubit(UserDetailState initial)
      : super(
          userId: 'u1',
          getById: GetManagedUserByIdUseCase(_FakeUsersRepo()),
          setStatus: SetManagedUserStatusUseCase(_FakeUsersRepo()),
          deleteUser: DeleteManagedUserUseCase(_FakeUsersRepo()),
          resetPassword: ResetManagedUserPasswordUseCase(_FakeUsersRepo()),
          uploadAvatar: UploadUserAvatarUseCase(_FakeUsersRepo()),
          queryCache: SessionQueryCache(),
        ) {
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    emit(initial);
  }
}

class _TestRolesDashboardCubit extends RolesDashboardCubit {
  _TestRolesDashboardCubit(RolesDashboardState initial)
      : super(
          getDashboard: GetRolesDashboardUseCase(_FakeRolesRepo()),
          queryCache: SessionQueryCache(),
        ) {
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    emit(initial);
  }
}

class _TestRolesListCubit extends RolesListCubit {
  _TestRolesListCubit(RolesListState initial)
      : super(
          listRoles: ListRolesUseCase(_FakeRolesRepo()),
          queryCache: SessionQueryCache(),
        ) {
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    emit(initial);
  }
}

class _TestRoleDetailCubit extends RoleDetailCubit {
  _TestRoleDetailCubit(RoleDetailState initial)
      : super(
          getRole: GetRoleByIdUseCase(_FakeRolesRepo()),
          listUsers: ListRoleUsersUseCase(_FakeRolesRepo()),
          setStatus: SetRoleStatusUseCase(_FakeRolesRepo()),
          deleteRole: DeleteRoleUseCase(_FakeRolesRepo()),
          cloneRole: CloneRoleUseCase(_FakeRolesRepo()),
          queryCache: SessionQueryCache(),
        ) {
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    emit(initial);
  }
}

class _TestRoleFormCubit extends RoleFormCubit {
  _TestRoleFormCubit(RoleFormState initial)
      : super(
          getRole: GetRoleByIdUseCase(_FakeRolesRepo()),
          getCatalog: GetPermissionCatalogUseCase(_FakeRolesRepo()),
          createRole: CreateRoleUseCase(_FakeRolesRepo()),
          updateRole: UpdateRoleUseCase(_FakeRolesRepo()),
        ) {
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    emit(initial);
  }
}

class _TestSrDashboardCubit extends ServiceReportsDashboardCubit {
  _TestSrDashboardCubit(ServiceReportsDashboardState initial)
      : super(
          getDashboard: GetServiceReportsDashboardUseCase(_FakeSrRepo()),
          queryCache: SessionQueryCache(),
        ) {
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    emit(initial);
  }
}

class _TestSrListCubit extends ServiceReportsListCubit {
  _TestSrListCubit(ServiceReportsListState initial)
      : super(
          listReports: ListServiceReportsUseCase(_FakeSrRepo()),
          queryCache: SessionQueryCache(),
        ) {
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    emit(initial);
  }
}

class _TestSrDetailCubit extends ServiceReportDetailCubit {
  _TestSrDetailCubit(ServiceReportDetailState initial)
      : super(
          reportId: 'sr1',
          getById: GetServiceReportByIdUseCase(_FakeSrRepo()),
          download: DownloadServiceReportUseCase(_FakeSrRepo()),
          queryCache: SessionQueryCache(),
        ) {
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    emit(initial);
  }
}

class _TestReportsCenterCubit extends ReportsCenterCubit {
  _TestReportsCenterCubit(ReportsCenterState initial)
      : super(
          permissions: const PermissionChecker([]),
          listOvertime: ListAdminOvertimeUseCase(_FakeOtRepo()),
          listWorkOrders: ListWorkOrdersUseCase(_FakeWoRepo()),
          listMyWorkOrders: ListMyWorkOrdersUseCase(_FakeWoRepo()),
          listAssets: ListAssetsUseCase(_FakeAssetsRepo()),
          listSpareParts: ListSparePartsUseCase(_FakeInvRepo()),
          listPmPlans: ListPmPlansUseCase(_FakePmRepo()),
          listServiceReports: ListServiceReportsUseCase(_FakeSrRepo()),
          listUsers: ListManagedUsersUseCase(_FakeUsersRepo()),
        ) {
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    emit(initial);
  }

  void setState(ReportsCenterState next) {
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    emit(next);
  }
}

void main() {
  late AuthCubit authCubit;
  late AuthSessionService session;

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
          permissions: [Permissions.overtimeViewAll],
        ),
      ),
    );
  });

  tearDown(() async {
    await authCubit.close();
    session.dispose();
  });

  Future<void> pumpPage(
    WidgetTester tester,
    Widget page, {
    double width = 400,
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
        home: MediaQuery(
          data: MediaQueryData(size: Size(width, 2200)),
          child: BlocProvider<AuthCubit>.value(
            value: authCubit,
            child: page,
          ),
        ),
      ),
    );
  }

  group('Users dashboard gates', () {
    testWidgets('initial no-data shows skeleton', (tester) async {
      final cubit = _TestUsersDashboardCubit(
        const UsersDashboardState(status: UsersDashboardStatus.loading),
      );
      addTearDown(cubit.close);
      await pumpPage(tester, UsersDashboardPage(debugCubit: cubit));
      await tester.pump();
      expect(find.byType(UserManagementSkeleton), findsOneWidget);
      expect(find.byType(AppLoader), findsNothing);
    });

    testWidgets('refresh with data keeps content', (tester) async {
      final cubit = _TestUsersDashboardCubit(
        const UsersDashboardState(
          status: UsersDashboardStatus.success,
          dashboard: _usersDash,
          isRefreshing: true,
        ),
      );
      addTearDown(cubit.close);
      await pumpPage(tester, UsersDashboardPage(debugCubit: cubit));
      await tester.pump();
      expect(find.byType(UserManagementSkeleton), findsNothing);
      expect(find.byType(AppRefreshBar), findsOneWidget);
      expect(find.text('Total users'), findsOneWidget);
    });

    testWidgets('error with no data shows retry', (tester) async {
      final cubit = _TestUsersDashboardCubit(
        const UsersDashboardState(
          status: UsersDashboardStatus.failure,
          message: 'failed',
        ),
      );
      addTearDown(cubit.close);
      await pumpPage(tester, UsersDashboardPage(debugCubit: cubit));
      await tester.pump();
      expect(find.byType(UserManagementSkeleton), findsNothing);
      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('Users list and detail gates', () {
    testWidgets('list initial no-data shows skeleton', (tester) async {
      final cubit = _TestUsersListCubit(
        const UsersListState(status: UsersListStatus.loading),
      );
      addTearDown(cubit.close);
      await pumpPage(tester, UsersListPage(debugCubit: cubit));
      await tester.pump();
      expect(find.byType(UserManagementSkeleton), findsOneWidget);
      expect(find.byType(AppLoader), findsNothing);
    });

    testWidgets('list refresh with data keeps row', (tester) async {
      final cubit = _TestUsersListCubit(
        const UsersListState(
          status: UsersListStatus.success,
          items: [_user],
          isRefreshing: true,
        ),
      );
      addTearDown(cubit.close);
      await pumpPage(tester, UsersListPage(debugCubit: cubit));
      await tester.pump();
      expect(find.byType(UserManagementSkeleton), findsNothing);
      expect(find.text('Jane Doe'), findsOneWidget);
    });

    testWidgets('list empty shows empty copy', (tester) async {
      final empty = _TestUsersListCubit(
        const UsersListState(status: UsersListStatus.success),
      );
      addTearDown(empty.close);
      await pumpPage(tester, UsersListPage(debugCubit: empty));
      await tester.pump();
      expect(find.text('No users found'), findsOneWidget);
    });

    testWidgets('list error with no data shows retry', (tester) async {
      final failed = _TestUsersListCubit(
        const UsersListState(
          status: UsersListStatus.failure,
          message: 'failed',
        ),
      );
      addTearDown(failed.close);
      await pumpPage(tester, UsersListPage(debugCubit: failed));
      await tester.pump();
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('detail loading shows skeleton', (tester) async {
      final loading = _TestUserDetailCubit(
        const UserDetailState(status: UserDetailStatus.loading),
      );
      addTearDown(loading.close);
      await pumpPage(
        tester,
        UserDetailPage(userId: 'u1', debugCubit: loading),
      );
      await tester.pump();
      expect(find.byType(UserManagementSkeleton), findsOneWidget);
    });

    testWidgets('detail refresh keeps user', (tester) async {
      final ready = _TestUserDetailCubit(
        const UserDetailState(
          status: UserDetailStatus.success,
          user: _user,
          isRefreshing: true,
        ),
      );
      addTearDown(ready.close);
      await pumpPage(
        tester,
        UserDetailPage(userId: 'u1', debugCubit: ready),
      );
      await tester.pump();
      expect(find.byType(UserManagementSkeleton), findsNothing);
      expect(find.byType(AppRefreshBar), findsOneWidget);
      expect(find.text('Jane Doe'), findsWidgets);
    });

    testWidgets('detail error with no data shows retry', (tester) async {
      final cubit = _TestUserDetailCubit(
        const UserDetailState(
          status: UserDetailStatus.failure,
          message: 'failed',
        ),
      );
      addTearDown(cubit.close);
      await pumpPage(
        tester,
        UserDetailPage(userId: 'u1', debugCubit: cubit),
      );
      await tester.pump();
      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('Reports Center result-area gates', () {
    ReportsCenterState loadingState() => const ReportsCenterState(
          status: ReportsCenterStatus.loading,
          module: ReportsCenterModule.serviceReports,
          availableModules: [
            ReportsCenterModule.serviceReports,
            ReportsCenterModule.overtime,
          ],
        );

    testWidgets('first load skeletons results only and keeps chrome',
        (tester) async {
      final cubit = _TestReportsCenterCubit(loadingState());
      addTearDown(cubit.close);
      await pumpPage(tester, ReportsCenterPage(debugCubit: cubit));
      await tester.pump();
      expect(find.byType(ReportsCenterResultsSkeleton), findsOneWidget);
      expect(find.byType(ReportsCenterFilterBar), findsOneWidget);
      expect(find.text('Reports Center'), findsOneWidget);
      expect(find.text('Service Reports'), findsOneWidget);
      expect(find.text('Filters'), findsOneWidget);
      expect(find.byType(AppLoader), findsNothing);
    });

    testWidgets('desktop first load still keeps filters', (tester) async {
      final cubit = _TestReportsCenterCubit(
        const ReportsCenterState(
          status: ReportsCenterStatus.loading,
          module: ReportsCenterModule.overtime,
          availableModules: [ReportsCenterModule.overtime],
        ),
      );
      addTearDown(cubit.close);
      await pumpPage(
        tester,
        ReportsCenterPage(debugCubit: cubit),
        width: 900,
      );
      await tester.pump();
      expect(find.byType(ReportsCenterResultsSkeleton), findsOneWidget);
      expect(find.byType(ReportsCenterFilterBar), findsOneWidget);
    });

    testWidgets('overtime loading keeps export control', (tester) async {
      final cubit = _TestReportsCenterCubit(
        const ReportsCenterState(
          status: ReportsCenterStatus.loading,
          module: ReportsCenterModule.overtime,
          availableModules: [ReportsCenterModule.overtime],
        ),
      );
      addTearDown(cubit.close);
      await pumpPage(tester, ReportsCenterPage(debugCubit: cubit));
      await tester.pump();
      expect(find.byType(ReportsCenterResultsSkeleton), findsOneWidget);
      expect(find.text('Export Excel'), findsOneWidget);
    });

    testWidgets('refresh with rows keeps table/list', (tester) async {
      const row = ReportListRow(
        id: 'row1',
        module: ReportsCenterModule.serviceReports,
        title: 'Site visit SR-100',
        route: '/reports/sr1',
      );
      final cubit = _TestReportsCenterCubit(
        const ReportsCenterState(
          status: ReportsCenterStatus.ready,
          module: ReportsCenterModule.serviceReports,
          availableModules: [ReportsCenterModule.serviceReports],
          rows: [row],
          isRefreshing: true,
        ),
      );
      addTearDown(cubit.close);
      await pumpPage(tester, ReportsCenterPage(debugCubit: cubit));
      await tester.pump();
      expect(find.byType(ReportsCenterResultsSkeleton), findsNothing);
      expect(find.text('Site visit SR-100'), findsOneWidget);
      expect(find.byType(AppRefreshBar), findsOneWidget);
      cubit.setState(
        const ReportsCenterState(
          status: ReportsCenterStatus.ready,
          module: ReportsCenterModule.serviceReports,
          availableModules: [ReportsCenterModule.serviceReports],
          rows: [row],
        ),
      );
      await tester.pump();
      expect(find.byType(ReportsCenterResultsSkeleton), findsNothing);
      expect(find.text('Site visit SR-100'), findsOneWidget);
    });

    testWidgets('loaded empty shows module empty copy', (tester) async {
      final empty = _TestReportsCenterCubit(
        const ReportsCenterState(
          status: ReportsCenterStatus.ready,
          module: ReportsCenterModule.serviceReports,
          availableModules: [ReportsCenterModule.serviceReports],
        ),
      );
      addTearDown(empty.close);
      await pumpPage(tester, ReportsCenterPage(debugCubit: empty));
      await tester.pump();
      expect(
        find.text('No service reports found for the selected filters.'),
        findsOneWidget,
      );
    });

    testWidgets('failure with no rows shows load failed', (tester) async {
      final failed = _TestReportsCenterCubit(
        const ReportsCenterState(
          status: ReportsCenterStatus.failure,
          module: ReportsCenterModule.serviceReports,
          availableModules: [ReportsCenterModule.serviceReports],
          message: 'failed',
        ),
      );
      addTearDown(failed.close);
      await pumpPage(tester, ReportsCenterPage(debugCubit: failed));
      await tester.pump();
      expect(find.text('Unable to load report data.'), findsOneWidget);
    });
  });

  group('Service Reports gates', () {
    testWidgets('dashboard loading skeleton', (tester) async {
      final cubit = _TestSrDashboardCubit(
        const ServiceReportsDashboardState(
          status: ServiceReportsDashboardStatus.loading,
        ),
      );
      addTearDown(cubit.close);
      await pumpPage(tester, ServiceReportsDashboardPage(debugCubit: cubit));
      await tester.pump();
      expect(find.byType(ServiceReportsSkeleton), findsOneWidget);
      expect(find.byType(AppLoader), findsNothing);
    });

    testWidgets('dashboard refresh keeps stats', (tester) async {
      final cubit = _TestSrDashboardCubit(
        const ServiceReportsDashboardState(
          status: ServiceReportsDashboardStatus.success,
          dashboard: _srDash,
          isRefreshing: true,
        ),
      );
      addTearDown(cubit.close);
      await pumpPage(tester, ServiceReportsDashboardPage(debugCubit: cubit));
      await tester.pump();
      expect(find.byType(ServiceReportsSkeleton), findsNothing);
      expect(find.byType(AppRefreshBar), findsOneWidget);
      expect(find.text('Total reports'), findsOneWidget);
    });

    testWidgets('list loading shows skeleton', (tester) async {
      final loading = _TestSrListCubit(
        const ServiceReportsListState(
          status: ServiceReportsListStatus.loading,
        ),
      );
      addTearDown(loading.close);
      await pumpPage(tester, ServiceReportsListPage(debugCubit: loading));
      await tester.pump();
      expect(find.byType(ServiceReportsSkeleton), findsOneWidget);
    });

    testWidgets('list refresh keeps row', (tester) async {
      final ready = _TestSrListCubit(
        const ServiceReportsListState(
          status: ServiceReportsListStatus.success,
          items: [_report],
          isRefreshing: true,
        ),
      );
      addTearDown(ready.close);
      await pumpPage(tester, ServiceReportsListPage(debugCubit: ready));
      await tester.pump();
      expect(find.byType(ServiceReportsSkeleton), findsNothing);
      expect(find.text('SR-100'), findsOneWidget);
    });

    testWidgets('list empty shows empty copy', (tester) async {
      final empty = _TestSrListCubit(
        const ServiceReportsListState(
          status: ServiceReportsListStatus.success,
        ),
      );
      addTearDown(empty.close);
      await pumpPage(tester, ServiceReportsListPage(debugCubit: empty));
      await tester.pump();
      expect(find.text('No service reports yet'), findsOneWidget);
    });

    testWidgets('detail loading shows skeleton', (tester) async {
      final loading = _TestSrDetailCubit(
        const ServiceReportDetailState(
          status: ServiceReportDetailStatus.loading,
        ),
      );
      addTearDown(loading.close);
      await pumpPage(
        tester,
        ServiceReportDetailPage(reportId: 'sr1', debugCubit: loading),
      );
      await tester.pump();
      expect(find.byType(ServiceReportsSkeleton), findsOneWidget);
    });

    testWidgets('detail refresh keeps report', (tester) async {
      final ready = _TestSrDetailCubit(
        const ServiceReportDetailState(
          status: ServiceReportDetailStatus.success,
          report: _report,
          isRefreshing: true,
        ),
      );
      addTearDown(ready.close);
      await pumpPage(
        tester,
        ServiceReportDetailPage(reportId: 'sr1', debugCubit: ready),
      );
      await tester.pump();
      expect(find.byType(ServiceReportsSkeleton), findsNothing);
      expect(find.byType(AppRefreshBar), findsOneWidget);
      expect(find.text('SR-100'), findsWidgets);
    });

    testWidgets('detail error retry', (tester) async {
      final cubit = _TestSrDetailCubit(
        const ServiceReportDetailState(
          status: ServiceReportDetailStatus.failure,
          message: 'failed',
        ),
      );
      addTearDown(cubit.close);
      await pumpPage(
        tester,
        ServiceReportDetailPage(reportId: 'sr1', debugCubit: cubit),
      );
      await tester.pump();
      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('Roles gates', () {
    testWidgets('dashboard loading skeleton', (tester) async {
      final cubit = _TestRolesDashboardCubit(
        const RolesDashboardState(status: RolesDashboardStatus.loading),
      );
      addTearDown(cubit.close);
      await pumpPage(tester, RolesDashboardPage(debugCubit: cubit));
      await tester.pump();
      expect(find.byType(RolesPermissionsSkeleton), findsOneWidget);
      expect(find.byType(AppLoader), findsNothing);
    });

    testWidgets('dashboard refresh keeps stats', (tester) async {
      final cubit = _TestRolesDashboardCubit(
        const RolesDashboardState(
          status: RolesDashboardStatus.success,
          dashboard: _rolesDash,
          isRefreshing: true,
        ),
      );
      addTearDown(cubit.close);
      await pumpPage(tester, RolesDashboardPage(debugCubit: cubit));
      await tester.pump();
      expect(find.byType(RolesPermissionsSkeleton), findsNothing);
      expect(find.byType(AppRefreshBar), findsOneWidget);
      expect(find.text('Total roles'), findsOneWidget);
    });

    testWidgets('list loading shows skeleton', (tester) async {
      final loading = _TestRolesListCubit(
        const RolesListState(status: RolesListStatus.loading),
      );
      addTearDown(loading.close);
      await pumpPage(tester, RolesListPage(debugCubit: loading));
      await tester.pump();
      expect(find.byType(RolesPermissionsSkeleton), findsOneWidget);
    });

    testWidgets('list refresh keeps row', (tester) async {
      final ready = _TestRolesListCubit(
        const RolesListState(
          status: RolesListStatus.success,
          items: [_role],
          isRefreshing: true,
        ),
      );
      addTearDown(ready.close);
      await pumpPage(tester, RolesListPage(debugCubit: ready));
      await tester.pump();
      expect(find.byType(RolesPermissionsSkeleton), findsNothing);
      expect(find.text('Field Lead'), findsOneWidget);
    });

    testWidgets('list empty shows empty copy', (tester) async {
      final empty = _TestRolesListCubit(
        const RolesListState(status: RolesListStatus.success),
      );
      addTearDown(empty.close);
      await pumpPage(tester, RolesListPage(debugCubit: empty));
      await tester.pump();
      expect(find.text('No roles found'), findsOneWidget);
    });

    testWidgets('detail loading shows skeleton', (tester) async {
      final loading = _TestRoleDetailCubit(
        const RoleDetailState(status: RoleDetailStatus.loading),
      );
      addTearDown(loading.close);
      await pumpPage(
        tester,
        RoleDetailPage(roleId: 'r1', debugCubit: loading),
      );
      await tester.pump();
      expect(find.byType(RolesPermissionsSkeleton), findsOneWidget);
    });

    testWidgets('detail refresh keeps role', (tester) async {
      final ready = _TestRoleDetailCubit(
        const RoleDetailState(
          status: RoleDetailStatus.success,
          role: _role,
          isRefreshing: true,
        ),
      );
      addTearDown(ready.close);
      await pumpPage(
        tester,
        RoleDetailPage(roleId: 'r1', debugCubit: ready),
      );
      await tester.pump();
      expect(find.byType(RolesPermissionsSkeleton), findsNothing);
      expect(find.byType(AppRefreshBar), findsOneWidget);
      expect(find.text('Field Lead'), findsWidgets);
    });

    testWidgets('form loading uses detail skeleton', (tester) async {
      final loading = _TestRoleFormCubit(
        const RoleFormState(status: RoleFormStatus.loading),
      );
      addTearDown(loading.close);
      await pumpPage(tester, RoleFormPage(debugCubit: loading));
      await tester.pump();
      expect(find.byType(RolesPermissionsSkeleton), findsOneWidget);
      expect(find.byType(AppLoader), findsNothing);
    });

    testWidgets('form save keeps catalog and shows save spinner',
        (tester) async {
      final saving = _TestRoleFormCubit(
        const RoleFormState(
          status: RoleFormStatus.saving,
          catalog: [
            PermissionCatalogItem(
              key: 'reports:view',
              module: 'reports',
              action: 'view',
            ),
          ],
        ),
      );
      addTearDown(saving.close);
      await pumpPage(tester, RoleFormPage(debugCubit: saving));
      await tester.pump();
      expect(find.byType(RolesPermissionsSkeleton), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });
}
