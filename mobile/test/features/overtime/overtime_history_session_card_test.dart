import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/features/attendance/domain/entities/gps_snapshot.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_status.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_technician_summary.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_type.dart';
import 'package:mobile/features/overtime/presentation/widgets/overtime_history_session_card.dart';

GpsSnapshot _gps() => GpsSnapshot(
      latitude: 24.7,
      longitude: 46.6,
      accuracy: 5,
      recordedAt: DateTime.utc(2026, 8, 12, 8),
      provider: 'gps',
    );

OvertimeSession _session({
  required OvertimeStatus status,
  String? rejectionReason,
}) {
  final start = DateTime.utc(2026, 8, 12, 8);
  return OvertimeSession(
    id: 'ot-history-${status.name}',
    companyId: 'c1',
    userId: 'u1',
    type: OvertimeType.normal,
    status: status,
    startAt: start,
    endAt: start.add(const Duration(hours: 2)),
    startGps: _gps(),
    startDeviceId: 'dev-1',
    rejectionReason: rejectionReason,
    technician: const OvertimeTechnicianSummary(
      id: 'u1',
      fullName: 'Test Tech',
      email: 'tech@test.com',
      roles: ['TECHNICIAN'],
    ),
  );
}

Future<void> pumpHistoryCard(
  WidgetTester tester, {
  required OvertimeSession session,
  Locale locale = const Locale('en'),
  double width = 390,
}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final l10n = lookupAppLocalizations(locale);
  final dateFormat = DateFormat('yyyy-MM-dd');

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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: OvertimeHistorySessionCard(
              session: session,
              pendingSync: false,
              dateFormat: dateFormat,
              l10n: l10n,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OvertimeHistorySessionCard rejection reason', () {
    testWidgets('REJECTED with reason shows status and rejection reason', (
      tester,
    ) async {
      const reason =
          'Overtime was not approved because prior authorization was missing.';
      final session = _session(
        status: OvertimeStatus.rejected,
        rejectionReason: reason,
      );
      final l10n = lookupAppLocalizations(const Locale('en'));

      await pumpHistoryCard(tester, session: session);

      expect(find.text(l10n.overtimeStatusRejected), findsOneWidget);
      expect(find.text(l10n.overtimeRejectionReason), findsOneWidget);
      expect(find.text(reason), findsOneWidget);
    });

    testWidgets('REJECTED without reason shows status only', (tester) async {
      final session = _session(status: OvertimeStatus.rejected);
      final l10n = lookupAppLocalizations(const Locale('en'));

      await pumpHistoryCard(tester, session: session);

      expect(find.text(l10n.overtimeStatusRejected), findsOneWidget);
      expect(find.text(l10n.overtimeRejectionReason), findsNothing);
    });

    testWidgets('REJECTED with blank reason hides rejection section', (
      tester,
    ) async {
      final session = _session(
        status: OvertimeStatus.rejected,
        rejectionReason: '   ',
      );
      final l10n = lookupAppLocalizations(const Locale('en'));

      await pumpHistoryCard(tester, session: session);

      expect(find.text(l10n.overtimeStatusRejected), findsOneWidget);
      expect(find.text(l10n.overtimeRejectionReason), findsNothing);
    });

    testWidgets('APPROVED does not show rejection reason', (tester) async {
      final session = _session(
        status: OvertimeStatus.approved,
        rejectionReason: 'Should not appear',
      );
      final l10n = lookupAppLocalizations(const Locale('en'));

      await pumpHistoryCard(tester, session: session);

      expect(find.text(l10n.overtimeStatusApproved), findsOneWidget);
      expect(find.text(l10n.overtimeRejectionReason), findsNothing);
      expect(find.text('Should not appear'), findsNothing);
    });

    testWidgets('PENDING_REVIEW does not show rejection reason', (tester) async {
      final session = _session(
        status: OvertimeStatus.pendingReview,
        rejectionReason: 'Should not appear',
      );
      final l10n = lookupAppLocalizations(const Locale('en'));

      await pumpHistoryCard(tester, session: session);

      expect(find.text(l10n.overtimeStatusPendingReview), findsOneWidget);
      expect(find.text(l10n.overtimeRejectionReason), findsNothing);
      expect(find.text('Should not appear'), findsNothing);
    });

    testWidgets('long rejection reason wraps without overflow', (tester) async {
      final reason = List.filled(40, 'long rejection reason text').join(' ');
      final session = _session(
        status: OvertimeStatus.rejected,
        rejectionReason: reason,
      );

      await pumpHistoryCard(tester, session: session, width: 320);

      expect(tester.takeException(), isNull);
      expect(find.text(reason), findsOneWidget);
    });

    testWidgets('Arabic RTL shows localized rejection labels', (tester) async {
      const reason = 'لم يتم اعتماد العمل الإضافي بسبب عدم وجود موافقة مسبقة.';
      final session = _session(
        status: OvertimeStatus.rejected,
        rejectionReason: reason,
      );
      final l10n = lookupAppLocalizations(const Locale('ar'));

      await pumpHistoryCard(
        tester,
        session: session,
        locale: const Locale('ar'),
      );

      expect(
        Directionality.of(tester.element(find.byType(Scaffold))),
        TextDirection.rtl,
      );
      expect(find.text(l10n.overtimeStatusRejected), findsOneWidget);
      expect(find.text(l10n.overtimeRejectionReason), findsOneWidget);
      expect(find.text(reason), findsOneWidget);
    });

    testWidgets('English LTR shows localized rejection labels', (tester) async {
      const reason = 'Missing prior authorization.';
      final session = _session(
        status: OvertimeStatus.rejected,
        rejectionReason: reason,
      );
      final l10n = lookupAppLocalizations(const Locale('en'));

      await pumpHistoryCard(
        tester,
        session: session,
        locale: const Locale('en'),
      );

      expect(
        Directionality.of(tester.element(find.byType(Scaffold))),
        TextDirection.ltr,
      );
      expect(find.text(l10n.overtimeRejectionReason), findsOneWidget);
      expect(find.text(reason), findsOneWidget);
    });
  });
}
