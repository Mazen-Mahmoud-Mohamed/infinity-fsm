import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/cache/session_query_cache.dart';
import 'package:mobile/core/constants/permissions.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/services/auth_session_service.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/attendance/domain/entities/gps_snapshot.dart';
import 'package:mobile/features/auth/domain/entities/current_user.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobile/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:mobile/features/auth/domain/usecases/logout_all_devices_usecase.dart';
import 'package:mobile/features/auth/domain/usecases/logout_usecase.dart';
import 'package:mobile/features/auth/domain/usecases/restore_session_usecase.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_checkpoint.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_status.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_technician_summary.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_type.dart';
import 'package:mobile/features/overtime/domain/repositories/overtime_repository.dart';
import 'package:mobile/features/overtime/domain/usecases/approve_overtime_usecase.dart';
import 'package:mobile/features/overtime/domain/usecases/get_overtime_by_id_usecase.dart';
import 'package:mobile/features/overtime/domain/usecases/reject_overtime_usecase.dart';
import 'package:mobile/features/overtime/presentation/cubit/overtime_detail_cubit.dart';
import 'package:mobile/features/overtime/presentation/pages/overtime_admin_detail_page.dart';
import 'package:mobile/features/overtime/presentation/widgets/overtime_voice_note_section.dart';

GpsSnapshot _gps(DateTime at, {double lat = 24.7, double lng = 46.6}) =>
    GpsSnapshot(
      latitude: lat,
      longitude: lng,
      accuracy: 5,
      recordedAt: at,
      provider: 'gps',
    );

OvertimeCheckpoint _cp(
  DateTime at, {
  String? photoUrl,
  OvertimeVoiceNote? voiceNote,
  double lat = 24.7,
  double lng = 46.6,
}) =>
    OvertimeCheckpoint(
      at: at,
      gps: _gps(at, lat: lat, lng: lng),
      address: 'Riyadh Test Site',
      deviceId: 'dev-1',
      batteryLevel: 80,
      networkStatus: 'wifi',
      photoUrl: photoUrl,
      voiceNote: voiceNote,
      notes: 'Checkpoint notes',
    );

OvertimeSession _session({
  OvertimeVoiceNote? voice,
  String? photoUrl = 'https://example.com/ot.jpg',
}) {
  final start = DateTime.utc(2026, 8, 12, 8);
  return OvertimeSession(
    id: 'ot-voice-1',
    companyId: 'c1',
    userId: 'u1',
    type: OvertimeType.normal,
    status: OvertimeStatus.pendingReview,
    startAt: start,
    endAt: start.add(const Duration(hours: 10)),
    startGps: _gps(start),
    startDeviceId: 'd1',
    createdAt: start,
    totalDurationMinutes: 600,
    workingDurationMinutes: 480,
    eligibleOvertimeMinutes: 120,
    technician: const OvertimeTechnicianSummary(
      id: 'u1',
      fullName: 'Field Technician',
      email: 'tech@test.com',
      roles: ['TECHNICIAN'],
    ),
    workflowVersion: OvertimeWorkflowVersion.v2,
    requiresManualReview: true,
    checkpoints: OvertimeCheckpoints(
      startJourney: _cp(
        start,
        voiceNote: voice,
        photoUrl: photoUrl,
        lat: 24.70,
        lng: 46.60,
      ),
      arrivedAtWorkSite: _cp(
        start.add(const Duration(hours: 1)),
        photoUrl: photoUrl,
        lat: 24.72,
        lng: 46.62,
      ),
      finishedWork: _cp(
        start.add(const Duration(hours: 8)),
        lat: 24.73,
        lng: 46.63,
      ),
      endJourney: _cp(
        start.add(const Duration(hours: 9)),
        lat: 24.71,
        lng: 46.61,
      ),
    ),
  );
}

class _NoopOvertimeRepo extends Fake implements OvertimeRepository {}

class _FakeGetById extends GetOvertimeByIdUseCase {
  _FakeGetById(this.session) : super(_NoopOvertimeRepo());
  final OvertimeSession session;

  @override
  Future<Result<OvertimeSession>> call(String id) async => Success(session);
}

class _FakeApprove extends ApproveOvertimeUseCase {
  _FakeApprove() : super(_NoopOvertimeRepo());
}

class _FakeReject extends RejectOvertimeUseCase {
  _FakeReject() : super(_NoopOvertimeRepo());
}

