import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/cache/session_query_cache.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/services/auth_session_service.dart';
import 'package:mobile/core/widgets/app_loader.dart';
import 'package:mobile/core/widgets/app_refresh_bar.dart';
import 'package:mobile/features/assets/domain/entities/asset.dart';
import 'package:mobile/features/assets/domain/entities/assets_dashboard.dart';
import 'package:mobile/features/assets/domain/repositories/assets_repository.dart';
import 'package:mobile/features/assets/domain/usecases/assets_usecases.dart';
import 'package:mobile/features/assets/presentation/cubit/assets_dashboard_cubit.dart';
import 'package:mobile/features/assets/presentation/cubit/assets_list_cubit.dart';
import 'package:mobile/features/assets/presentation/pages/assets_list_page.dart';
import 'package:mobile/features/assets/presentation/pages/assets_page.dart';
import 'package:mobile/features/assets/presentation/widgets/assets_skeleton.dart';
import 'package:mobile/features/auth/domain/entities/current_user.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobile/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:mobile/features/auth/domain/usecases/logout_all_devices_usecase.dart';
import 'package:mobile/features/auth/domain/usecases/logout_usecase.dart';
import 'package:mobile/features/auth/domain/usecases/restore_session_usecase.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/features/inventory/domain/entities/inventory_dashboard.dart';
import 'package:mobile/features/inventory/domain/entities/spare_part.dart';
import 'package:mobile/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:mobile/features/inventory/domain/usecases/get_inventory_dashboard_usecase.dart';
import 'package:mobile/features/inventory/domain/usecases/spare_part_usecases.dart';
import 'package:mobile/features/inventory/presentation/cubit/inventory_dashboard_cubit.dart';
import 'package:mobile/features/inventory/presentation/cubit/spare_parts_list_cubit.dart';
import 'package:mobile/features/inventory/presentation/pages/inventory_dashboard_page.dart';
import 'package:mobile/features/inventory/presentation/pages/spare_parts_page.dart';
import 'package:mobile/features/inventory/presentation/widgets/inventory_skeleton.dart';
import 'package:mobile/features/pm/domain/entities/pm_entities.dart';
import 'package:mobile/features/pm/domain/repositories/pm_repository.dart';
import 'package:mobile/features/pm/domain/usecases/pm_usecases.dart';
import 'package:mobile/features/pm/presentation/cubit/pm_dashboard_cubit.dart';
import 'package:mobile/features/pm/presentation/cubit/pm_plans_cubit.dart';
import 'package:mobile/features/pm/presentation/pages/pm_dashboard_page.dart';
import 'package:mobile/features/pm/presentation/pages/pm_plans_page.dart';
import 'package:mobile/features/pm/presentation/widgets/preventive_maintenance_skeleton.dart';

class _FakeAuthRepo extends Fake implements AuthRepository {}

class _FakeInvRepo extends Fake implements InventoryRepository {}

class _FakeAssetsRepo extends Fake implements AssetsRepository {}

class _FakePmRepo extends Fake implements PmRepository {}

class _TestInventoryDashboardCubit extends InventoryDashboardCubit {
  _TestInventoryDashboardCubit(InventoryDashboardState initial)
      : super(
          getDashboard: GetInventoryDashboardUseCase(_FakeInvRepo()),
          sessionCache: SessionQueryCache(),
        ) {
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    emit(initial);
  }

  void setState(InventoryDashboardState next) {
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    emit(next);
  }
}

class _TestSparePartsCubit extends SparePartsListCubit {
  _TestSparePartsCubit(SparePartsListState initial)
      : super(
          listSpareParts: ListSparePartsUseCase(_FakeInvRepo()),
          sessionCache: SessionQueryCache(),
        ) {
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    emit(initial);
  }

  void setState(SparePartsListState next) {
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    emit(next);
  }
}

class _TestAssetsDashboardCubit extends AssetsDashboardCubit {
  _TestAssetsDashboardCubit(AssetsDashboardState initial)
      : super(
          getDashboard: GetAssetsDashboardUseCase(_FakeAssetsRepo()),
          sessionCache: SessionQueryCache(),
        ) {
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    emit(initial);
  }

  void setState(AssetsDashboardState next) {
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    emit(next);
  }
}

class _TestAssetsListCubit extends AssetsListCubit {
  _TestAssetsListCubit(AssetsListState initial)
      : super(
          listAssets: ListAssetsUseCase(_FakeAssetsRepo()),
          sessionCache: SessionQueryCache(),
        ) {
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    emit(initial);
  }

  void setState(AssetsListState next) {
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    emit(next);
  }
}

