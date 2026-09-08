import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/cache/session_query_cache.dart';
import 'package:mobile/core/constants/permissions.dart';
import 'package:mobile/core/geo/gps_snapshot.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/services/address_resolver_service.dart';
import 'package:mobile/core/services/auth_session_service.dart';
import 'package:mobile/core/services/checkpoint_telemetry_service.dart';
import 'package:mobile/core/services/connectivity_service.dart';
import 'package:mobile/core/services/device_time_guard_service.dart';
import 'package:mobile/core/services/gps_address_sync_service.dart';
import 'package:mobile/core/services/gps_service.dart';
import 'package:mobile/core/services/logger_service.dart';
import 'package:mobile/core/services/selfie_capture_service.dart';
import 'package:mobile/core/storage/preferences_service.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/core/widgets/app_loader.dart';
import 'package:mobile/features/auth/domain/entities/current_user.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobile/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:mobile/features/auth/domain/usecases/logout_all_devices_usecase.dart';
import 'package:mobile/features/auth/domain/usecases/logout_usecase.dart';
import 'package:mobile/features/auth/domain/usecases/restore_session_usecase.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:mobile/features/notifications/domain/usecases/notifications_usecases.dart';
import 'package:mobile/features/notifications/presentation/cubit/notifications_unread_cubit.dart';
import 'package:mobile/features/overtime/data/datasources/overtime_local_datasource.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_checkpoint.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_status.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_technician_summary.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_type.dart';
import 'package:mobile/features/overtime/domain/repositories/overtime_repository.dart';
import 'package:mobile/features/overtime/domain/services/overtime_upload_policy_service.dart';
import 'package:mobile/features/overtime/domain/usecases/end_overtime_usecase.dart';
import 'package:mobile/features/overtime/domain/usecases/get_running_overtime_usecase.dart';
import 'package:mobile/features/overtime/domain/usecases/record_overtime_checkpoint_usecase.dart';
import 'package:mobile/features/overtime/domain/usecases/start_overtime_usecase.dart';
import 'package:mobile/features/overtime/presentation/cubit/overtime_cubit.dart';
import 'package:mobile/features/overtime/presentation/cubit/overtime_state.dart';
import 'package:mobile/features/overtime/presentation/cubit/overtime_sync_cubit.dart';
import 'package:mobile/features/overtime/presentation/pages/overtime_page.dart';
import 'package:mobile/features/overtime/presentation/widgets/overtime_tracking_skeleton.dart';
import 'package:mobile/features/overtime/presentation/widgets/technician_overtime_running_card.dart';
import 'package:mobile/features/settings/domain/entities/settings_entities.dart';
import 'package:mobile/features/settings/domain/repositories/settings_repository.dart';
import 'package:mobile/features/settings/domain/usecases/settings_usecases.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

GpsSnapshot _gps() => GpsSnapshot(
      latitude: 24.7,
      longitude: 46.6,
      accuracy: 5,
      recordedAt: DateTime.utc(2026, 3, 1, 8),
      provider: 'gps',
    );

