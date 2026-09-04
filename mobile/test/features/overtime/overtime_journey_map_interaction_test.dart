import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/features/attendance/domain/entities/gps_snapshot.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_checkpoint.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_status.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_technician_summary.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_type.dart';
import 'package:mobile/features/overtime/presentation/pages/overtime_admin_detail_page.dart';
import 'package:mobile/features/overtime/presentation/widgets/overtime_journey_timeline.dart';

GpsSnapshot _gps(double lat, double lng) => GpsSnapshot(
      latitude: lat,
      longitude: lng,
      accuracy: 5,
      recordedAt: DateTime.utc(2026, 8, 12, 8),
      provider: 'gps',
    );

OvertimeCheckpoint _cp(GpsSnapshot gps) => OvertimeCheckpoint(
      at: gps.recordedAt,
      gps: gps,
      address: 'Test address',
      deviceId: 'dev-1',
    );

OvertimeSession _session() {
  final start = DateTime.utc(2026, 8, 12, 8);
  return OvertimeSession(
    id: 'ot-map-test',
    companyId: 'c1',
    userId: 'u1',
    type: OvertimeType.normal,
    status: OvertimeStatus.pendingReview,
    startAt: start,
    endAt: start.add(const Duration(hours: 8)),
    startGps: _gps(24.7, 46.6),
    startDeviceId: 'dev-1',
    workflowVersion: OvertimeWorkflowVersion.v2,
    requiresManualReview: false,
    checkpoints: OvertimeCheckpoints(
      startJourney: _cp(_gps(24.70, 46.60)),
      arrivedAtWorkSite: _cp(_gps(24.72, 46.62)),
      finishedWork: _cp(_gps(24.73, 46.63)),
      endJourney: _cp(_gps(24.71, 46.61)),
    ),
    technician: const OvertimeTechnicianSummary(
      id: 'u1',
      fullName: 'Test Tech',
      email: 'tech@test.com',
      roles: ['TECHNICIAN'],
    ),
  );
}

