import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_data_table.dart';
import 'package:mobile/features/attendance/domain/entities/gps_snapshot.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_status.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_technician_summary.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_type.dart';
import 'package:mobile/features/overtime/presentation/widgets/overtime_admin_desktop_table.dart';

GpsSnapshot _gps() => GpsSnapshot(
      latitude: 24.7,
      longitude: 46.6,
      accuracy: 5,
      recordedAt: DateTime.utc(2026, 8, 12, 8),
      provider: 'gps',
    );

OvertimeSession _session({
  required String id,
  required bool isOvernight,
  String fullName = 'Jane Technician',
  String email = 'jane.tech@example.com',
}) {
  final start = DateTime.utc(2026, 8, 12, 8);
  return OvertimeSession(
    id: id,
    companyId: 'c1',
    userId: 'u1',
    type: OvertimeType.travel,
    status: OvertimeStatus.approved,
    startAt: start,
    endAt: start.add(const Duration(hours: 3)),
    startGps: _gps(),
    startDeviceId: 'dev-1',
    isOvernight: isOvernight,
    eligibleOvertimeMinutes: 120,
    technician: OvertimeTechnicianSummary(
      id: 'u1',
      fullName: fullName,
      email: email,
      roles: const ['TECHNICIAN'],
    ),
  );
}

Future<void> _pumpDesktopTable(
  WidgetTester tester, {
  required List<OvertimeSession> sessions,
}) async {
  tester.view.physicalSize = const Size(1200, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final scrollController = ScrollController();
  addTearDown(scrollController.dispose);

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
        body: OvertimeAdminDesktopTable(
          sessions: sessions,
          dateFormat: DateFormat('yyyy-MM-dd HH:mm'),
          scrollController: scrollController,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('OvertimeAdminDesktopTable', () {
    testWidgets('renders technician display name without email', (tester) async {
      await _pumpDesktopTable(
        tester,
        sessions: [
          _session(id: 'ot-1', isOvernight: false),
        ],
      );

      expect(find.text('Jane Technician'), findsOneWidget);
      expect(find.text('jane.tech@example.com'), findsNothing);
    });

    testWidgets('includes Per Diem column in the required order', (tester) async {
      await _pumpDesktopTable(
        tester,
        sessions: [
          _session(id: 'ot-1', isOvernight: true),
        ],
      );

      expect(find.byKey(const Key('overtime-desktop-col-technician')), findsOneWidget);
      expect(find.byKey(const Key('overtime-desktop-col-type')), findsOneWidget);
      expect(find.byKey(const Key('overtime-desktop-col-status')), findsOneWidget);
      expect(find.byKey(const Key('overtime-desktop-col-per-diem')), findsOneWidget);
      expect(find.byKey(const Key('overtime-desktop-col-start')), findsOneWidget);
      expect(find.byKey(const Key('overtime-desktop-col-end')), findsOneWidget);
      expect(find.byKey(const Key('overtime-desktop-col-overtime-hours')), findsOneWidget);

      final headers = tester
          .widgetList<Text>(find.descendant(
            of: find.byType(AppDesktopDataTable),
            matching: find.byType(Text),
          ))
          .map((text) => text.data)
          .whereType<String>()
          .take(7)
          .toList();

      expect(headers, [
        'Technician',
        'Type',
        'Status',
        'Per Diem',
        'Start',
        'End',
        'Overtime Hours',
      ]);
    });

    testWidgets('renders Yes and No badges from isOvernight', (tester) async {
      await _pumpDesktopTable(
        tester,
        sessions: [
          _session(id: 'ot-yes', isOvernight: true),
          _session(
            id: 'ot-no',
            isOvernight: false,
            fullName: 'John Technician',
            email: 'john.tech@example.com',
          ),
        ],
      );

      expect(find.byKey(const Key('overtime-per-diem-Yes')), findsOneWidget);
      expect(find.byKey(const Key('overtime-per-diem-No')), findsOneWidget);
    });

    testWidgets('matches Work Orders table wrapper structure', (tester) async {
      await _pumpDesktopTable(
        tester,
        sessions: [
          _session(id: 'ot-1', isOvernight: false),
        ],
      );

      final tableFinder = find.byType(AppDesktopDataTable);
      expect(tableFinder, findsOneWidget);

      final layoutBuilder = find.ancestor(
        of: tableFinder,
        matching: find.byType(LayoutBuilder),
      );
      expect(layoutBuilder, findsOneWidget);

      final table = tester.widget<AppDesktopDataTable>(tableFinder);
      expect(table.columnMinWidth, 128);
      expect(table.expandVertically, isTrue);
    });
  });
}
