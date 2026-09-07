import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/cache/session_query_cache.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/widgets/app_loader.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_constants.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_shell_body.dart';
import 'package:mobile/features/auth/domain/entities/current_user.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobile/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:mobile/features/auth/domain/usecases/logout_all_devices_usecase.dart';
import 'package:mobile/features/auth/domain/usecases/logout_usecase.dart';
import 'package:mobile/features/auth/domain/usecases/restore_session_usecase.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/core/services/auth_session_service.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order_priority.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order_status.dart';
import 'package:mobile/features/work_orders/domain/usecases/list_my_work_orders_usecase.dart';
import 'package:mobile/features/work_orders/domain/usecases/list_work_orders_usecase.dart';
import 'package:mobile/features/work_orders/presentation/cubit/work_orders_list_cubit.dart';
import 'package:mobile/features/work_orders/presentation/widgets/work_orders_desktop_view.dart';
import 'package:mobile/features/work_orders/presentation/widgets/work_orders_list_skeleton.dart';

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
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    emit(initial);
  }

  void setState(WorkOrdersListState next) {
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    emit(next);
  }
}

WorkOrder _sample() => WorkOrder(
      id: 'wo-1',
      companyId: 'c1',
      jobNumber: 'WO-1',
      jobTitle: 'Sample',
      priority: WorkOrderPriority.medium,
      status: WorkOrderStatus.assigned,
      customerName: 'Customer',
    );

void main() {
  late _TestWorkOrdersListCubit cubit;
  late AuthCubit authCubit;
  late AuthSessionService session;
  late TextEditingController search;

  setUp(() {
    cubit = _TestWorkOrdersListCubit(
      const WorkOrdersListState(status: WorkOrdersListStatus.loading),
    );
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
    search = TextEditingController();
  });

  tearDown(() async {
    await cubit.close();
    await authCubit.close();
    session.dispose();
    search.dispose();
  });

  Future<void> pumpDesktop(WidgetTester tester) async {
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
          data: const MediaQueryData(size: Size(1100, 900)),
          child: MultiBlocProvider(
            providers: [
              BlocProvider<AuthCubit>.value(value: authCubit),
              BlocProvider<WorkOrdersListCubit>.value(value: cubit),
            ],
            child: Scaffold(
              body: Row(
                children: [
                  SizedBox(width: AppDesktopConstants.sidebarCollapsedWidth),
                  Expanded(
                    child: AppDesktopShellBody(
                      child: WorkOrdersDesktopView(
                        isAdminMode: true,
                        scrollController: ScrollController(),
                        searchController: search,
                        onSearchChanged: () {},
                        onOpenForm: () async {},
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('desktop initial no-data shows WorkOrdersListSkeleton',
      (tester) async {
    await pumpDesktop(tester);
    await tester.pump();
    expect(find.byType(WorkOrdersListSkeleton), findsOneWidget);
    expect(find.byType(AppLoader), findsNothing);
  });

  testWidgets('desktop refresh with data keeps content, not skeleton',
      (tester) async {
    cubit.setState(
      WorkOrdersListState(
        status: WorkOrdersListStatus.success,
        items: [_sample()],
        isRefreshing: true,
      ),
    );
    await pumpDesktop(tester);
    await tester.pump();

    expect(find.byType(WorkOrdersListSkeleton), findsNothing);
    expect(find.text('Sample'), findsOneWidget);

    cubit.setState(
      WorkOrdersListState(
        status: WorkOrdersListStatus.success,
        items: [_sample()],
      ),
    );
    await tester.pump();
    expect(find.byType(WorkOrdersListSkeleton), findsNothing);
    expect(find.text('Sample'), findsOneWidget);
  });

  testWidgets('desktop loaded empty shows empty state', (tester) async {
    cubit.setState(
      const WorkOrdersListState(
        status: WorkOrdersListStatus.success,
        items: [],
      ),
    );
    await pumpDesktop(tester);
    await tester.pump();
    expect(find.byType(WorkOrdersListSkeleton), findsNothing);
  });

  testWidgets('desktop error with no data shows error, not skeleton',
      (tester) async {
    cubit.setState(
      const WorkOrdersListState(
        status: WorkOrdersListStatus.failure,
        message: 'boom',
      ),
    );
    await pumpDesktop(tester);
    await tester.pump();
    expect(find.byType(WorkOrdersListSkeleton), findsNothing);
    expect(find.byType(FilledButton), findsOneWidget);
  });
}