Future<void> pumpOverview(
  WidgetTester tester, {
  required Size size,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

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
          child: OvertimeJourneyOverview(
            session: _session(),
            mapHeight: 280,
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

  group('overtimeJourneyMapInteractionFlags', () {
    test('desktop keeps drag; disables native wheel/pinch zoom paths', () {
      final flags = overtimeJourneyMapInteractionFlags(isDesktop: true);
      expect(InteractiveFlag.hasDrag(flags), isTrue);
      expect(InteractiveFlag.hasScrollWheelZoom(flags), isFalse);
      expect(InteractiveFlag.hasPinchMove(flags), isFalse);
      expect(InteractiveFlag.hasPinchZoom(flags), isFalse);
      expect(InteractiveFlag.hasRotate(flags), isFalse);
    });

    test('mobile/tablet keeps scrollWheelZoom, pinchMove, pinchZoom, and drag', () {
      final flags = overtimeJourneyMapInteractionFlags(isDesktop: false);
      expect(InteractiveFlag.hasDrag(flags), isTrue);
      expect(InteractiveFlag.hasScrollWheelZoom(flags), isTrue);
      expect(InteractiveFlag.hasPinchMove(flags), isTrue);
      expect(InteractiveFlag.hasPinchZoom(flags), isTrue);
    });
  });

  group('overtimeDesktopPanZoomScaleToZoomDelta', () {
    test('pinch out zooms in', () {
      expect(overtimeDesktopPanZoomScaleToZoomDelta(2), closeTo(1, 1e-9));
    });

    test('pinch in zooms out', () {
      expect(overtimeDesktopPanZoomScaleToZoomDelta(0.5), closeTo(-1, 1e-9));
    });

    test('invalid scale yields zero', () {
      expect(overtimeDesktopPanZoomScaleToZoomDelta(0), 0);
      expect(overtimeDesktopPanZoomScaleToZoomDelta(-1), 0);
    });
  });

  group('overtimeDesktopWheelAccumResult', () {
    test('accumulates tiny touchpad deltas until threshold', () {
      var accum = 0.0;
      var totalSteps = 0;
      for (var i = 0; i < 10; i++) {
        final r = overtimeDesktopWheelAccumResult(
          accumulated: accum,
          scrollDeltaDy: -8,
          threshold: 40,
        );
        accum = r.accumulated;
        totalSteps += r.steps;
      }
      expect(totalSteps, -2); // 80 / 40
      expect(accum.abs(), lessThan(40));
    });

    test('large mouse-wheel delta produces steps immediately', () {
      final r = overtimeDesktopWheelAccumResult(
        accumulated: 0,
        scrollDeltaDy: 120,
        threshold: 40,
      );
      expect(r.steps, 3);
    });
  });

  group('buildOvertimeDesktopMediaRowChildren', () {
    test('omits missing voice/image and does not reserve placeholders', () {
      const voice = SizedBox(key: Key('voice'));
      const image = SizedBox(key: Key('image'));
      const live = SizedBox(key: Key('live'));

      expect(
        buildOvertimeDesktopMediaRowChildren(
          voice: voice,
          image: image,
          liveLocation: live,
        ).map((w) => w.key),
        [const Key('voice'), const Key('image'), const Key('live')],
      );
      expect(
        buildOvertimeDesktopMediaRowChildren(
          image: image,
          liveLocation: live,
        ).map((w) => w.key),
        [const Key('image'), const Key('live')],
      );
      expect(
        buildOvertimeDesktopMediaRowChildren(liveLocation: live).map((w) => w.key),
        [const Key('live')],
      );
      expect(buildOvertimeDesktopMediaRowChildren(), isEmpty);
    });
  });

  group('OvertimeDesktopMediaRow equal height', () {
    Future<void> pumpRow(
      WidgetTester tester, {
      Widget? voice,
      Widget? image,
      Widget? liveLocation,
      double width = 900,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                child: OvertimeDesktopMediaRow(
                  voice: voice,
                  image: image,
                  liveLocation: liveLocation,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    void expectEqualOuterCards(WidgetTester tester, List<Key> keys) {
      expect(keys, isNotEmpty);
      final first = tester.getRect(find.byKey(keys.first));
      expect(first.height, greaterThan(0));
      for (final key in keys.skip(1)) {
        final rect = tester.getRect(find.byKey(key));
        expect(rect.height, closeTo(first.height, 0.5));
        expect(rect.top, closeTo(first.top, 0.5));
        expect(rect.bottom, closeTo(first.bottom, 0.5));
      }
      // No placeholder cells for missing content.
      final allCellKeys = [
        overtimeDesktopMediaVoiceCellKey,
        overtimeDesktopMediaImageCellKey,
        overtimeDesktopMediaLiveCellKey,
      ];
      for (final key in allCellKeys) {
        if (keys.contains(key)) {
          expect(find.byKey(key), findsOneWidget);
        } else {
          expect(find.byKey(key), findsNothing);
        }
      }
    }

    testWidgets('voice + image + live share identical outer card edges', (
      tester,
    ) async {
      await pumpRow(
        tester,
        voice: Container(height: 80, color: const Color(0xFF112233)),
        image: Container(height: 40, color: const Color(0xFF445566)),
        liveLocation: const SizedBox(
          width: 120,
          height: 48,
          child: ColoredBox(color: Color(0xFF778899)),
        ),
      );

      expectEqualOuterCards(tester, [
        overtimeDesktopMediaVoiceCellKey,
        overtimeDesktopMediaImageCellKey,
        overtimeDesktopMediaLiveCellKey,
      ]);

      // Tallest content (voice 80 + cell padding + 1px border × 2) drives height.
      final shared = tester.getRect(find.byKey(overtimeDesktopMediaVoiceCellKey));
      expect(shared.height, closeTo(80 + 2 * 8 + 2, 1));
    });

    testWidgets('image + live stretch equally when voice is missing', (
      tester,
    ) async {
      await pumpRow(
        tester,
        image: Container(height: 60, color: const Color(0xFF445566)),
        liveLocation: const SizedBox(
          width: 100,
          height: 40,
          child: ColoredBox(color: Color(0xFF778899)),
        ),
      );

      expectEqualOuterCards(tester, [
        overtimeDesktopMediaImageCellKey,
        overtimeDesktopMediaLiveCellKey,
      ]);

      // Image cell (no padding, 1px border × 2) drives height — not 260px.
      final shared = tester.getRect(find.byKey(overtimeDesktopMediaImageCellKey));
      expect(shared.height, lessThan(200));
      expect(shared.height, closeTo(60 + 2, 1));
    });

    testWidgets('voice + live stretch equally when image is missing', (
      tester,
    ) async {
      await pumpRow(
        tester,
        voice: Container(height: 90, color: const Color(0xFF112233)),
        liveLocation: const SizedBox(
          width: 100,
          height: 40,
          child: ColoredBox(color: Color(0xFF778899)),
        ),
      );

      expectEqualOuterCards(tester, [
        overtimeDesktopMediaVoiceCellKey,
        overtimeDesktopMediaLiveCellKey,
      ]);
      final shared = tester.getRect(find.byKey(overtimeDesktopMediaVoiceCellKey));
      expect(shared.height, closeTo(90 + 2 * 8 + 2, 1));
    });

    testWidgets('live-only uses compact content height without placeholders', (
      tester,
    ) async {
      await pumpRow(
        tester,
        liveLocation: const SizedBox(
          width: 100,
          height: 40,
          child: ColoredBox(color: Color(0xFF778899)),
        ),
      );

      expectEqualOuterCards(tester, [overtimeDesktopMediaLiveCellKey]);
      final live = tester.getRect(find.byKey(overtimeDesktopMediaLiveCellKey));
      expect(live.height, closeTo(40 + 2 * 8 + 2, 1));
      expect(live.height, lessThan(120));
    });
  });

  group('overtimeDesktopCenterWheelZoom', () {
    test('zooms in when scroll delta is negative (wheel up)', () {
      expect(
        overtimeDesktopCenterWheelZoom(currentZoom: 12, scrollDeltaDy: -100),
        greaterThan(12),
      );
    });

    test('zooms out when scroll delta is positive (wheel down)', () {
      expect(
        overtimeDesktopCenterWheelZoom(currentZoom: 12, scrollDeltaDy: 100),
        lessThan(12),
      );
    });

    test('clamps to min/max', () {
      expect(
        overtimeDesktopCenterWheelZoom(
          currentZoom: 3,
          scrollDeltaDy: 1000,
          minZoom: 3,
          maxZoom: 18,
        ),
        3,
      );
      expect(
        overtimeDesktopCenterWheelZoom(
          currentZoom: 18,
          scrollDeltaDy: -1000,
          minZoom: 3,
          maxZoom: 18,
        ),
        18,
      );
    });
  });

  group('applyOvertimeDesktopCenterWheelZoom', () {
    testWidgets('keeps map center stable while changing zoom', (tester) async {
      await pumpOverview(tester, size: const Size(1280, 900));
      await tester.pump(const Duration(milliseconds: 100));

      final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
      final controller = map.mapController!;
      const fixedCenter = LatLng(24.71, 46.61);
      controller.move(fixedCenter, 13);
      await tester.pump();

      final beforeCenter = controller.camera.center;
      final beforeZoom = controller.camera.zoom;

      final next = applyOvertimeDesktopCenterWheelZoom(
        controller: controller,
        scrollDeltaDy: -120,
      );
      await tester.pump();

      expect(next, isNotNull);
      expect(next, greaterThan(beforeZoom));
      expect(controller.camera.center.latitude, closeTo(beforeCenter.latitude, 1e-9));
      expect(
        controller.camera.center.longitude,
        closeTo(beforeCenter.longitude, 1e-9),
      );

      // Pan via controller — drag flag remains enabled for real pointer pans.
      controller.move(const LatLng(24.75, 46.65), controller.camera.zoom);
      await tester.pump();
      final panned = controller.camera.center;

      applyOvertimeDesktopCenterWheelZoom(
        controller: controller,
        scrollDeltaDy: 120,
      );
      await tester.pump();

      expect(controller.camera.center.latitude, closeTo(panned.latitude, 1e-9));
      expect(controller.camera.center.longitude, closeTo(panned.longitude, 1e-9));
    });
  });

  group('applyOvertimeDesktopWheelZoomSteps', () {
    testWidgets('applies discrete steps without drifting center', (tester) async {
      await pumpOverview(tester, size: const Size(1280, 900));
      await tester.pump(const Duration(milliseconds: 100));

      final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
      final controller = map.mapController!;
      const fixedCenter = LatLng(24.71, 46.61);
      controller.move(fixedCenter, 12);
      await tester.pump();

      final before = controller.camera.center;
      final next = applyOvertimeDesktopWheelZoomSteps(
        controller: controller,
        steps: -2, // zoom in
      );
      await tester.pump();

      expect(next, closeTo(12 + 2 * overtimeDesktopWheelZoomStep, 1e-9));
      expect(controller.camera.center.latitude, closeTo(before.latitude, 1e-9));
      expect(controller.camera.center.longitude, closeTo(before.longitude, 1e-9));
      expect(applyOvertimeDesktopWheelZoomSteps(controller: controller, steps: 0), isNull);
    });
  });

  group('desktop pointer signal zoom', () {
    testWidgets('PointerScrollEvent zooms while keeping center stable', (
      tester,
    ) async {
      await pumpOverview(tester, size: const Size(1280, 900));
      await tester.pump(const Duration(milliseconds: 100));

      final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
      final controller = map.mapController!;
      const fixedCenter = LatLng(24.72, 46.62);
      controller.move(fixedCenter, 13);
      await tester.pump();

      final mapBox = tester.getRect(find.byType(FlutterMap));
      final local = mapBox.center;

      // Simulate a large mouse-wheel notch (exceeds accum threshold).
      await tester.sendEventToBinding(
        PointerScrollEvent(
          position: local,
          scrollDelta: const Offset(0, -120),
        ),
      );
      await tester.pump();

      expect(controller.camera.zoom, greaterThan(13));
      expect(
        controller.camera.center.latitude,
        closeTo(fixedCenter.latitude, 1e-9),
      );
      expect(
        controller.camera.center.longitude,
        closeTo(fixedCenter.longitude, 1e-9),
      );

      final zoomAfterIn = controller.camera.zoom;
      await tester.sendEventToBinding(
        PointerScrollEvent(
          position: local,
          scrollDelta: const Offset(0, 120),
        ),
      );
      await tester.pump();

      expect(controller.camera.zoom, lessThan(zoomAfterIn));
      expect(
        controller.camera.center.latitude,
        closeTo(fixedCenter.latitude, 1e-9),
      );
      expect(
        controller.camera.center.longitude,
        closeTo(fixedCenter.longitude, 1e-9),
      );
    });
  });

  group('overtimeDesktopDetailColumnFlex', () {
    test('is consistently ~35/65 for Technician | Session', () {
      for (final width in [900.0, 1080.0, 1280.0, 1440.0, 1920.0]) {
        final flex = overtimeDesktopDetailColumnFlex(width);
        expect(flex.startFlex, 7);
        expect(flex.endFlex, 13);
        expect(
          flex.startFlex / (flex.startFlex + flex.endFlex),
          closeTo(0.35, 0.001),
        );
      }
    });
  });

  group('Journey Overview FlutterMap wiring', () {
    testWidgets('desktop MapOptions keep drag and disable native wheel zoom', (
      tester,
    ) async {
      await pumpOverview(tester, size: const Size(1280, 900));

      final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
      final flags = map.options.interactionOptions.flags;
      expect(InteractiveFlag.hasDrag(flags), isTrue);
      expect(InteractiveFlag.hasScrollWheelZoom(flags), isFalse);
      expect(InteractiveFlag.hasPinchMove(flags), isFalse);
      expect(InteractiveFlag.hasPinchZoom(flags), isFalse);
      expect(map.options.keepAlive, isTrue);

      // Desktop-only wheel interceptor uses translucent Listener with
      // pointer-signal + pan-zoom handlers (Windows touchpad).
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Listener &&
              w.behavior == HitTestBehavior.translucent &&
              w.onPointerSignal != null &&
              w.onPointerPanZoomUpdate != null,
        ),
        findsOneWidget,
      );
    });

    testWidgets('phone keeps native scrollWheelZoom, pinchMove, and drag', (
      tester,
    ) async {
      await pumpOverview(tester, size: const Size(480, 844));

      final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
      final flags = map.options.interactionOptions.flags;
      expect(InteractiveFlag.hasDrag(flags), isTrue);
      expect(InteractiveFlag.hasScrollWheelZoom(flags), isTrue);
      expect(InteractiveFlag.hasPinchMove(flags), isTrue);

      // Desktop translucent wheel Listener is not applied on phone.
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Listener &&
              w.behavior == HitTestBehavior.translucent &&
              w.onPointerSignal != null,
        ),
        findsNothing,
      );
    });

    testWidgets('rebuild does not remount MapController identity', (tester) async {
      await pumpOverview(tester, size: const Size(1280, 900));
      final first = tester.widget<FlutterMap>(find.byType(FlutterMap));
      final controller = first.mapController;

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
              child: OvertimeJourneyOverview(
                session: _session(),
                mapHeight: 320,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final second = tester.widget<FlutterMap>(find.byType(FlutterMap));
      expect(identical(second.mapController, controller), isTrue);
    });
  });
}
