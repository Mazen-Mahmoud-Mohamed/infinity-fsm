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
import 'package:mobile/features/reports_center/presentation/pages/reports_center_page.dart';
import 'package:mobile/features/service_reports/presentation/pages/service_reports_list_page.dart';
import 'package:mobile/features/settings/presentation/pages/account_settings_pages.dart';
import 'package:mobile/features/settings/presentation/pages/organization_settings_page.dart';
import 'package:mobile/features/settings/presentation/pages/overtime_settings_page.dart';
import 'package:mobile/features/settings/presentation/pages/server_management_page.dart';
import 'package:mobile/features/settings/presentation/pages/settings_extra_pages.dart';
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
        final user = authCubit.state.user;
        final home = user != null && user.usesOperationalHome
            ? RoutePaths.workOrders
            : RoutePaths.dashboard;

        if (isLogin || isSplash) {
          return home;
        }

        // Technicians must not land on / use the executive Dashboard.
        if (user != null &&
            user.usesOperationalHome &&
            location == RoutePaths.dashboard) {
          return RoutePaths.workOrders;
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
        // Branch indexes must match MainNavigationShell rail destinations:
        // 0 Dashboard, 1 Attendance, 2 Work Orders, 3 Overtime, 4 Profile,
        // 5 Inventory, 6 Assets, 7 PM, 8 Reports, 9 Users, 10 Roles, 11 Settings
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
                routes: [
                  GoRoute(
                    path: 'history',
                    builder: (context, state) =>
                        const AttendanceHistoryPage(),
                  ),
                  GoRoute(
                    path: 'admin',
                    builder: (context, state) => const AttendanceAdminPage(),
                    routes: [
                      GoRoute(
                        path: ':id',
                        builder: (context, state) => AttendanceAdminDetailPage(
                          attendanceId: state.pathParameters['id']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.workOrders,
                builder: (context, state) => const WorkOrdersPage(),
                routes: [
                  GoRoute(
                    path: 'form',
                    builder: (context, state) => const WorkOrderFormPage(),
                  ),
                  GoRoute(
                    path: 'form/:id',
                    builder: (context, state) => WorkOrderFormPage(
                      workOrderId: state.pathParameters['id'],
                    ),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => WorkOrderDetailPage(
                      workOrderId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.overtime,
                builder: (context, state) => const OvertimePage(),
                routes: [
                  GoRoute(
                    path: 'history',
                    builder: (context, state) => const OvertimeHistoryPage(),
                  ),
                  GoRoute(
                    path: 'admin',
                    builder: (context, state) => const OvertimeAdminPage(),
                    routes: [
                      GoRoute(
                        path: ':id',
                        builder: (context, state) => OvertimeAdminDetailPage(
                          sessionId: state.pathParameters['id']!,
                        ),
                      ),
                    ],
                  ),
                ],
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
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.inventory,
                builder: (context, state) => const InventoryDashboardPage(),
                routes: [
                  GoRoute(
                    path: 'warehouses',
                    builder: (context, state) => const WarehousesPage(),
                  ),
                  GoRoute(
                    path: 'stock-history',
                    builder: (context, state) => const StockHistoryPage(),
                  ),
                  GoRoute(
                    path: 'parts',
                    builder: (context, state) => const SparePartsPage(),
                    routes: [
                      GoRoute(
                        path: 'form',
                        builder: (context, state) =>
                            const SparePartFormPage(),
                      ),
                      GoRoute(
                        path: 'form/:id',
                        builder: (context, state) => SparePartFormPage(
                          partId: state.pathParameters['id'],
                        ),
                      ),
                      GoRoute(
                        path: ':id',
                        builder: (context, state) => SparePartDetailPage(
                          partId: state.pathParameters['id']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.assets,
                builder: (context, state) => const AssetsPage(),
                routes: [
                  GoRoute(
                    path: 'list',
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
                    path: 'categories',
                    builder: (context, state) =>
                        const AssetCategoriesPage(),
                  ),
                  GoRoute(
                    path: 'history',
                    builder: (context, state) => const AssetHistoryPage(),
                  ),
                  GoRoute(
                    path: 'form',
                    builder: (context, state) => const AssetFormPage(),
                  ),
                  GoRoute(
                    path: 'form/:id',
                    builder: (context, state) => AssetFormPage(
                      assetId: state.pathParameters['id'],
                    ),
                  ),
                  GoRoute(
                    path: 'detail/:id',
                    builder: (context, state) => AssetDetailPage(
                      assetId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.pm,
                builder: (context, state) => const PmDashboardPage(),
                routes: [
                  GoRoute(
                    path: 'plans',
                    builder: (context, state) => const PmPlansPage(),
                    routes: [
                      GoRoute(
                        path: 'form',
                        builder: (context, state) => const PmPlanFormPage(),
                      ),
                      GoRoute(
                        path: 'form/:id',
                        builder: (context, state) => PmPlanFormPage(
                          planId: state.pathParameters['id'],
                        ),
                      ),
                      GoRoute(
                        path: ':id',
                        builder: (context, state) => PmPlanDetailPage(
                          planId: state.pathParameters['id']!,
                        ),
                        routes: [
                          GoRoute(
                            path: 'checklist',
                            builder: (context, state) =>
                                PmChecklistBuilderPage(
                              planId: state.pathParameters['id']!,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'schedules',
                    builder: (context, state) => const PmSchedulesPage(),
                  ),
                  GoRoute(
                    path: 'history',
                    builder: (context, state) => const PmHistoryPage(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.reports,
                builder: (context, state) =>
                    const ReportsCenterPage(),
                routes: [
                  GoRoute(
                    path: 'list',
                    builder: (context, state) =>
                        const ServiceReportsListPage(),
                  ),
                  GoRoute(
                    path: 'signature',
                    builder: (context, state) =>
                        const CustomerSignaturePage(),
                  ),
                  GoRoute(
                    path: 'generate',
                    builder: (context, state) =>
                        const ServiceReportGeneratePage(),
                  ),
                  GoRoute(
                    path: 'detail/:id',
                    builder: (context, state) => ServiceReportDetailPage(
                      reportId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.users,
                builder: (context, state) => const UsersDashboardPage(),
                routes: [
                  GoRoute(
                    path: 'list',
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
                    path: 'form',
                    builder: (context, state) => const UserFormPage(),
                  ),
                  GoRoute(
                    path: 'form/:id',
                    builder: (context, state) => UserFormPage(
                      userId: state.pathParameters['id'],
                    ),
                  ),
                  GoRoute(
                    path: 'detail/:id',
                    builder: (context, state) => UserDetailPage(
                      userId: state.pathParameters['id']!,
                    ),
                  ),
                  GoRoute(
                    path: 'change-password',
                    builder: (context, state) =>
                        const ChangePasswordPage(),
                  ),
                  GoRoute(
                    path: 'reset-password/:id',
                    builder: (context, state) => ResetPasswordPage(
                      userId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.roles,
                builder: (context, state) => const RolesDashboardPage(),
                routes: [
                  GoRoute(
                    path: 'list',
                    builder: (context, state) => const RolesListPage(),
                  ),
                  GoRoute(
                    path: 'form',
                    builder: (context, state) => const RoleFormPage(),
                  ),
                  GoRoute(
                    path: 'form/:id',
                    builder: (context, state) => RoleFormPage(
                      roleId: state.pathParameters['id'],
                    ),
                  ),
                  GoRoute(
                    path: 'detail/:id',
                    builder: (context, state) => RoleDetailPage(
                      roleId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.settings,
                builder: (context, state) => const SettingsPage(),
                routes: [
                  GoRoute(
                    path: 'company',
                    builder: (context, state) =>
                        const OrganizationSettingsPage(),
                  ),
                  GoRoute(
                    path: 'overtime',
                    builder: (context, state) =>
                        const OvertimeSettingsPage(),
                  ),
                  GoRoute(
                    path: 'system',
                    builder: (context, state) =>
                        const SystemSettingsPage(),
                  ),
                  GoRoute(
                    path: 'language',
                    builder: (context, state) =>
                        const LanguageSettingsPage(),
                  ),
                  GoRoute(
                    path: 'theme',
                    builder: (context, state) =>
                        const ThemeSettingsPage(),
                  ),
                  GoRoute(
                    path: 'notifications',
                    builder: (context, state) =>
                        const NotificationPreferencesPage(),
                  ),
                  GoRoute(
                    path: 'about',
                    builder: (context, state) =>
                        const AboutSettingsPage(),
                  ),
                  GoRoute(
                    path: 'server',
                    builder: (context, state) =>
                        const ServerManagementPage(),
                  ),
                  GoRoute(
                    path: 'account',
                    builder: (context, state) =>
                        const AccountOverviewPage(),
                  ),
                  GoRoute(
                    path: 'sync',
                    builder: (context, state) =>
                        const SyncSettingsPage(),
                  ),
                  GoRoute(
                    path: 'storage',
                    builder: (context, state) =>
                        const StorageSettingsPage(),
                  ),
                  GoRoute(
                    path: 'support',
                    builder: (context, state) =>
                        const SupportSettingsPage(),
                  ),
                  GoRoute(
                    path: 'security',
                    builder: (context, state) =>
                        const SecuritySettingsPage(),
                  ),
                  GoRoute(
                    path: 'application',
                    builder: (context, state) =>
                        const ApplicationInfoPage(),
                  ),
                  GoRoute(
                    path: 'performance',
                    builder: (context, state) =>
                        const PerformanceSettingsPage(),
                  ),
                  GoRoute(
                    path: 'accessibility',
                    builder: (context, state) =>
                        const AccessibilitySettingsPage(),
                  ),
                  GoRoute(
                    path: 'backup',
                    builder: (context, state) =>
                        const BackupSettingsPage(),
                  ),
                  GoRoute(
                    path: 'danger',
                    builder: (context, state) => const DangerZonePage(),
                  ),
                  GoRoute(
                    path: 'updates',
                    builder: (context, state) =>
                        const UpdateCenterPage(),
                  ),
                  GoRoute(
                    path: 'logs',
                    builder: (context, state) => const AdminLogsPage(),
                  ),
                  GoRoute(
                    path: 'developer',
                    builder: (context, state) =>
                        const DeveloperOptionsPage(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: RoutePaths.notifications,
        builder: (context, state) => const NotificationsPage(),
      ),
    ],
  );
}
