import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/geo/gps_snapshot.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_checkpoint.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_status.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_type.dart';
import 'package:mobile/features/overtime/presentation/cubit/overtime_state.dart';
import 'package:mobile/features/overtime/presentation/widgets/technician_overtime_running_card.dart';

GpsSnapshot _gps() => GpsSnapshot(
      latitude: 24.7,
      longitude: 46.6,
      accuracy: 5,
      recordedAt: DateTime.utc(2026, 3, 1, 8),
      provider: 'gps',
    );

OvertimeSession _running() {
  final start = DateTime.utc(2026, 3, 1, 8);
  return OvertimeSession(
    id: 'ot-1',
    companyId: 'c1',
    userId: 'u1',
    type: OvertimeType.normal,
    status: OvertimeStatus.running,
    startAt: start,
    startGps: _gps(),
    startDeviceId: 'dev-1',
    workflowVersion: OvertimeWorkflowVersion.v2,
    checkpoints: OvertimeCheckpoints(
      startJourney: OvertimeCheckpoint(
        at: start,
        gps: _gps(),
        deviceId: 'dev-1',
      ),
    ),
    nextCheckpoint: OvertimeCheckpointStage.arrivedAtWorkSite,
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required Widget child,
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
      home: Scaffold(
        body: SingleChildScrollView(child: child),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows red Cancel Overtime and opens confirmation', (tester) async {
    var cancelCalls = 0;
    final l10n = lookupAppLocalizations(const Locale('en'));
    final session = _running();

    await _pump(
      tester,
      child: TechnicianOvertimeRunningContent(
        session: session,
        nextStage: session.effectiveNextCheckpoint,
        isBusy: false,
        busyAction: null,
        canCancel: true,
        onAdvance: () {},
        onCancel: () => cancelCalls++,
        elapsedSeconds: 10,
        voiceMaxDurationSeconds: 300,
        voiceRecordingQuality: 'medium',
        onNotesChanged: (_) {},
        onVoiceDraftChanged: (_) {},
      ),
    );

    expect(find.byKey(const Key('overtime-cancel-button')), findsOneWidget);
    expect(find.text(l10n.overtimeCancel), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('overtime-cancel-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('overtime-cancel-button')));
    await tester.pumpAndSettle();

    expect(find.text(l10n.overtimeCancelConfirmTitle), findsOneWidget);
    expect(find.text(l10n.overtimeCancelConfirmMessage), findsOneWidget);
    expect(cancelCalls, 0);

    await tester.tap(find.text(l10n.no));
    await tester.pumpAndSettle();
    expect(cancelCalls, 0);
    expect(find.text(l10n.overtimeCancelConfirmTitle), findsNothing);

    await tester.ensureVisible(find.byKey(const Key('overtime-cancel-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('overtime-cancel-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.overtimeCancelConfirmYes));
    await tester.pumpAndSettle();
    expect(cancelCalls, 1);
  });

  testWidgets('disables cancel while busy and hides without permission', (
    tester,
  ) async {
    final session = _running();

    await _pump(
      tester,
      child: TechnicianOvertimeRunningContent(
        session: session,
        nextStage: session.effectiveNextCheckpoint,
        isBusy: true,
        busyAction: OvertimeBusyAction.cancel,
        canCancel: true,
        onAdvance: () {},
        onCancel: () {},
        elapsedSeconds: 10,
        voiceMaxDurationSeconds: 300,
        voiceRecordingQuality: 'medium',
        onNotesChanged: (_) {},
        onVoiceDraftChanged: (_) {},
      ),
    );

    final button = tester.widget<FilledButton>(
      find.byKey(const Key('overtime-cancel-button')),
    );
    expect(button.onPressed, isNull);

    await _pump(
      tester,
      child: TechnicianOvertimeRunningContent(
        session: session,
        nextStage: session.effectiveNextCheckpoint,
        isBusy: false,
        busyAction: null,
        canCancel: false,
        onAdvance: () {},
        onCancel: () {},
        elapsedSeconds: 10,
        voiceMaxDurationSeconds: 300,
        voiceRecordingQuality: 'medium',
        onNotesChanged: (_) {},
        onVoiceDraftChanged: (_) {},
      ),
    );
    expect(find.byKey(const Key('overtime-cancel-button')), findsNothing);
  });
}
