import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/features/attendance/domain/entities/gps_snapshot.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_checkpoint.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_status.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_technician_summary.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_type.dart';
import 'package:mobile/features/overtime/presentation/widgets/overtime_journey_timeline.dart';
import 'package:mobile/features/overtime/presentation/widgets/technician_overtime_running_card.dart';
import 'package:mobile/features/overtime/presentation/widgets/technician_overtime_stage_photos.dart';

GpsSnapshot _gps() => GpsSnapshot(
      latitude: 24.7136,
      longitude: 46.6753,
      accuracy: 5,
      recordedAt: DateTime.utc(2026, 8, 12, 8),
      provider: 'gps',
    );

OvertimeCheckpoint _cp(
  DateTime at, {
  String? photoUrl,
}) =>
    OvertimeCheckpoint(
      at: at,
      gps: _gps(),
      photoUrl: photoUrl ?? 'https://example.com/overtime.jpg',
      address: '123 Test Street, Riyadh',
      deviceId: 'dev-technician-test',
      batteryLevel: 82,
      networkStatus: 'wifi',
    );

OvertimeSession _runningSession({
  bool startDone = true,
  bool arrivedDone = false,
  bool finishedDone = false,
  bool endDone = false,
  String? startPhotoUrl,
  String? arrivedPhotoUrl,
}) {
  final base = DateTime.utc(2026, 8, 12, 8);
  return OvertimeSession(
    id: 'ot-tech-ui-test',
    companyId: 'c1',
    userId: 'u1',
    type: OvertimeType.normal,
    status: OvertimeStatus.running,
    startAt: base,
    endAt: null,
    startGps: _gps(),
    startDeviceId: 'dev-technician-test',
    workflowVersion: OvertimeWorkflowVersion.v2,
    requiresManualReview: false,
    checkpoints: OvertimeCheckpoints(
      startJourney: startDone
          ? _cp(base, photoUrl: startPhotoUrl ?? 'https://example.com/start.jpg')
          : null,
      arrivedAtWorkSite: arrivedDone
          ? _cp(
              base.add(const Duration(hours: 1)),
              photoUrl: arrivedPhotoUrl,
            )
          : null,
      finishedWork: finishedDone
          ? _cp(base.add(const Duration(hours: 6)))
          : null,
      endJourney: endDone ? _cp(base.add(const Duration(hours: 8))) : null,
    ),
    technician: const OvertimeTechnicianSummary(
      id: 'u1',
      fullName: 'Test Tech',
      email: 'tech@test.com',
      roles: ['TECHNICIAN'],
    ),
  );
}

