import 'package:go_router/go_router.dart';
import 'package:mobile/core/router/auth_router_refresh.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/features/assets/domain/entities/asset.dart';
import 'package:mobile/features/assets/presentation/pages/asset_categories_page.dart';
import 'package:mobile/features/assets/presentation/pages/asset_detail_page.dart';
import 'package:mobile/features/assets/presentation/pages/asset_form_page.dart';
import 'package:mobile/features/assets/presentation/pages/asset_history_page.dart';
import 'package:mobile/features/assets/presentation/pages/assets_list_page.dart';
import 'package:mobile/features/assets/presentation/pages/assets_page.dart';
import 'package:mobile/features/attendance/presentation/pages/attendance_admin_detail_page.dart';
import 'package:mobile/features/attendance/presentation/pages/attendance_admin_page.dart';
import 'package:mobile/features/attendance/presentation/pages/attendance_dashboard_page.dart';
import 'package:mobile/features/attendance/presentation/pages/attendance_history_page.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/features/auth/presentation/pages/login_page.dart';
import 'package:mobile/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:mobile/features/inventory/presentation/pages/inventory_dashboard_page.dart';
import 'package:mobile/features/inventory/presentation/pages/spare_part_detail_page.dart';
import 'package:mobile/features/inventory/presentation/pages/spare_part_form_page.dart';
import 'package:mobile/features/inventory/presentation/pages/spare_parts_page.dart';
import 'package:mobile/features/inventory/presentation/pages/stock_history_page.dart';
import 'package:mobile/features/inventory/presentation/pages/warehouses_page.dart';
import 'package:mobile/features/notifications/presentation/pages/notifications_page.dart';
import 'package:mobile/features/overtime/presentation/pages/overtime_admin_detail_page.dart';
import 'package:mobile/features/overtime/presentation/pages/overtime_admin_page.dart';
import 'package:mobile/features/overtime/presentation/pages/overtime_history_page.dart';
import 'package:mobile/features/overtime/presentation/pages/overtime_page.dart';
import 'package:mobile/features/pm/presentation/pages/pm_checklist_builder_page.dart';
import 'package:mobile/features/pm/presentation/pages/pm_dashboard_page.dart';
import 'package:mobile/features/pm/presentation/pages/pm_history_page.dart';
import 'package:mobile/features/pm/presentation/pages/pm_plan_detail_page.dart';
import 'package:mobile/features/pm/presentation/pages/pm_plan_form_page.dart';
import 'package:mobile/features/pm/presentation/pages/pm_plans_page.dart';
import 'package:mobile/features/pm/presentation/pages/pm_schedules_page.dart';
import 'package:mobile/features/roles/presentation/pages/role_detail_page.dart';
import 'package:mobile/features/roles/presentation/pages/role_form_page.dart';
import 'package:mobile/features/roles/presentation/pages/roles_dashboard_page.dart';
import 'package:mobile/features/roles/presentation/pages/roles_list_page.dart';
import 'package:mobile/features/service_reports/presentation/pages/customer_signature_page.dart';
import 'package:mobile/features/service_reports/presentation/pages/service_report_detail_page.dart';
import 'package:mobile/features/service_reports/presentation/pages/service_report_generate_page.dart';
import 'package:mobile/features/service_reports/presentation/pages/service_reports_dashboard_page.dart';
import 'package:mobile/features/service_reports/presentation/pages/service_reports_list_page.dart';
import 'package:mobile/features/settings/presentation/pages/account_settings_pages.dart';
import 'package:mobile/features/settings/presentation/pages/organization_settings_page.dart';
import 'package:mobile/features/settings/presentation/pages/system_settings_page.dart';
import 'package:mobile/features/users/domain/entities/user_management_entities.dart';
import 'package:mobile/features/users/presentation/pages/change_password_page.dart';
import 'package:mobile/features/users/presentation/pages/reset_password_page.dart';
import 'package:mobile/features/users/presentation/pages/user_detail_page.dart';
import 'package:mobile/features/users/presentation/pages/user_form_page.dart';
import 'package:mobile/features/users/presentation/pages/users_dashboard_page.dart';
import 'package:mobile/features/users/presentation/pages/users_list_page.dart';
import 'package:mobile/features/work_orders/presentation/pages/work_order_detail_page.dart';
import 'package:mobile/features/work_orders/presentation/pages/work_order_form_page.dart';
import 'package:mobile/features/work_orders/presentation/pages/work_orders_page.dart';
import 'package:mobile/shared/presentation/pages/profile_page.dart';
import 'package:mobile/shared/presentation/pages/settings_page.dart';
import 'package:mobile/shared/presentation/pages/splash_page.dart';

