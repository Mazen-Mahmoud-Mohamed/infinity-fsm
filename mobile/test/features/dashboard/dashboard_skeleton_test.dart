import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/cache/session_query_cache.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/services/auth_session_service.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/core/widgets/app_refresh_bar.dart';
import 'package:mobile/core/widgets/skeleton/skeleton.dart';
import 'package:mobile/features/auth/domain/entities/current_user.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobile/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:mobile/features/auth/domain/usecases/logout_all_devices_usecase.dart';
import 'package:mobile/features/auth/domain/usecases/logout_usecase.dart';
import 'package:mobile/features/auth/domain/usecases/restore_session_usecase.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/features/dashboard/domain/entities/role_dashboard_summary.dart';
import 'package:mobile/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:mobile/features/dashboard/domain/usecases/get_dashboard_summary_usecase.dart';
import 'package:mobile/features/dashboard/presentation/cubit/executive_dashboard_cubit.dart';
import 'package:mobile/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:mobile/features/dashboard/presentation/widgets/dashboard_dense_widgets.dart';
import 'package:mobile/features/dashboard/presentation/widgets/dashboard_skeleton.dart';

class _FakeDashboardRepository implements DashboardRepository {
  RoleDashboardSummary? nextSummary;

  @override
  Future<Result<RoleDashboardSummary>> getSummary({
    required DashboardPeriod period,
    DateTime? from,
    DateTime? to,
  }) async {
    final summary = nextSummary;
    if (summary == null) {
      return const Failure('missing');
    }
    return Success(summary);
  }
}

class _FakeAuthRepo implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

CurrentUser _user(List<String> roles) => CurrentUser(
      id: 'u1',
      companyId: 'c1',
      email: 'u@example.com',
      firstName: 'Test',
      lastName: 'User',
      fullName: 'Test User',
      roles: roles,
      permissions: const [],
    );

