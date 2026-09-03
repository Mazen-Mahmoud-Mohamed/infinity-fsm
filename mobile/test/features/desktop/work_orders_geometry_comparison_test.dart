import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/cache/session_query_cache.dart';
import 'package:mobile/core/constants/permissions.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/services/auth_session_service.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_action_bar.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_constants.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_data_table.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_page_layout.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_shell_body.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_toolbar.dart';
import 'package:mobile/features/auth/domain/entities/current_user.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobile/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:mobile/features/auth/domain/usecases/logout_all_devices_usecase.dart';
import 'package:mobile/features/auth/domain/usecases/logout_usecase.dart';
import 'package:mobile/features/auth/domain/usecases/restore_session_usecase.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order_priority.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order_status.dart';
import 'package:mobile/features/work_orders/domain/usecases/list_my_work_orders_usecase.dart';
import 'package:mobile/features/work_orders/domain/usecases/list_work_orders_usecase.dart';
import 'package:mobile/features/work_orders/presentation/cubit/work_orders_list_cubit.dart';
import 'package:mobile/features/work_orders/presentation/widgets/work_orders_desktop_view.dart';

class _FakeAuthRepo extends Fake implements AuthRepository {}

class _FakeListWorkOrders extends Fake implements ListWorkOrdersUseCase {}

class _FakeListMyWorkOrders extends Fake implements ListMyWorkOrdersUseCase {}

class _TestWorkOrdersListCubit extends WorkOrdersListCubit {
  _TestWorkOrdersListCubit(WorkOrdersListState initial)
      : super(
          listWorkOrders: _FakeListWorkOrders(),
          listMyWorkOrders: _FakeListMyWorkOrders(),
          sessionQueryCache: SessionQueryCache(),
        ) {
    emit(initial);
  }
}

WorkOrder _sampleWorkOrder() {
  return WorkOrder(
    id: 'wo-1',
    companyId: 'c1',
    jobNumber: 'WO-20260828-0001',
    jobTitle: 'Sample job',
    priority: WorkOrderPriority.medium,
    status: WorkOrderStatus.assigned,
    customerName: 'Customer',
  );
}