GoRouter createAppRouter({
  required AuthCubit authCubit,
  required AuthRouterRefresh refreshListenable,
}) {
  return GoRouter(
    initialLocation: RoutePaths.splash,
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final authStatus = authCubit.state.status;
      final location = state.matchedLocation;
      final isSplash = location == RoutePaths.splash;
      final isLogin = location == RoutePaths.login;

      if (authStatus == AuthStatus.unknown) {
        return isSplash ? null : RoutePaths.splash;
      }

      if (authStatus == AuthStatus.unauthenticated) {
        if (isLogin || isSplash) {
          return null;
        }
        return RoutePaths.login;
      }

      if (authStatus == AuthStatus.authenticated) {
        if (isLogin || isSplash) {
          return RoutePaths.dashboard;
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: RoutePaths.login,
        builder: (context, state) => const LoginPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainNavigationShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.dashboard,
                builder: (context, state) => const DashboardPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.attendance,
                builder: (context, state) => const AttendanceDashboardPage(),
              ),
            ],
          ),
          // Branch indexes must match MainNavigationShell destinations:
          // 0 Dashboard, 1 Attendance, 2 Work Orders, 3 Overtime, 4 Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.workOrders,
                builder: (context, state) => const WorkOrdersPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.overtime,
                builder: (context, state) => const OvertimePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.profile,
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: RoutePaths.assets,
        builder: (context, state) => const AssetsPage(),
      ),
      GoRoute(
        path: RoutePaths.assetsList,
        builder: (context, state) {
          final extra = state.extra;
          AssetStatus? initialStatus;
          if (extra is AssetStatus) {
            initialStatus = extra;
          }
          return AssetsListPage(initialStatus: initialStatus);
        },
      ),
      GoRoute(
        path: RoutePaths.assetsCategories,
        builder: (context, state) => const AssetCategoriesPage(),
      ),
      GoRoute(
        path: RoutePaths.assetsForm,
        builder: (context, state) => const AssetFormPage(),
      ),
      GoRoute(
        path: '/assets/form/:id',
        builder: (context, state) => AssetFormPage(
          assetId: state.pathParameters['id'],
        ),
      ),
      GoRoute(
        path: '/assets/detail/:id',
        builder: (context, state) => AssetDetailPage(
          assetId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: RoutePaths.assetsHistory,
        builder: (context, state) => const AssetHistoryPage(),
      ),
      GoRoute(
        path: RoutePaths.pm,
        builder: (context, state) => const PmDashboardPage(),
      ),
      GoRoute(
        path: RoutePaths.pmPlans,
        builder: (context, state) => const PmPlansPage(),
      ),
      GoRoute(
        path: '/pm/plans/:id',
        builder: (context, state) => PmPlanDetailPage(
          planId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: RoutePaths.pmPlanForm,
        builder: (context, state) => const PmPlanFormPage(),
      ),
      GoRoute(
        path: '/pm/plans/form/:id',
        builder: (context, state) => PmPlanFormPage(
          planId: state.pathParameters['id'],
        ),
      ),
      GoRoute(
        path: '/pm/plans/:id/checklist',
        builder: (context, state) => PmChecklistBuilderPage(
          planId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: RoutePaths.pmSchedules,
        builder: (context, state) => const PmSchedulesPage(),
      ),
      GoRoute(
        path: RoutePaths.pmHistory,
        builder: (context, state) => const PmHistoryPage(),
      ),
      GoRoute(
        path: RoutePaths.reports,
        builder: (context, state) => const ServiceReportsDashboardPage(),
      ),
      GoRoute(
        path: RoutePaths.reportsList,
        builder: (context, state) => const ServiceReportsListPage(),
      ),
      GoRoute(
        path: RoutePaths.reportsSignature,
        builder: (context, state) => const CustomerSignaturePage(),
      ),
      GoRoute(
        path: RoutePaths.reportsGenerate,
        builder: (context, state) => const ServiceReportGeneratePage(),
      ),
      GoRoute(
        path: '/reports/detail/:id',
        builder: (context, state) => ServiceReportDetailPage(
          reportId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: RoutePaths.users,
        builder: (context, state) => const UsersDashboardPage(),
      ),
      GoRoute(
        path: RoutePaths.usersList,
        builder: (context, state) {
          final extra = state.extra;
          ManagedUserStatus? initialStatus;
          if (extra is ManagedUserStatus) {
            initialStatus = extra;
          }
          return UsersListPage(initialStatus: initialStatus);
        },
      ),
      GoRoute(
        path: RoutePaths.usersForm,
        builder: (context, state) => const UserFormPage(),
      ),
      GoRoute(
        path: '/users/form/:id',
        builder: (context, state) => UserFormPage(
          userId: state.pathParameters['id'],
        ),
      ),
      GoRoute(
        path: '/users/detail/:id',
        builder: (context, state) => UserDetailPage(
          userId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: RoutePaths.usersChangePassword,
        builder: (context, state) => const ChangePasswordPage(),
      ),
      GoRoute(
        path: '/users/reset-password/:id',
        builder: (context, state) => ResetPasswordPage(
          userId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: RoutePaths.roles,
        builder: (context, state) => const RolesDashboardPage(),
      ),
      GoRoute(
        path: RoutePaths.rolesList,
        builder: (context, state) => const RolesListPage(),
      ),
      GoRoute(
        path: '/roles/detail/:id',
        builder: (context, state) => RoleDetailPage(
          roleId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: RoutePaths.rolesForm,
        builder: (context, state) => const RoleFormPage(),
      ),
      GoRoute(
        path: '/roles/form/:id',
        builder: (context, state) => RoleFormPage(
          roleId: state.pathParameters['id'],
        ),
      ),
      GoRoute(
        path: RoutePaths.inventory,
        builder: (context, state) => const InventoryDashboardPage(),
      ),
      GoRoute(
        path: RoutePaths.inventoryWarehouses,
        builder: (context, state) => const WarehousesPage(),
      ),
      GoRoute(
        path: RoutePaths.inventoryParts,
        builder: (context, state) => const SparePartsPage(),
      ),
      GoRoute(
        path: '/inventory/parts/:id',
        builder: (context, state) => SparePartDetailPage(
          partId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: RoutePaths.inventoryPartForm,
        builder: (context, state) => const SparePartFormPage(),
      ),
      GoRoute(
        path: '/inventory/parts/form/:id',
        builder: (context, state) => SparePartFormPage(
          partId: state.pathParameters['id'],
        ),
      ),
      GoRoute(
        path: RoutePaths.inventoryStockHistory,
        builder: (context, state) => const StockHistoryPage(),
      ),
      GoRoute(
        path: RoutePaths.notifications,
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: RoutePaths.settings,
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: RoutePaths.settingsCompany,
        builder: (context, state) => const OrganizationSettingsPage(),
      ),
      GoRoute(
        path: RoutePaths.settingsSystem,
        builder: (context, state) => const SystemSettingsPage(),
      ),
      GoRoute(
        path: RoutePaths.settingsLanguage,
        builder: (context, state) => const LanguageSettingsPage(),
      ),
      GoRoute(
        path: RoutePaths.settingsTheme,
        builder: (context, state) => const ThemeSettingsPage(),
      ),
      GoRoute(
        path: RoutePaths.settingsNotifications,
        builder: (context, state) => const NotificationPreferencesPage(),
      ),
      GoRoute(
        path: RoutePaths.settingsAbout,
        builder: (context, state) => const AboutSettingsPage(),
      ),
      GoRoute(
        path: RoutePaths.attendanceHistory,
        builder: (context, state) => const AttendanceHistoryPage(),
      ),
      GoRoute(
        path: RoutePaths.attendanceAdmin,
        builder: (context, state) => const AttendanceAdminPage(),
      ),
      GoRoute(
        path: '/attendance/admin/:id',
        builder: (context, state) => AttendanceAdminDetailPage(
          attendanceId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: RoutePaths.overtimeHistory,
        builder: (context, state) => const OvertimeHistoryPage(),
      ),
      GoRoute(
        path: RoutePaths.overtimeAdmin,
        builder: (context, state) => const OvertimeAdminPage(),
      ),
      GoRoute(
        path: '/overtime/admin/:id',
        builder: (context, state) => OvertimeAdminDetailPage(
          sessionId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: RoutePaths.workOrderForm,
        builder: (context, state) => const WorkOrderFormPage(),
      ),
      GoRoute(
        path: '/work-orders/form/:id',
        builder: (context, state) => WorkOrderFormPage(
          workOrderId: state.pathParameters['id'],
        ),
      ),
      GoRoute(
        path: '/work-orders/:id',
        builder: (context, state) => WorkOrderDetailPage(
          workOrderId: state.pathParameters['id']!,
        ),
      ),
    ],
  );
}