Future<void> pumpTechnicianContent(
  WidgetTester tester, {
  required Widget child,
  Locale locale = const Locale('en'),
  double width = 390,
}) async {
  tester.view.physicalSize = Size(width, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

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
            child: child,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

TechnicianOvertimeRunningContent _contentFor(OvertimeSession session) {
  return TechnicianOvertimeRunningContent(
    session: session,
    nextStage: session.effectiveNextCheckpoint,
    isBusy: false,
    busyAction: null,
    onAdvance: () {},
    elapsedSeconds: 3661,
    voiceMaxDurationSeconds: 300,
    voiceRecordingQuality: 'medium',
    onNotesChanged: (_) {},
    onVoiceDraftChanged: (_) {},
    pendingActions: const [],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Technician overtime running UI', () {
    testWidgets('hides technical telemetry and journey review widgets', (
      tester,
    ) async {
      final session = _runningSession(startDone: true, arrivedDone: true);
      final l10n = lookupAppLocalizations(const Locale('en'));

      await pumpTechnicianContent(
        tester,
        child: _contentFor(session),
      );

      expect(find.text(l10n.overtimeCurrentStage), findsOneWidget);
      expect(find.text(l10n.overtimeNotes), findsOneWidget);
      expect(find.text(l10n.overtimeVoiceNote), findsOneWidget);
      expect(find.text(l10n.overtimeImages), findsWidgets);
      expect(find.text(l10n.overtimeArrivedAtWorkSite), findsOneWidget);

      expect(find.textContaining('24.'), findsNothing);
      expect(find.textContaining('46.'), findsNothing);
      expect(find.text(l10n.overtimeGpsAccuracy), findsNothing);
      expect(find.text(l10n.overtimeGpsStatus), findsNothing);
      expect(find.text(l10n.overtimeDeviceId), findsNothing);
      expect(find.text(l10n.overtimeBatteryLevel), findsNothing);
      expect(find.text(l10n.overtimeNetworkStatus), findsNothing);
      expect(find.text(l10n.overtimeLocation), findsNothing);
      expect(find.text('123 Test Street, Riyadh'), findsNothing);
      expect(find.text('dev-technician-test'), findsNothing);
      expect(find.text('82%'), findsNothing);
      expect(find.text('wifi'), findsNothing);
      expect(find.text(l10n.overtimeJourneyTimeline), findsNothing);
      expect(find.text(l10n.overtimeJourneyOverview), findsNothing);
      expect(find.text(l10n.overtimeSyncOffline), findsNothing);
      expect(find.text(l10n.overtimeSyncPending), findsNothing);
      expect(find.text(l10n.overtimeSyncSynced), findsNothing);
      expect(find.byType(OvertimeJourneyTimeline), findsNothing);
    });

    testWidgets('shows uploaded checkpoint photos without metadata', (
      tester,
    ) async {
      final session = _runningSession(
        startDone: true,
        arrivedDone: false,
        startPhotoUrl: 'https://cdn.example.com/start-photo.jpg',
      );
      final l10n = lookupAppLocalizations(const Locale('en'));

      await pumpTechnicianContent(
        tester,
        child: TechnicianOvertimeStagePhotos(session: session),
      );

      expect(find.text(l10n.overtimeImages), findsOneWidget);
      expect(find.text(l10n.overtimeStageStartJourney), findsOneWidget);
      expect(find.text(l10n.overtimeGpsAccuracy), findsNothing);
      expect(find.text('dev-technician-test'), findsNothing);
    });

    testWidgets('stage action button reflects the next checkpoint', (
      tester,
    ) async {
      final session = _runningSession(startDone: true, arrivedDone: false);
      final l10n = lookupAppLocalizations(const Locale('en'));

      await pumpTechnicianContent(
        tester,
        child: _contentFor(session),
      );

      expect(find.text(l10n.overtimeStageArrivedAtWorkSite), findsNWidgets(2));
      expect(
        find.widgetWithText(ElevatedButton, l10n.overtimeArrivedAtWorkSite),
        findsOneWidget,
      );
    });

    testWidgets('Arabic RTL keeps simplified technician layout', (tester) async {
      final session = _runningSession(startDone: true, arrivedDone: false);
      final l10n = lookupAppLocalizations(const Locale('ar'));

      await pumpTechnicianContent(
        tester,
        child: _contentFor(session),
        locale: const Locale('ar'),
      );

      expect(Directionality.of(tester.element(find.byType(Scaffold))), TextDirection.rtl);
      expect(find.text(l10n.overtimeNotes), findsOneWidget);
      expect(find.text(l10n.overtimeVoiceNote), findsOneWidget);
      expect(find.text(l10n.overtimeGpsAccuracy), findsNothing);
    });

    testWidgets('English LTR keeps simplified technician layout', (tester) async {
      final session = _runningSession(startDone: true, arrivedDone: false);
      final l10n = lookupAppLocalizations(const Locale('en'));

      await pumpTechnicianContent(
        tester,
        child: _contentFor(session),
        locale: const Locale('en'),
      );

      expect(Directionality.of(tester.element(find.byType(Scaffold))), TextDirection.ltr);
      expect(find.text(l10n.overtimeNotes), findsOneWidget);
      expect(find.text(l10n.overtimeVoiceNote), findsOneWidget);
      expect(find.text(l10n.overtimeDeviceId), findsNothing);
    });
  });

  group('Admin journey timeline remains unchanged', () {
    testWidgets('still shows technical checkpoint review details', (
      tester,
    ) async {
      final session = _runningSession(startDone: true, arrivedDone: true);
      final l10n = lookupAppLocalizations(const Locale('en'));

      await pumpTechnicianContent(
        tester,
        child: OvertimeJourneyTimeline(
          session: session,
          includeJourneyOverview: true,
          showOpenLiveLocation: true,
        ),
        width: 900,
      );

      expect(find.textContaining('GPS accuracy'), findsWidgets);
      expect(find.textContaining('Device ID'), findsWidgets);
      expect(find.text('123 Test Street, Riyadh'), findsWidgets);
      expect(find.textContaining('dev-technician-test'), findsWidgets);
      expect(find.textContaining('82%'), findsWidgets);
      expect(find.textContaining('wifi'), findsWidgets);
      expect(find.text(l10n.overtimeJourneyOverview), findsOneWidget);
    });
  });
}