RoleDashboardSummary _summary(DashboardViewRole role) {
  final now = DateTime(2026, 9, 1);
  return RoleDashboardSummary(
    viewRole: role,
    period: DashboardPeriod.month,
    from: now,
    to: now,
    kpis: role == DashboardViewRole.admin
        ? const DashboardKpis(
            totalEmployees: 10,
            activeEmployees: 8,
            employeesCurrentlyWorking: 3,
          )
        : null,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('resolveDashboardSkeletonRole', () {
    test('maps ADMIN / SUPERVISOR / technician', () {
      expect(
        resolveDashboardSkeletonRole(_user(['ADMIN'])),
        DashboardViewRole.admin,
      );
      expect(
        resolveDashboardSkeletonRole(_user(['SUPERVISOR'])),
        DashboardViewRole.supervisor,
      );
      expect(
        resolveDashboardSkeletonRole(_user(['TECHNICIAN'])),
        DashboardViewRole.technician,
      );
      expect(
        resolveDashboardSkeletonRole(null),
        DashboardViewRole.admin,
      );
    });
  });

  group('DashboardSkeleton structure', () {
    Widget wrap(
      Widget child, {
      double width = 400,
      Locale locale = const Locale('en'),
      TextDirection direction = TextDirection.ltr,
    }) {
      return MaterialApp(
        locale: locale,
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
            data: MediaQueryData(
              size: Size(width, 900),
              textScaler: TextScaler.noScaling,
            ),
            child: Scaffold(body: child),
          ),
        ),
      );
    }

    testWidgets('admin skeleton uses KPI strip layout bones', (tester) async {
      await tester.pumpWidget(
        wrap(
          const DashboardSkeleton(
            viewRole: DashboardViewRole.admin,
            pagePadding: 16,
            sectionGap: 16,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(DashboardSkeleton), findsOneWidget);
      expect(find.byType(SkeletonScope), findsOneWidget);
      expect(find.byType(SkeletonChip), findsWidgets);
      expect(find.byType(SkeletonCircle), findsWidgets);
      expect(find.byType(SkeletonPanel), findsWidgets);
    });

    testWidgets('supervisor skeleton uses hero metrics cards', (tester) async {
      await tester.pumpWidget(
        wrap(
          const DashboardSkeleton(
            viewRole: DashboardViewRole.supervisor,
            pagePadding: 16,
            sectionGap: 16,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(DashboardSkeleton), findsOneWidget);
      expect(find.byType(SkeletonCard), findsWidgets);
    });

    testWidgets('technician skeleton exposes loading semantics', (tester) async {
      await tester.pumpWidget(
        wrap(
          const DashboardSkeleton(
            viewRole: DashboardViewRole.technician,
            pagePadding: 16,
            sectionGap: 16,
            semanticsLabel: 'Loading dashboard',
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(DashboardSkeleton), findsOneWidget);
      expect(
        find.bySemanticsLabel('Loading dashboard'),
        findsOneWidget,
      );
    });

    testWidgets('900px desktop width builds without overflow', (tester) async {
      await tester.pumpWidget(
        wrap(
          const DashboardSkeleton(
            viewRole: DashboardViewRole.admin,
            pagePadding: 16,
            sectionGap: 24,
          ),
          width: 900,
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(DashboardSkeleton), findsOneWidget);
    });

    testWidgets('RTL builds without overflow', (tester) async {
      await tester.pumpWidget(
        wrap(
          const DashboardSkeleton(
            viewRole: DashboardViewRole.admin,
            pagePadding: 16,
            sectionGap: 16,
          ),
          locale: const Locale('ar'),
          direction: TextDirection.rtl,
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('DashboardPage first-load vs refresh', () {
    late ExecutiveDashboardCubit cubit;
    late AuthCubit authCubit;
    late AuthSessionService sessionService;
    late _FakeDashboardRepository repo;

    setUp(() {
      repo = _FakeDashboardRepository()
        ..nextSummary = _summary(DashboardViewRole.admin);

      cubit = ExecutiveDashboardCubit(
        getDashboardSummary: GetDashboardSummaryUseCase(repo),
        sessionQueryCache: SessionQueryCache(),
      );

      sessionService = AuthSessionService();
      final fakeRepo = _FakeAuthRepo();
      authCubit = AuthCubit(
        restoreSessionUseCase: RestoreSessionUseCase(fakeRepo),
        getCurrentUserUseCase: GetCurrentUserUseCase(fakeRepo),
        logoutUseCase: LogoutUseCase(fakeRepo),
        logoutAllDevicesUseCase: LogoutAllDevicesUseCase(fakeRepo),
        authSessionService: sessionService,
        sessionQueryCache: SessionQueryCache(),
      );
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      authCubit.emit(
        AuthState(
          status: AuthStatus.authenticated,
          user: _user(['ADMIN']),
        ),
      );
    });

    tearDown(() async {
      await cubit.close();
      await authCubit.close();
      sessionService.dispose();
    });

    Future<void> pumpPage(WidgetTester tester, {double width = 900}) async {
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
            data: MediaQueryData(size: Size(width, 900)),
            child: MultiBlocProvider(
              providers: [
                BlocProvider<AuthCubit>.value(value: authCubit),
              ],
              child: DashboardPage(debugCubit: cubit),
            ),
          ),
        ),
      );
    }

    testWidgets('shows skeleton on initial empty loading', (tester) async {
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      cubit.emit(
        const ExecutiveDashboardState(
          status: ExecutiveDashboardStatus.loading,
        ),
      );
      await pumpPage(tester);
      await tester.pump();

      expect(find.byType(DashboardSkeleton), findsOneWidget);
      expect(find.byType(DashboardPageHeader), findsNothing);
      expect(find.byKey(const ValueKey('dashboard-skeleton')), findsOneWidget);
    });

    testWidgets('keeps content + AppRefreshBar when refreshing with summary',
        (tester) async {
      final summary = _summary(DashboardViewRole.admin);
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      cubit.emit(
        ExecutiveDashboardState(
          status: ExecutiveDashboardStatus.success,
          summary: summary,
          hasLoadedOnce: true,
          isRefreshing: true,
        ),
      );
      await pumpPage(tester);
      await tester.pump();

      expect(find.byType(DashboardSkeleton), findsNothing);
      expect(find.byType(DashboardPageHeader), findsOneWidget);
      expect(find.byType(AppRefreshBar), findsOneWidget);

      // Refresh flag flip must not reintroduce skeleton.
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      cubit.emit(
        ExecutiveDashboardState(
          status: ExecutiveDashboardStatus.success,
          summary: summary,
          hasLoadedOnce: true,
          isRefreshing: false,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(DashboardSkeleton), findsNothing);
      expect(find.byType(DashboardPageHeader), findsOneWidget);
      expect(find.byKey(const ValueKey('dashboard-content')), findsOneWidget);
    });

    testWidgets('does not show skeleton when cached summary exists',
        (tester) async {
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      cubit.emit(
        ExecutiveDashboardState(
          status: ExecutiveDashboardStatus.success,
          summary: _summary(DashboardViewRole.admin),
          hasLoadedOnce: true,
        ),
      );
      await pumpPage(tester);
      await tester.pump();

      expect(find.byType(DashboardSkeleton), findsNothing);
      expect(find.byType(DashboardPageHeader), findsOneWidget);
    });

    testWidgets('900px desktop first-load skeleton has no exceptions',
        (tester) async {
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      cubit.emit(
        const ExecutiveDashboardState(
          status: ExecutiveDashboardStatus.loading,
        ),
      );
      await pumpPage(tester, width: 900);
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(DashboardSkeleton), findsOneWidget);
    });
  });
}