Widget _shellReplica({required Widget branch}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: AppDesktopConstants.sidebarCollapsedWidth),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: AppDesktopConstants.topBarHeight),
                Expanded(
                  child: AppDesktopShellBody(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox.shrink(),
                        Expanded(child: branch),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _GeometryReport {
  _GeometryReport({
    required this.label,
    required this.found,
    required this.hasSize,
    required this.global,
    required this.size,
    required this.attached,
  });

  final String label;
  final bool found;
  final bool hasSize;
  final Offset global;
  final Size size;
  final bool attached;

  @override
  String toString() {
    if (!found) {
      return '$label = NOT FOUND';
    }
    return '$label = Offset(${global.dx.toStringAsFixed(1)}, '
        '${global.dy.toStringAsFixed(1)}), '
        'Size(${size.width.toStringAsFixed(1)}, ${size.height.toStringAsFixed(1)}), '
        'attached=$attached, hasSize=$hasSize';
  }
}

_GeometryReport _measure(WidgetTester tester, String label, Finder finder) {
  if (finder.evaluate().isEmpty) {
    return _GeometryReport(
      label: label,
      found: false,
      hasSize: false,
      global: Offset.zero,
      size: Size.zero,
      attached: false,
    );
  }
  final ro = tester.renderObject<RenderBox>(finder.first);
  return _GeometryReport(
    label: label,
    found: true,
    hasSize: ro.hasSize,
    global: ro.localToGlobal(Offset.zero),
    size: ro.size,
    attached: ro.attached,
  );
}

void _printReport(String heading, List<_GeometryReport> reports) {
  debugPrint('GLOBAL_GEOMETRY [$heading]');
  for (final report in reports) {
    debugPrint(report.toString());
  }
}

List<_GeometryReport> _workOrdersReports(WidgetTester tester) {
  return [
    _measure(tester, 'title', find.text('Work Orders')),
    _measure(tester, 'actions', find.byType(AppDesktopActionBar)),
    _measure(tester, 'refresh', find.text('Refresh')),
    _measure(
      tester,
      'toolbar',
      find.byWidgetPredicate(
        (w) =>
            w is TextField &&
            w.decoration?.hintText == 'Search job, customer, or location',
      ),
    ),
    _measure(
      tester,
      'table',
      find.byType(AppDesktopDataTable),
    ),
  ];
}

List<_GeometryReport> _usersReports(WidgetTester tester) {
  return [
    _measure(tester, 'title', find.text('Users')),
    _measure(
      tester,
      'actions',
      find.widgetWithText(FilledButton, 'Create user'),
    ),
    _measure(
      tester,
      'toolbar',
      find.byWidgetPredicate(
        (w) =>
            w is TextField &&
            w.decoration?.hintText == 'Search users',
      ),
    ),
    _measure(tester, 'table', find.byType(AppDesktopDataTable)),
  ];
}

Widget _usersDesktopReplica() {
  return _shellReplica(
    branch: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppDesktopListPageHeader(
          title: 'Users',
          trailing: FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Create user'),
          ),
          toolbar: AppDesktopToolbar(
            search: TextField(
              decoration: const InputDecoration(
                hintText: 'Search users',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onSubmitted: (_) {},
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(label: Text('All'), selected: true, onSelected: null),
              ],
            ),
          ),
        ),
        const Expanded(
          child: ColoredBox(color: Color(0xFF333333)),
        ),
      ],
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthSessionService sessionService;
  late AuthCubit authCubit;
  late _TestWorkOrdersListCubit listCubit;
  late ScrollController scrollController;
  late TextEditingController searchController;

  const admin = CurrentUser(
    id: 'admin-1',
    companyId: 'c1',
    email: 'admin@example.com',
    firstName: 'Admin',
    lastName: 'User',
    fullName: 'Admin User',
    roles: ['ADMIN'],
    permissions: [
      Permissions.workOrdersViewAll,
      Permissions.workOrdersCreate,
      Permissions.usersView,
      Permissions.usersCreate,
    ],
  );

  setUp(() {
    sessionService = AuthSessionService();
    authCubit = AuthCubit(
      restoreSessionUseCase: RestoreSessionUseCase(_FakeAuthRepo()),
      getCurrentUserUseCase: GetCurrentUserUseCase(_FakeAuthRepo()),
      logoutUseCase: LogoutUseCase(_FakeAuthRepo()),
      logoutAllDevicesUseCase: LogoutAllDevicesUseCase(_FakeAuthRepo()),
      authSessionService: sessionService,
      sessionQueryCache: SessionQueryCache(),
    )..setAuthenticated(admin);

    listCubit = _TestWorkOrdersListCubit(
      const WorkOrdersListState(status: WorkOrdersListStatus.initial),
    );
    scrollController = ScrollController();
    searchController = TextEditingController();
  });

  tearDown(() async {
    await listCubit.close();
    await authCubit.close();
    scrollController.dispose();
    searchController.dispose();
    sessionService.dispose();
  });

  Future<void> pumpWorkOrders(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _shellReplica(
        branch: BlocProvider<WorkOrdersListCubit>.value(
          value: listCubit,
          child: BlocProvider<AuthCubit>.value(
            value: authCubit,
            child: WorkOrdersDesktopView(
              isAdminMode: true,
              scrollController: scrollController,
              searchController: searchController,
              onSearchChanged: () {},
              onOpenForm: () async {},
            ),
          ),
        ),
      ),
    );
  }

  group('Work Orders page-level geometry comparison', () {
    testWidgets('A: initial/loading state geometry', (tester) async {
      await pumpWorkOrders(tester);
      await tester.pump();

      final reports = _workOrdersReports(tester);
      _printReport('WorkOrders loading', reports);

      expect(find.text('Refresh'), findsOneWidget);
      final refresh = reports.firstWhere((r) => r.label == 'refresh');
      expect(refresh.hasSize, isTrue);
      expect(refresh.size.height, greaterThan(0));
      expect(refresh.global.dy, greaterThan(0));
    });

    testWidgets('B: loaded state geometry after data arrives', (tester) async {
      await pumpWorkOrders(tester);
      await tester.pump();

      listCubit.emit(
        WorkOrdersListState(
          status: WorkOrdersListStatus.success,
          items: [_sampleWorkOrder()],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final reports = _workOrdersReports(tester);
      _printReport('WorkOrders loaded', reports);

      final title = reports.firstWhere((r) => r.label == 'title');
      final actions = reports.firstWhere((r) => r.label == 'actions');
      final refresh = reports.firstWhere((r) => r.label == 'refresh');
      final toolbar = reports.firstWhere((r) => r.label == 'toolbar');
      final table = reports.firstWhere((r) => r.label == 'table');

      expect(refresh.hasSize, isTrue);
      expect(refresh.size.height, greaterThan(0));
      expect(refresh.global.dy, greaterThan(0));
      expect(title.global.dy, lessThan(toolbar.global.dy));
      expect(toolbar.global.dy, lessThan(table.global.dy));
      expect(table.global.dy, lessThan(refresh.global.dy));

      debugPrint(
        'ORDER CHECK: titleY=${title.global.dy} toolbarY=${toolbar.global.dy} '
        'tableY=${table.global.dy} refreshY=${refresh.global.dy}',
      );
      debugPrint(
        'ACTIONS BAR: ${actions.size.width}x${actions.size.height} at ${actions.global}',
      );
    });

    testWidgets('Users known-good desktop replica geometry', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_usersDesktopReplica());
      await tester.pumpAndSettle();

      final reports = _usersReports(tester);
      _printReport('Users reference', reports);

      final create = reports.firstWhere((r) => r.label == 'actions');
      expect(create.hasSize, isTrue);
      expect(create.global.dy, greaterThan(0));
    });
  });
}
