import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/cache/session_query_cache.dart';
import 'package:mobile/core/geo/gps_snapshot.dart';
import 'package:mobile/core/services/address_resolver_service.dart';
import 'package:mobile/core/services/checkpoint_telemetry_service.dart';
import 'package:mobile/core/services/connectivity_service.dart';
import 'package:mobile/core/services/device_time_guard_service.dart';
import 'package:mobile/core/services/gps_address_sync_service.dart';
import 'package:mobile/core/services/gps_service.dart';
import 'package:mobile/core/services/logger_service.dart';
import 'package:mobile/core/services/selfie_capture_service.dart';
import 'package:mobile/core/storage/preferences_service.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/overtime/data/datasources/overtime_local_datasource.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_checkpoint.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_status.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_type.dart';
import 'package:mobile/features/overtime/domain/repositories/overtime_repository.dart';
import 'package:mobile/features/overtime/domain/services/overtime_upload_policy_service.dart';
import 'package:mobile/features/overtime/domain/usecases/cancel_overtime_usecase.dart';
import 'package:mobile/features/overtime/domain/usecases/end_overtime_usecase.dart';
import 'package:mobile/features/overtime/domain/usecases/get_running_overtime_usecase.dart';
import 'package:mobile/features/overtime/domain/usecases/record_overtime_checkpoint_usecase.dart';
import 'package:mobile/features/overtime/domain/usecases/start_overtime_usecase.dart';
import 'package:mobile/features/overtime/presentation/cubit/overtime_cubit.dart';
import 'package:mobile/features/overtime/presentation/cubit/overtime_state.dart';
import 'package:mobile/features/overtime/presentation/cubit/overtime_sync_cubit.dart';
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

OvertimeSession _running() {
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

class _CancelRepo extends Fake implements OvertimeRepository {
  int cancelCalls = 0;
  Result<OvertimeSession>? nextResult;

  @override
  Future<Result<OvertimeSession>> cancelSession({
    required String sessionId,
  }) async {
    cancelCalls += 1;
    return nextResult ??
        Success(
          OvertimeSession(
            id: sessionId,
            companyId: 'c1',
            userId: 'u1',
            type: OvertimeType.normal,
            status: OvertimeStatus.cancelled,
            startAt: DateTime.utc(2026, 3, 1, 8),
            startGps: _gps(),
            startDeviceId: 'dev-1',
          ),
        );
  }
}

class _FakeSyncCubit extends Fake implements OvertimeSyncCubit {
  @override
  OvertimeSyncState get state => const OvertimeSyncState();

  @override
  Stream<OvertimeSyncState> get stream => const Stream.empty();

  @override
  bool get isClosed => false;

  @override
  Future<void> refreshPendingCount() async {}
}

class _FakeConnectivity extends Fake implements ConnectivityService {
  @override
  Future<bool> get isConnected async => true;

  @override
  Future<List<ConnectivityResult>> get connectionTypes async =>
      const [ConnectivityResult.wifi];
}

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

class _FakeSettingsRepo extends Fake implements SettingsRepository {}

class _FakeMediaConfig extends GetOvertimeMediaConfigUseCase {
  _FakeMediaConfig() : super(_FakeSettingsRepo());

  @override
  Future<Result<OvertimeMediaConfigEntity>> call() async =>
      Success(OvertimeMediaConfigEntity.defaults());
}

class _TestCubit extends OvertimeCubit {
  _TestCubit({
    required OvertimeRepository repo,
    required PreferencesService preferences,
  }) : super(
          getRunningOvertimeUseCase: GetRunningOvertimeUseCase(repo),
          startOvertimeUseCase: StartOvertimeUseCase(repo),
          endOvertimeUseCase: EndOvertimeUseCase(repo),
          cancelOvertimeUseCase: CancelOvertimeUseCase(repo),
          recordCheckpointUseCase: RecordOvertimeCheckpointUseCase(repo),
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
        );

  void seed(OvertimeState next) => emit(next);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PreferencesService prefs;
  late _CancelRepo repo;
  late _TestCubit cubit;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = PreferencesService(await SharedPreferences.getInstance());
    repo = _CancelRepo();
    cubit = _TestCubit(repo: repo, preferences: prefs);
  });

  tearDown(() async {
    await cubit.close();
  });

  test('cancelSession clears running state and stops timer', () async {
    cubit.seed(
      OvertimeState(
        status: OvertimeLoadStatus.ready,
        session: _running(),
        elapsedSeconds: 42,
      ),
    );

    await cubit.cancelSession();

    expect(repo.cancelCalls, 1);
    expect(cubit.state.session, isNull);
    expect(cubit.state.isRunning, isFalse);
    expect(cubit.state.elapsedSeconds, 0);
    expect(cubit.state.busyAction, isNull);
    expect(cubit.state.message, 'overtimeCancelled');
  });

  test('cancelSession is ignored while busy (no duplicate submit)', () async {
    cubit.seed(
      OvertimeState(
        status: OvertimeLoadStatus.actionInProgress,
        session: _running(),
        busyAction: OvertimeBusyAction.cancel,
      ),
    );

    await cubit.cancelSession();
    expect(repo.cancelCalls, 0);
  });

  test('cancelSession rejects non-running session', () async {
    cubit.seed(
      OvertimeState(
        status: OvertimeLoadStatus.ready,
        session: OvertimeSession(
          id: 'ot-done',
          companyId: 'c1',
          userId: 'u1',
          type: OvertimeType.normal,
          status: OvertimeStatus.pendingReview,
          startAt: DateTime.utc(2026, 3, 1, 8),
          startGps: _gps(),
          startDeviceId: 'dev-1',
        ),
      ),
    );

    await cubit.cancelSession();
    expect(repo.cancelCalls, 0);
  });
}