class _TestPmDashboardCubit extends PmDashboardCubit {
  _TestPmDashboardCubit(PmDashboardState initial)
      : super(
          getDashboard: GetPmDashboardUseCase(_FakePmRepo()),
          queryCache: SessionQueryCache(),
        ) {
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    emit(initial);
  }

  void setState(PmDashboardState next) {
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    emit(next);
  }
}

class _TestPmPlansCubit extends PmPlansCubit {
  _TestPmPlansCubit(PmPlansState initial)
      : super(
          listPlans: ListPmPlansUseCase(_FakePmRepo()),
          queryCache: SessionQueryCache(),
        ) {
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    emit(initial);
  }

  void setState(PmPlansState next) {
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
          permissions: [],
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
          data: MediaQueryData(size: Size(width, 1400)),
          child: BlocProvider<AuthCubit>.value(
            value: authCubit,
            child: page,
          ),
        ),
      ),
    );
  }

  group('Inventory dashboard gates', () {
    testWidgets('initial no-data shows InventorySkeleton', (tester) async {
      final cubit = _TestInventoryDashboardCubit(
        const InventoryDashboardState(
          status: InventoryDashboardStatus.loading,
        ),
      );
      addTearDown(cubit.close);
      await pumpPage(tester, InventoryDashboardPage(debugCubit: cubit));
      await tester.pump();
      expect(find.byType(InventorySkeleton), findsOneWidget);
      expect(find.byType(AppLoader), findsNothing);
    });

    testWidgets('refresh with data keeps content', (tester) async {
      const dashboard = InventoryDashboard(
        totalParts: 4,
        lowStock: 1,
        outOfStock: 0,
      );
      final cubit = _TestInventoryDashboardCubit(
        const InventoryDashboardState(
          status: InventoryDashboardStatus.success,
          dashboard: dashboard,
          isRefreshing: true,
        ),
      );
      addTearDown(cubit.close);
      await pumpPage(tester, InventoryDashboardPage(debugCubit: cubit));
      await tester.pump();
      expect(find.byType(InventorySkeleton), findsNothing);
      expect(find.byType(AppRefreshBar), findsOneWidget);
      cubit.setState(
        const InventoryDashboardState(
          status: InventoryDashboardStatus.success,
          dashboard: dashboard,
        ),
      );
      await tester.pump();
      expect(find.byType(InventorySkeleton), findsNothing);
    });

    testWidgets('loaded empty shows movements empty state', (tester) async {
      final cubit = _TestInventoryDashboardCubit(
        const InventoryDashboardState(
          status: InventoryDashboardStatus.success,
          dashboard: InventoryDashboard(
            totalParts: 0,
            lowStock: 0,
            outOfStock: 0,
          ),
        ),
      );
      addTearDown(cubit.close);
      await pumpPage(tester, InventoryDashboardPage(debugCubit: cubit));
      await tester.pump();
      expect(find.byType(InventorySkeleton), findsNothing);
      expect(find.text('No stock movements yet'), findsOneWidget);
    });

    testWidgets('error with no data shows error', (tester) async {
      final cubit = _TestInventoryDashboardCubit(
        const InventoryDashboardState(
          status: InventoryDashboardStatus.failure,
          message: 'failed',
        ),
      );
      addTearDown(cubit.close);
      await pumpPage(tester, InventoryDashboardPage(debugCubit: cubit));
      await tester.pump();
      expect(find.byType(InventorySkeleton), findsNothing);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('desktop >=900 initial loading shows skeleton', (tester) async {
      final cubit = _TestInventoryDashboardCubit(
        const InventoryDashboardState(
          status: InventoryDashboardStatus.initial,
        ),
      );
      addTearDown(cubit.close);
      await pumpPage(
        tester,
        InventoryDashboardPage(debugCubit: cubit),
        width: 900,
      );
      await tester.pump();
      expect(find.byType(InventorySkeleton), findsOneWidget);
    });
  });

  group('Inventory spare parts list gates', () {
    testWidgets('initial no-data shows list skeleton', (tester) async {
      final cubit = _TestSparePartsCubit(
        const SparePartsListState(status: SparePartsListStatus.loading),
      );
      addTearDown(cubit.close);
      await pumpPage(tester, SparePartsPage(debugCubit: cubit));
      await tester.pump();
      expect(find.byType(InventorySkeleton), findsOneWidget);
      expect(find.byType(AppLoader), findsNothing);
    });

    testWidgets('refresh with data keeps real row', (tester) async {
      const part = SparePart(
        id: 'p1',
        partNumber: 'PN-1',
        name: 'Filter',
        unit: 'pcs',
        currentQuantity: 3,
        minimumQuantity: 1,
        stockStatus: StockStatus.inStock,
      );
      final cubit = _TestSparePartsCubit(
        SparePartsListState(
          status: SparePartsListStatus.success,
          items: const [part],
          isRefreshing: true,
        ),
      );
      addTearDown(cubit.close);
      await pumpPage(tester, SparePartsPage(debugCubit: cubit));
      await tester.pump();
      expect(find.byType(InventorySkeleton), findsNothing);
      expect(find.text('Filter'), findsOneWidget);
    });

    testWidgets('loaded empty shows empty state', (tester) async {
      final cubit = _TestSparePartsCubit(
        const SparePartsListState(status: SparePartsListStatus.success),
      );
      addTearDown(cubit.close);
      await pumpPage(tester, SparePartsPage(debugCubit: cubit));
      await tester.pump();
      expect(find.byType(InventorySkeleton), findsNothing);
      expect(find.text('No spare parts found'), findsOneWidget);
    });

    testWidgets('error with no data shows error', (tester) async {
      final cubit = _TestSparePartsCubit(
        const SparePartsListState(
          status: SparePartsListStatus.failure,
          message: 'failed',
        ),
      );
      addTearDown(cubit.close);
      await pumpPage(tester, SparePartsPage(debugCubit: cubit));
      await tester.pump();
      expect(find.byType(InventorySkeleton), findsNothing);
      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('Assets dashboard gates', () {
    testWidgets('initial no-data shows AssetsSkeleton', (tester) async {
      final cubit = _TestAssetsDashboardCubit(
        const AssetsDashboardState(status: AssetsDashboardStatus.loading),
      );
      addTearDown(cubit.close);
      await pumpPage(tester, AssetsPage(debugCubit: cubit));
      await tester.pump();
      expect(find.byType(AssetsSkeleton), findsOneWidget);
      expect(find.byType(AppLoader), findsNothing);
    });

    testWidgets('refresh with data keeps content', (tester) async {
      const dashboard = AssetsDashboard(
        totalAssets: 9,
        active: 7,
        underMaintenance: 1,
        retired: 1,
        warrantyExpiringSoon: 0,
      );
      final cubit = _TestAssetsDashboardCubit(
        const AssetsDashboardState(
          status: AssetsDashboardStatus.success,
          dashboard: dashboard,
          isRefreshing: true,
        ),
      );
      addTearDown(cubit.close);
      await pumpPage(tester, AssetsPage(debugCubit: cubit));
      await tester.pump();
      expect(find.byType(AssetsSkeleton), findsNothing);
      expect(find.byType(AppRefreshBar), findsOneWidget);
    });

    testWidgets('error with no data shows error', (tester) async {
      final cubit = _TestAssetsDashboardCubit(
        const AssetsDashboardState(
          status: AssetsDashboardStatus.failure,
          message: 'failed',
        ),
      );
      addTearDown(cubit.close);
      await pumpPage(tester, AssetsPage(debugCubit: cubit));
      await tester.pump();
      expect(find.byType(AssetsSkeleton), findsNothing);
      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('Assets list gates', () {
    testWidgets('initial no-data shows list skeleton', (tester) async {
      final cubit = _TestAssetsListCubit(
        const AssetsListState(status: AssetsListStatus.loading),
      );
      addTearDown(cubit.close);
      await pumpPage(tester, AssetsListPage(debugCubit: cubit));
      await tester.pump();
      expect(find.byType(AssetsSkeleton), findsOneWidget);
    });

    testWidgets('refresh with data keeps real row', (tester) async {
      const asset = Asset(
        id: 'a1',
        assetNumber: 'AST-1',
        name: 'Pump',
        status: AssetStatus.active,
      );
      final cubit = _TestAssetsListCubit(
        AssetsListState(
          status: AssetsListStatus.success,
          items: const [asset],
          isRefreshing: true,
        ),
      );
      addTearDown(cubit.close);
      await pumpPage(tester, AssetsListPage(debugCubit: cubit));
      await tester.pump();
      expect(find.byType(AssetsSkeleton), findsNothing);
      expect(find.text('Pump'), findsOneWidget);
    });

    testWidgets('loaded empty shows empty state', (tester) async {
      final cubit = _TestAssetsListCubit(
        const AssetsListState(status: AssetsListStatus.success),
      );
      addTearDown(cubit.close);
      await pumpPage(tester, AssetsListPage(debugCubit: cubit));
      await tester.pump();
      expect(find.byType(AssetsSkeleton), findsNothing);
      expect(find.text('No assets found'), findsOneWidget);
    });

    testWidgets('error with no data shows error', (tester) async {
      final cubit = _TestAssetsListCubit(
        const AssetsListState(
          status: AssetsListStatus.failure,
          message: 'failed',
        ),
      );
      addTearDown(cubit.close);
      await pumpPage(tester, AssetsListPage(debugCubit: cubit));
      await tester.pump();
      expect(find.byType(AssetsSkeleton), findsNothing);
      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('PM dashboard gates', () {
    testWidgets('initial no-data shows PreventiveMaintenanceSkeleton',
        (tester) async {
      final cubit = _TestPmDashboardCubit(
        const PmDashboardState(status: PmDashboardStatus.loading),
      );
      addTearDown(cubit.close);
      await pumpPage(tester, PmDashboardPage(debugCubit: cubit));
      await tester.pump();
      expect(find.byType(PreventiveMaintenanceSkeleton), findsOneWidget);
      expect(find.byType(AppLoader), findsNothing);
    });

    testWidgets('refresh with data keeps content', (tester) async {
      const dashboard = PmDashboard(
        upcoming: 2,
        overdue: 1,
        completed: 4,
        cancelled: 0,
        activePlans: 3,
      );
      final cubit = _TestPmDashboardCubit(
        const PmDashboardState(
          status: PmDashboardStatus.success,
          dashboard: dashboard,
          isRefreshing: true,
        ),
      );
      addTearDown(cubit.close);
      await pumpPage(tester, PmDashboardPage(debugCubit: cubit));
      await tester.pump();
      expect(find.byType(PreventiveMaintenanceSkeleton), findsNothing);
      expect(find.byType(AppRefreshBar), findsOneWidget);
    });

    testWidgets('error with no data shows error', (tester) async {
      final cubit = _TestPmDashboardCubit(
        const PmDashboardState(
          status: PmDashboardStatus.failure,
          message: 'failed',
        ),
      );
      addTearDown(cubit.close);
      await pumpPage(tester, PmDashboardPage(debugCubit: cubit));
      await tester.pump();
      expect(find.byType(PreventiveMaintenanceSkeleton), findsNothing);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('desktop >=900 initial loading shows skeleton', (tester) async {
      final cubit = _TestPmDashboardCubit(
        const PmDashboardState(status: PmDashboardStatus.initial),
      );
      addTearDown(cubit.close);
      await pumpPage(
        tester,
        PmDashboardPage(debugCubit: cubit),
        width: 1100,
      );
      await tester.pump();
      expect(find.byType(PreventiveMaintenanceSkeleton), findsOneWidget);
    });
  });

  group('PM plans list gates', () {
    testWidgets('initial no-data shows list skeleton', (tester) async {
      final cubit = _TestPmPlansCubit(
        const PmPlansState(status: PmPlansStatus.loading),
      );
      addTearDown(cubit.close);
      await pumpPage(tester, PmPlansPage(debugCubit: cubit));
      await tester.pump();
      expect(find.byType(PreventiveMaintenanceSkeleton), findsOneWidget);
    });

    testWidgets('refresh with data keeps real row', (tester) async {
      const plan = MaintenancePlan(
        id: 'pl1',
        name: 'HVAC Plan',
        code: 'PM-1',
        frequency: PmFrequency.monthly,
        trigger: PmTrigger.timeBased,
        priority: PmPriority.medium,
        status: PmPlanStatus.active,
      );
      final cubit = _TestPmPlansCubit(
        PmPlansState(
          status: PmPlansStatus.success,
          items: const [plan],
          isRefreshing: true,
        ),
      );
      addTearDown(cubit.close);
      await pumpPage(tester, PmPlansPage(debugCubit: cubit));
      await tester.pump();
      expect(find.byType(PreventiveMaintenanceSkeleton), findsNothing);
      expect(find.text('HVAC Plan'), findsOneWidget);
    });

    testWidgets('loaded empty shows empty state', (tester) async {
      final cubit = _TestPmPlansCubit(
        const PmPlansState(status: PmPlansStatus.success),
      );
      addTearDown(cubit.close);
      await pumpPage(tester, PmPlansPage(debugCubit: cubit));
      await tester.pump();
      expect(find.byType(PreventiveMaintenanceSkeleton), findsNothing);
      expect(find.text('No maintenance plans found'), findsOneWidget);
    });

    testWidgets('error with no data shows error', (tester) async {
      final cubit = _TestPmPlansCubit(
        const PmPlansState(
          status: PmPlansStatus.failure,
          message: 'failed',
        ),
      );
      addTearDown(cubit.close);
      await pumpPage(tester, PmPlansPage(debugCubit: cubit));
      await tester.pump();
      expect(find.byType(PreventiveMaintenanceSkeleton), findsNothing);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