OvertimeSession _runningSession() {
  final start = DateTime.utc(2026, 3, 1, 8);
  return OvertimeSession(
    id: 'ot-run',
    companyId: 'c1',
    userId: 'u1',
    type: OvertimeType.normal,
    status: OvertimeStatus.running,
    startAt: start,
    startGps: _gps(),
    startDeviceId: 'dev-1',
    createdAt: start,
    workflowVersion: OvertimeWorkflowVersion.v2,
    technician: const OvertimeTechnicianSummary(
      id: 'u1',
      fullName: 'Field Tech',
    ),
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

class _FakeOtRepo extends Fake implements OvertimeRepository {}

class _FakeAuthRepo extends Fake implements AuthRepository {}

class _FakeNotifRepo extends Fake implements NotificationsRepository {}

class _FakeTimeGuard extends Fake implements DeviceTimeGuardService {
  @override
  Future<DeviceTimeCheckResult> validate({
    DateTime? lastCaptureAt,
    String module = 'overtime',
  }) async =>
      const DeviceTimeCheckResult.ok();

  @override
  Future<void> syncSecurityEvents() async {}
}

class _FakeAddress extends Fake implements AddressResolverService {}

class _FakeGpsSync extends Fake implements GpsAddressSyncService {}

class _FakeTelemetry extends Fake implements CheckpointTelemetryService {}

class _FakeConnectivity extends Fake implements ConnectivityService {
  @override
  Future<bool> get isConnected async => true;

  @override
  Future<List<ConnectivityResult>> get connectionTypes async =>
      const [ConnectivityResult.wifi];
}

class _FakeSettingsRepo extends Fake implements SettingsRepository {}

class _FakeMediaConfig extends GetOvertimeMediaConfigUseCase {
  _FakeMediaConfig() : super(_FakeSettingsRepo());

  @override
  Future<Result<OvertimeMediaConfigEntity>> call() async =>
      Success(OvertimeMediaConfigEntity.defaults());
}

class _FakeSyncCubit extends Fake implements OvertimeSyncCubit {
  @override
  OvertimeSyncState get state => const OvertimeSyncState();

  @override
  Stream<OvertimeSyncState> get stream => const Stream.empty();

  @override
  bool get isClosed => false;
}

class _TestOvertimeCubit extends OvertimeCubit {
  _TestOvertimeCubit({
    required OvertimeState initial,
    required PreferencesService preferences,
  }) : super(
          getRunningOvertimeUseCase: GetRunningOvertimeUseCase(_FakeOtRepo()),
          startOvertimeUseCase: StartOvertimeUseCase(_FakeOtRepo()),
          endOvertimeUseCase: EndOvertimeUseCase(_FakeOtRepo()),
          recordCheckpointUseCase:
              RecordOvertimeCheckpointUseCase(_FakeOtRepo()),
          gpsService: GpsService(),
          selfieCaptureService: SelfieCaptureService(),
          addressResolverService: _FakeAddress(),
          deviceTimeGuard: _FakeTimeGuard(),
          gpsAddressSync: _FakeGpsSync(),
          preferencesService: preferences,
          connectivityService: _FakeConnectivity(),
          checkpointTelemetryService: _FakeTelemetry(),
          sessionQueryCache: SessionQueryCache(),
          localDataSource: OvertimeLocalDataSource(preferences),
          overtimeSyncCubit: _FakeSyncCubit(),
          getMediaConfigUseCase: _FakeMediaConfig(),
          uploadPolicyService: OvertimeUploadPolicyService(
            connectivity: _FakeConnectivity(),
            sessionQueryCache: SessionQueryCache(),
          ),
          loggerService: LoggerService(),
        ) {
    emit(initial);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthCubit authCubit;
  late AuthSessionService session;
  late NotificationsUnreadCubit unreadCubit;
  late PreferencesService prefs;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = PreferencesService(await SharedPreferences.getInstance());
  });

  setUp(() {
    session = AuthSessionService();
    authCubit = AuthCubit(
      restoreSessionUseCase: RestoreSessionUseCase(_FakeAuthRepo()),
      getCurrentUserUseCase: GetCurrentUserUseCase(_FakeAuthRepo()),
      logoutUseCase: LogoutUseCase(_FakeAuthRepo()),
      logoutAllDevicesUseCase: LogoutAllDevicesUseCase(_FakeAuthRepo()),
      authSessionService: session,
      sessionQueryCache: SessionQueryCache(),
    )..setAuthenticated(
        const CurrentUser(
          id: 't1',
          companyId: 'c1',
          email: 'tech@example.com',
          firstName: 'Field',
          lastName: 'Tech',
          fullName: 'Field Tech',
          roles: ['TECHNICIAN'],
          permissions: [Permissions.overtimeCreate],
        ),
      );
    unreadCubit = NotificationsUnreadCubit(
      getUnreadCount: GetNotificationsUnreadCountUseCase(_FakeNotifRepo()),
      repository: _FakeNotifRepo(),
    );
  });

  tearDown(() async {
    await unreadCubit.close();
    await authCubit.close();
    session.dispose();
  });

  Future<void> pumpTracking(
    WidgetTester tester,
    OvertimeCubit cubit, {
    Size size = const Size(400, 1400),
    TextDirection direction = TextDirection.ltr,
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
        home: Directionality(
          textDirection: direction,
          child: MediaQuery(
            data: MediaQueryData(size: size),
            child: MultiBlocProvider(
              providers: [
                BlocProvider<AuthCubit>.value(value: authCubit),
                BlocProvider<NotificationsUnreadCubit>.value(
                  value: unreadCubit,
                ),
                BlocProvider<OvertimeSyncCubit>.value(value: _FakeSyncCubit()),
              ],
              child: OvertimePage(debugCubit: cubit),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('loading with no session shows tracking skeleton not spinner',
      (tester) async {
    final cubit = _TestOvertimeCubit(
      initial: const OvertimeState(status: OvertimeLoadStatus.loading),
      preferences: prefs,
    );
    addTearDown(cubit.close);

    await pumpTracking(tester, cubit);

    expect(find.byType(OvertimeTrackingSkeleton), findsOneWidget);
    expect(find.byType(AppLoader), findsNothing);
    expect(find.text('Start overtime journey'), findsNothing);
    expect(find.text('Loading overtime...'), findsNothing);
  });

  testWidgets('initial with no session shows tracking skeleton', (tester) async {
    final cubit = _TestOvertimeCubit(
      initial: const OvertimeState(),
      preferences: prefs,
    );
    addTearDown(cubit.close);
    await pumpTracking(tester, cubit, size: const Size(720, 1400));
    expect(find.byType(OvertimeTrackingSkeleton), findsOneWidget);
    expect(find.byType(AppLoader), findsNothing);
  });

  testWidgets('ready idle start form is kept while refreshing', (tester) async {
    final cubit = _TestOvertimeCubit(
      initial: const OvertimeState(
        status: OvertimeLoadStatus.ready,
        isRefreshing: true,
      ),
      preferences: prefs,
    );
    addTearDown(cubit.close);
    await pumpTracking(tester, cubit);

    expect(find.byType(OvertimeTrackingSkeleton), findsNothing);
    expect(find.text('Start overtime journey'), findsOneWidget);
    expect(find.byType(AppLoader), findsNothing);
  });

  testWidgets('running session remains visible while refreshing',
      (tester) async {
    final cubit = _TestOvertimeCubit(
      initial: OvertimeState(
        status: OvertimeLoadStatus.ready,
        session: _runningSession(),
        isRefreshing: true,
      ),
      preferences: prefs,
    );
    addTearDown(cubit.close);
    await pumpTracking(tester, cubit, size: const Size(1100, 900));

    expect(find.byType(OvertimeTrackingSkeleton), findsNothing);
    expect(find.byType(TechnicianOvertimeRunningCard), findsOneWidget);
    expect(find.byType(AppLoader), findsNothing);
  });

  testWidgets('start mutation keeps form and button spinner', (tester) async {
    final cubit = _TestOvertimeCubit(
      initial: const OvertimeState(
        status: OvertimeLoadStatus.actionInProgress,
        busyAction: OvertimeBusyAction.startNormal,
      ),
      preferences: prefs,
    );
    addTearDown(cubit.close);
    await pumpTracking(tester, cubit);

    expect(find.byType(OvertimeTrackingSkeleton), findsNothing);
    expect(find.text('Start overtime journey'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(AppLoader), findsNothing);
  });

  testWidgets('desktop first-load skeleton has no overflow', (tester) async {
    final cubit = _TestOvertimeCubit(
      initial: const OvertimeState(status: OvertimeLoadStatus.loading),
      preferences: prefs,
    );
    addTearDown(cubit.close);
    await pumpTracking(tester, cubit, size: const Size(1100, 900));
    expect(find.byType(OvertimeTrackingSkeleton), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('RTL first-load skeleton has no overflow', (tester) async {
    final cubit = _TestOvertimeCubit(
      initial: const OvertimeState(status: OvertimeLoadStatus.loading),
      preferences: prefs,
    );
    addTearDown(cubit.close);
    await pumpTracking(
      tester,
      cubit,
      size: const Size(720, 1400),
      direction: TextDirection.rtl,
    );
    expect(find.byType(OvertimeTrackingSkeleton), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
