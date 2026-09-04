import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/organization/domain/entities/user_summary.dart';
import 'package:mobile/features/organization/domain/repositories/organization_repository.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order_priority.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order_status.dart';
import 'package:mobile/features/work_orders/domain/repositories/work_order_repository.dart';
import 'package:mobile/features/work_orders/domain/usecases/create_work_order_usecase.dart';
import 'package:mobile/features/work_orders/domain/usecases/get_work_order_by_id_usecase.dart';
import 'package:mobile/features/work_orders/domain/usecases/update_work_order_usecase.dart';
import 'package:mobile/features/work_orders/presentation/cubit/work_order_detail_cubit.dart';
import 'package:mobile/features/work_orders/presentation/cubit/work_order_form_cubit.dart';
import 'package:mobile/features/work_orders/presentation/widgets/work_order_execution_panel.dart';

UserSummary _tech(String id, String name) {
  return UserSummary(
    id: id,
    code: id,
    name: name,
    status: 'ACTIVE',
    companyId: 'c1',
    email: '$id@example.com',
    firstName: name,
    lastName: 'Tech',
    fullName: name,
    roles: const ['TECHNICIAN'],
    branchId: 'b1',
    departmentId: 'd1',
  );
}

class _FakeOrgRepo implements OrganizationRepository {
  @override
  Future<Result<List<UserSummary>>> getUsers({
    String? search,
    bool forceRefresh = false,
  }) async {
    return Success([_tech('t1', 'Tech One')]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeWorkOrderRepo implements WorkOrderRepository {
  WorkOrderUpsertInput? lastCreateInput;
  WorkOrderUpsertInput? lastUpdateInput;
  WorkOrder? existing;

  @override
  Future<Result<WorkOrder>> create(WorkOrderUpsertInput input) async {
    lastCreateInput = input;
    return Success(
      WorkOrder(
        id: 'new',
        companyId: 'c',
        jobNumber: 'WO-1',
        jobTitle: input.jobTitle,
        priority: input.priority,
        status: WorkOrderStatus.assigned,
        locationLabel: input.locationLabel,
        locationUrl: input.locationUrl,
      ),
    );
  }

  @override
  Future<Result<WorkOrder>> update(String id, WorkOrderUpsertInput input) async {
    lastUpdateInput = input;
    return Success(
      WorkOrder(
        id: id,
        companyId: 'c',
        jobNumber: 'WO-1',
        jobTitle: input.jobTitle,
        priority: input.priority,
        status: WorkOrderStatus.assigned,
        locationLabel: input.locationLabel,
        locationUrl: input.locationUrl,
      ),
    );
  }

  @override
  Future<Result<WorkOrder>> getById(String id) async {
    final wo = existing;
    if (wo == null) {
      return const Failure('missing');
    }
    return Success(wo);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

WorkOrder _wo({
  String? locationLabel,
  String? locationUrl,
}) {
  return WorkOrder(
    id: 'wo-1',
    companyId: 'c1',
    jobNumber: 'WO-0007',
    jobTitle: 'AC Repair',
    priority: WorkOrderPriority.high,
    status: WorkOrderStatus.assigned,
    locationLabel: locationLabel,
    locationUrl: locationUrl,
    scheduledAt: DateTime(2026, 8, 24, 10, 30),
  );
}

Future<void> _pumpTechnicianPanel(
  WidgetTester tester,
  WorkOrder workOrder,
) async {
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
      home: Scaffold(
        body: SingleChildScrollView(
          child: WorkOrderExecutionPanel(
            workOrder: workOrder,
            state: WorkOrderDetailState(
              status: WorkOrderDetailStatus.success,
              workOrder: workOrder,
            ),
            canExecute: true,
            showAdminDetails: false,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  group('splitWorkOrderLocationFields compatibility', () {
    test('keeps plain address and optional URL separate', () {
      final split = splitWorkOrderLocationFields(
        _wo(
          locationLabel: '123 Tahrir Street, Dokki, Giza',
          locationUrl: 'https://maps.app.goo.gl/xyz',
        ),
      );
      expect(split.address, '123 Tahrir Street, Dokki, Giza');
      expect(split.url, 'https://maps.app.goo.gl/xyz');
      expect(split.linkVisible, isTrue);
    });

    test('legacy URL stored only in locationLabel becomes the link field', () {
      final split = splitWorkOrderLocationFields(
        _wo(
          locationLabel: 'https://maps.app.goo.gl/legacy',
          locationUrl: null,
        ),
      );
      expect(split.address, isEmpty);
      expect(split.url, 'https://maps.app.goo.gl/legacy');
      expect(split.linkVisible, isTrue);
    });

    test('address-only record does not show link editor', () {
      final split = splitWorkOrderLocationFields(
        _wo(locationLabel: 'Dokki, Giza', locationUrl: null),
      );
      expect(split.address, 'Dokki, Giza');
      expect(split.url, isEmpty);
      expect(split.linkVisible, isFalse);
    });
  });

  group('form cubit location address + optional link', () {
    test('A: address only saves without locationUrl', () async {
      final repo = _FakeWorkOrderRepo();
      final cubit = WorkOrderFormCubit(
        create: CreateWorkOrderUseCase(repo),
        update: UpdateWorkOrderUseCase(repo),
        getById: GetWorkOrderByIdUseCase(repo),
        organizationRepository: _FakeOrgRepo(),
      );
      await cubit.load();
      cubit.updateField(
        jobTitle: 'Address only',
        locationLabel: '123 Tahrir Street, Dokki, Giza',
      );
      await cubit.submit();

      expect(repo.lastCreateInput!.locationLabel, '123 Tahrir Street, Dokki, Giza');
      expect(repo.lastCreateInput!.locationUrl, isNull);
    });

    test('B: address + URL both persist', () async {
      final repo = _FakeWorkOrderRepo();
      final cubit = WorkOrderFormCubit(
        create: CreateWorkOrderUseCase(repo),
        update: UpdateWorkOrderUseCase(repo),
        getById: GetWorkOrderByIdUseCase(repo),
        organizationRepository: _FakeOrgRepo(),
      );
      await cubit.load();
      cubit.updateField(
        jobTitle: 'Both',
        locationLabel: 'Dokki, Giza',
      );
      cubit.addLocationLinkRow();
      cubit.updateField(locationUrl: 'https://maps.app.goo.gl/abc');
      await cubit.submit();

      expect(repo.lastCreateInput!.locationLabel, 'Dokki, Giza');
      expect(repo.lastCreateInput!.locationUrl, 'https://maps.app.goo.gl/abc');
    });

    test('C: edit can add then remove URL without losing address', () async {
      final repo = _FakeWorkOrderRepo()
        ..existing = _wo(
          locationLabel: 'Dokki, Giza',
          locationUrl: null,
        );
      final cubit = WorkOrderFormCubit(
        create: CreateWorkOrderUseCase(repo),
        update: UpdateWorkOrderUseCase(repo),
        getById: GetWorkOrderByIdUseCase(repo),
        organizationRepository: _FakeOrgRepo(),
        workOrderId: 'wo-1',
      );
      await cubit.load();
      expect(cubit.state.locationLabel, 'Dokki, Giza');
      expect(cubit.state.locationLinkVisible, isFalse);

      cubit.addLocationLinkRow();
      cubit.updateField(locationUrl: 'https://maps.app.goo.gl/added');
      await cubit.submit();
      expect(repo.lastUpdateInput!.locationLabel, 'Dokki, Giza');
      expect(repo.lastUpdateInput!.locationUrl, 'https://maps.app.goo.gl/added');

      cubit.removeLocationLink();
      await cubit.submit();
      expect(repo.lastUpdateInput!.locationLabel, 'Dokki, Giza');
      expect(repo.lastUpdateInput!.locationUrl, isNull);
    });

    test('D: invalid URL is rejected without creating', () async {
      final repo = _FakeWorkOrderRepo();
      final cubit = WorkOrderFormCubit(
        create: CreateWorkOrderUseCase(repo),
        update: UpdateWorkOrderUseCase(repo),
        getById: GetWorkOrderByIdUseCase(repo),
        organizationRepository: _FakeOrgRepo(),
      );
      await cubit.load();
      cubit.updateField(jobTitle: 'Bad link');
      cubit.addLocationLinkRow();
      cubit.updateField(locationUrl: 'not-a-url');
      await cubit.submit();

      expect(repo.lastCreateInput, isNull);
      expect(cubit.state.message, 'workOrderLocationUrlInvalid');
      expect(cubit.state.isError, isTrue);
    });

    test('E: legacy URL-in-label loads into link field safely', () async {
      final repo = _FakeWorkOrderRepo()
        ..existing = _wo(
          locationLabel: 'https://maps.app.goo.gl/old',
          locationUrl: null,
        );
      final cubit = WorkOrderFormCubit(
        create: CreateWorkOrderUseCase(repo),
        update: UpdateWorkOrderUseCase(repo),
        getById: GetWorkOrderByIdUseCase(repo),
        organizationRepository: _FakeOrgRepo(),
        workOrderId: 'wo-1',
      );
      await cubit.load();
      expect(cubit.state.locationLabel, isEmpty);
      expect(cubit.state.locationUrl, 'https://maps.app.goo.gl/old');
      expect(cubit.state.locationLinkVisible, isTrue);
    });
  });

  group('technician location presentation', () {
    testWidgets('A: address only shows text and hides Open location', (
      tester,
    ) async {
      await _pumpTechnicianPanel(
        tester,
        _wo(locationLabel: '123 Tahrir Street', locationUrl: null),
      );
      expect(find.text('123 Tahrir Street'), findsOneWidget);
      expect(find.text('Open location'), findsNothing);
    });

    testWidgets('B: address + URL shows text and Open location', (tester) async {
      await _pumpTechnicianPanel(
        tester,
        _wo(
          locationLabel: 'Dokki, Giza',
          locationUrl: 'https://maps.app.goo.gl/abc',
        ),
      );
      expect(find.text('Dokki, Giza'), findsOneWidget);
      expect(find.text('Open location'), findsOneWidget);
      expect(find.textContaining('maps.app.goo.gl'), findsNothing);
    });

    testWidgets('C: after URL removed, Open location is hidden', (tester) async {
      await _pumpTechnicianPanel(
        tester,
        _wo(locationLabel: 'Dokki, Giza', locationUrl: null),
      );
      expect(find.text('Dokki, Giza'), findsOneWidget);
      expect(find.text('Open location'), findsNothing);
    });
  });
}