class _FakeAuthRepo extends Fake implements AuthRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthSessionService sessionService;
  late AuthCubit authCubit;

  const admin = CurrentUser(
    id: 'admin-1',
    companyId: 'c1',
    email: 'admin@example.com',
    firstName: 'Admin',
    lastName: 'User',
    fullName: 'Admin User',
    roles: ['ADMIN'],
    permissions: [
      Permissions.overtimeApprove,
      Permissions.overtimeReject,
      Permissions.overtimeViewAll,
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
    debugOvertimeAudioPlayerFactory = null;
  });

  tearDown(() async {
    debugOvertimeAudioPlayerFactory = null;
    await authCubit.close();
    sessionService.dispose();
  });

  Future<void> pumpDetail(
    WidgetTester tester, {
    required OvertimeSession session,
    Size size = const Size(1280, 900),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final detailCubit = OvertimeDetailCubit(
      getById: _FakeGetById(session),
      approve: _FakeApprove(),
      reject: _FakeReject(),
      sessionId: session.id,
    );
    addTearDown(detailCubit.close);

    await detailCubit.load();
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
        home: BlocProvider.value(
          value: authCubit,
          child: OvertimeAdminDetailPage(
            sessionId: session.id,
            detailCubit: detailCubit,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  Future<void> scrollUntilVisible(WidgetTester tester, Finder target) async {
    final list = find.byType(ListView);
    for (var i = 0; i < 30 && target.evaluate().isEmpty; i++) {
      await tester.drag(list, const Offset(0, -320));
      await tester.pump();
    }
  }

  group('isOvertimeVoiceRemoteUrlValid', () {
    test('accepts http(s) URLs with host', () {
      expect(
        isOvertimeVoiceRemoteUrlValid('https://res.cloudinary.com/x/voice.m4a'),
        isTrue,
      );
      expect(isOvertimeVoiceRemoteUrlValid('http://cdn.example/a.mp3'), isTrue);
    });

    test('rejects missing/invalid URLs', () {
      expect(isOvertimeVoiceRemoteUrlValid(null), isFalse);
      expect(isOvertimeVoiceRemoteUrlValid(''), isFalse);
      expect(isOvertimeVoiceRemoteUrlValid('local-pending'), isFalse);
      expect(isOvertimeVoiceRemoteUrlValid('not-a-url'), isFalse);
      expect(isOvertimeVoiceRemoteUrlValid('https://'), isFalse);
      expect(isOvertimeVoiceRemoteUrlValid('ftp://files/a.m4a'), isFalse);
    });
  });

  group('Overtime Details voice robustness', () {
    testWidgets('valid voice note URL still renders the details page', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        session: _session(
          voice: const OvertimeVoiceNote(
            url: 'https://res.cloudinary.com/demo/video/upload/voice.m4a',
            duration: 12,
            format: 'm4a',
          ),
        ),
      );

      expect(find.text('Technician Information'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await scrollUntilVisible(tester, find.text('Voice Note'));
      expect(find.text('Voice Note'), findsWidgets);
      expect(find.text('Journey timeline'), findsOneWidget);
      expect(find.text('Open Live Location'), findsWidgets);
    });

    testWidgets('invalid voice URL keeps page rendering with unavailable state', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        session: _session(
          voice: const OvertimeVoiceNote(
            url: 'not-a-valid-audio-url',
            duration: 5,
          ),
        ),
      );

      expect(find.text('Technician Information'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await scrollUntilVisible(tester, find.text('Voice note unavailable'));
      expect(find.text('Voice note unavailable'), findsOneWidget);
      expect(find.text('Journey timeline'), findsOneWidget);
      expect(find.text('Open Live Location'), findsWidgets);
    });

    testWidgets('player init failure isolates to voice unavailable UI', (
      tester,
    ) async {
      debugOvertimeAudioPlayerFactory = () {
        throw StateError('simulated AudioPlayer init failure');
      };

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
          home: const Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: OvertimeVoiceNoteSection(
                  remoteUrl:
                      'https://res.cloudinary.com/demo/video/upload/voice.m4a',
                  durationSeconds: 8,
                  readOnly: true,
                  compact: true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Voice Note'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Voice note unavailable'), findsOneWidget);
      expect(find.text('Voice Note'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'details page with voice stays visible when player factory is broken',
      (tester) async {
        debugOvertimeAudioPlayerFactory = () {
          throw StateError('simulated AudioPlayer init failure');
        };

        await pumpDetail(
          tester,
          session: _session(
            voice: const OvertimeVoiceNote(
              url: 'https://res.cloudinary.com/demo/video/upload/voice.m4a',
              duration: 8,
            ),
          ),
        );

        expect(find.text('Technician Information'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await scrollUntilVisible(tester, find.text('Voice Note'));
        expect(find.text('Voice Note'), findsWidgets);
        expect(find.text('Open Live Location'), findsWidgets);
      },
    );

    testWidgets('no voice note does not reserve a Voice Note card', (
      tester,
    ) async {
      await pumpDetail(tester, session: _session(voice: null));

      expect(find.text('Technician Information'), findsOneWidget);
      await scrollUntilVisible(tester, find.text('Journey timeline'));
      expect(find.text('Voice Note'), findsNothing);
      expect(find.text('Voice note unavailable'), findsNothing);
      expect(find.text('Open Live Location'), findsWidgets);
    });
  });
}
