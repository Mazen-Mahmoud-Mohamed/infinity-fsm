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

GpsSnapshot _gps() => GpsSnapshot(
      latitude: 24.7,
      longitude: 46.6,
      accuracy: 5,
      recordedAt: DateTime.utc(2026, 8, 12, 8),
      provider: 'gps',
    );

OvertimeCheckpoint _cp(DateTime at) => OvertimeCheckpoint(
      at: at,
      gps: _gps(),
      address: 'Test address',
      deviceId: 'dev-1',
    );

OvertimeSession _v2Session({
  bool startDone = true,
  bool arrivedDone = true,
  bool finishedDone = false,
  bool endDone = false,
}) {
  final base = DateTime.utc(2026, 8, 12, 8);
  return OvertimeSession(
    id: 'ot-layout-test',
    companyId: 'c1',
    userId: 'u1',
    type: OvertimeType.normal,
    status: OvertimeStatus.pendingReview,
    startAt: base,
    endAt: null,
    startGps: _gps(),
    startDeviceId: 'dev-1',
    workflowVersion: OvertimeWorkflowVersion.v2,
    requiresManualReview: false,
    checkpoints: OvertimeCheckpoints(
      startJourney: startDone ? _cp(base) : null,
      arrivedAtWorkSite: arrivedDone ? _cp(base.add(const Duration(hours: 1))) : null,
      finishedWork: finishedDone ? _cp(base.add(const Duration(hours: 6))) : null,
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

Future<void> pumpTimeline(
  WidgetTester tester, {
  required OvertimeSession session,
  required double width,
  Locale locale = const Locale('ar'),
}) async {
  tester.view.physicalSize = Size(width, 1200);
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
            child: OvertimeJourneyTimeline(
              session: session,
              includeJourneyOverview: false,
              showOpenLiveLocation: false,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OvertimeJourneyTimeline – icon-inside-card layout', () {
    testWidgets(
      'completed check icon is inside the Card, not a leading external column (Arabic 390px)',
      (tester) async {
        final session = _v2Session(
          startDone: true,
          arrivedDone: true,
          finishedDone: false,
          endDone: false,
        );
        await pumpTimeline(tester, session: session, width: 390);

        // Cards exist.
        expect(find.byType(Card), findsWidgets);

        // The check Icon (Icons.check) must exist and must be a DESCENDANT of a Card.
        final checkIconFinder = find.byWidgetPredicate(
          (w) => w is Icon && w.icon == Icons.check,
        );
        expect(checkIconFinder, findsWidgets);

        for (final el in checkIconFinder.evaluate()) {
          bool foundCardAncestor = false;
          el.visitAncestorElements((ancestor) {
            if (ancestor.widget is Card) {
              foundCardAncestor = true;
              return false; // stop walking
            }
            return true;
          });
          expect(
            foundCardAncestor,
            isTrue,
            reason: 'Every check icon must be inside a Card widget',
          );
        }
      },
    );

    testWidgets(
      'no Card is preceded by a sibling external indicator Row column (360px)',
      (tester) async {
        final session = _v2Session(
          startDone: true,
          arrivedDone: true,
          finishedDone: false,
          endDone: false,
        );
        await pumpTimeline(tester, session: session, width: 360);

        // The _TimelineStageTile used to be a Row([indicator, Expanded(Card)]).
        // After the fix it is just a Card at the top level.
        // Verify: each Card's left edge is NOT pushed inward by an external
        // indicator column — i.e. no Card has its left offset > (padding + ~50px).
        for (final cardElement in find.byType(Card).evaluate()) {
          final renderBox =
              cardElement.renderObject as RenderBox?;
          if (renderBox == null || !renderBox.hasSize) continue;
          final globalOffset = renderBox.localToGlobal(Offset.zero);
          // With 16px padding and no external column the card starts near x=16.
          // If an external indicator column (≈ 28–44px) + gap (8px) were still
          // present, the card's left edge would be at least 50+px from the left.
          expect(
            globalOffset.dx,
            lessThan(52),
            reason: 'Card should start near the left padding, not offset by an external indicator column',
          );
        }
      },
    );

    testWidgets(
      'pending stage shows circle_outlined icon inside its Card (not a check)',
      (tester) async {
        final session = _v2Session(
          startDone: true,
          arrivedDone: false,
          finishedDone: false,
          endDone: false,
        );
        await pumpTimeline(tester, session: session, width: 390);

        final pendingIconFinder = find.byWidgetPredicate(
          (w) => w is Icon && w.icon == Icons.circle_outlined,
        );
        expect(pendingIconFinder, findsWidgets);

        for (final el in pendingIconFinder.evaluate()) {
          bool foundCardAncestor = false;
          el.visitAncestorElements((ancestor) {
            if (ancestor.widget is Card) {
              foundCardAncestor = true;
              return false;
            }
            return true;
          });
          expect(foundCardAncestor, isTrue,
              reason: 'Pending icon must also be inside a Card');
        }
      },
    );

    testWidgets(
      'layout renders without overflow on 360px narrow phone (Arabic RTL)',
      (tester) async {
        final session = _v2Session(
          startDone: true,
          arrivedDone: true,
          finishedDone: true,
          endDone: true,
        );
        await pumpTimeline(tester, session: session, width: 360, locale: const Locale('ar'));

        // No RenderFlex overflow exception means layout is correct.
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'layout renders without overflow on 390px phone (English LTR)',
      (tester) async {
        final session = _v2Session(
          startDone: true,
          arrivedDone: true,
          finishedDone: false,
          endDone: false,
        );
        await pumpTimeline(tester, session: session, width: 390, locale: const Locale('en'));

        expect(tester.takeException(), isNull);
        // English stage titles are present.
        expect(find.text('Start Journey'), findsOneWidget);
        expect(find.text('Arrived at Work Site'), findsOneWidget);
      },
    );
  });
}
