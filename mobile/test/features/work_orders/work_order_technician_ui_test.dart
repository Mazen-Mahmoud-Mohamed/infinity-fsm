import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order_priority.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order_status.dart';
import 'package:mobile/features/work_orders/presentation/cubit/work_order_detail_cubit.dart';
import 'package:mobile/features/work_orders/presentation/widgets/work_order_execution_panel.dart';

WorkOrder _wo({
  String? locationUrl = 'https://maps.app.goo.gl/AbCdEfGhIjKlMnOpQr',
  String? locationLabel,
  List<String> phones = const [],
  String? notes = 'Bring filter',
  WorkOrderFieldLocation? startedLocation,
  WorkOrderStatus status = WorkOrderStatus.assigned,
}) {
  return WorkOrder(
    id: 'wo-1',
    companyId: 'c1',
    jobNumber: 'WO-0007',
    jobTitle: 'AC Repair',
    priority: WorkOrderPriority.high,
    status: status,
    locationUrl: locationUrl,
    locationLabel: locationLabel ?? locationUrl,
    customerPhoneNumbers: phones,
    notes: notes,
    startedLocation: startedLocation,
    completedLocation: startedLocation,
    scheduledAt: DateTime(2026, 8, 24, 10, 30),
  );
}

WorkOrderDetailState _state(WorkOrder wo) => WorkOrderDetailState(
      status: WorkOrderDetailStatus.success,
      workOrder: wo,
    );

Future<void> _pumpPanel(
  WidgetTester tester, {
  required WorkOrder workOrder,
  required bool showAdminDetails,
  Locale locale = const Locale('en'),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
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
            state: _state(workOrder),
            canExecute: true,
            showAdminDetails: showAdminDetails,
          ),
        ),
      ),
    ),
  );
  // Avoid pumpAndSettle — section cards / expansion can keep animating.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  group('WorkOrder location title', () {
    test('does not expose raw URL when human-readable fallback is used', () {
      final wo = _wo(
        locationUrl: 'https://maps.app.goo.gl/raw-url-only',
        locationLabel: 'https://maps.app.goo.gl/raw-url-only',
      );
      expect(
        wo.locationTitle(urlFallback: 'Customer Location'),
        'Customer Location',
      );
      expect(
        wo.locationTitle(urlFallback: 'Customer Location').contains('http'),
        isFalse,
      );
      expect(wo.effectiveLocationUrl, contains('maps.app.goo.gl'));
    });

    test('prefers non-URL locationLabel / address', () {
      final wo = _wo(
        locationLabel: 'El Basatin, Cairo',
        locationUrl: 'https://maps.app.goo.gl/xyz',
      );
      expect(
        wo.locationTitle(urlFallback: 'Customer Location'),
        'El Basatin, Cairo',
      );
    });
  });

  group('Technician execution panel', () {
    testWidgets('hides captured locations and raw map URL', (tester) async {
      final wo = _wo(
        startedLocation: const WorkOrderFieldLocation(
          latitude: 24.7,
          longitude: 46.6,
          accuracy: 8,
        ),
      );
      await _pumpPanel(tester, workOrder: wo, showAdminDetails: false);

      expect(find.textContaining('maps.app.goo.gl'), findsNothing);
      expect(find.text('Customer Location'), findsOneWidget);
      expect(find.text('Open location'), findsOneWidget);
      expect(find.text('Captured locations'), findsNothing);
      expect(find.textContaining('24.7'), findsNothing);
    });

    testWidgets('Arabic technician location uses موقع العميل fallback',
        (tester) async {
      final wo = _wo();
      await _pumpPanel(
        tester,
        workOrder: wo,
        showAdminDetails: false,
        locale: const Locale('ar'),
      );
      expect(find.text('موقع العميل'), findsOneWidget);
      expect(find.text('فتح الموقع'), findsOneWidget);
      expect(find.textContaining('maps.app.goo.gl'), findsNothing);
      expect(find.text('المواقع المسجلة'), findsNothing);
    });

    testWidgets('shows phones when present and hides when empty', (tester) async {
      await _pumpPanel(
        tester,
        workOrder: _wo(phones: const ['+201012345678']),
        showAdminDetails: false,
      );
      expect(find.text('+201012345678'), findsOneWidget);
      expect(find.text('Call'), findsOneWidget);

      await _pumpPanel(
        tester,
        workOrder: _wo(phones: const []),
        showAdminDetails: false,
      );
      expect(find.text('Call'), findsNothing);
    });

    testWidgets('shows notes and keeps open-location action', (tester) async {
      await _pumpPanel(
        tester,
        workOrder: _wo(notes: 'Use side entrance'),
        showAdminDetails: false,
      );
      expect(find.text('Use side entrance'), findsOneWidget);
      expect(find.text('Open location'), findsOneWidget);
    });

    testWidgets('admin still sees captured locations', (tester) async {
      final wo = _wo(
        startedLocation: const WorkOrderFieldLocation(
          latitude: 24.7136,
          longitude: 46.6753,
          accuracy: 5,
        ),
      );
      await _pumpPanel(tester, workOrder: wo, showAdminDetails: true);
      expect(find.text('Captured locations'), findsOneWidget);
    });
  });
}
