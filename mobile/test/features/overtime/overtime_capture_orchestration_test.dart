import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
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

GpsReading _accurateReading() => GpsReading(
      latitude: 24.7136,
      longitude: 46.6753,
      accuracy: 8,
      recordedAt: DateTime.utc(2026, 3, 1, 8, 0, 1),
      provider: 'fused',
    );

GpsSnapshot _gps() => GpsSnapshot(
      latitude: 24.7136,
      longitude: 46.6753,
      accuracy: 8,
      recordedAt: DateTime.utc(2026, 3, 1, 8),
      provider: 'gps',
    );

OvertimeSession _running({
  OvertimeCheckpointStage? next,
}) {
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
    checkpoints: OvertimeCheckpoints(
      startJourney: OvertimeCheckpoint(
        at: start,
        gps: _gps(),
        deviceId: 'dev-1',
      ),
    ),
    nextCheckpoint: next ?? OvertimeCheckpointStage.arrivedAtWorkSite,
  );
}

class _ScriptedGps extends GpsService {
  Completer<void>? ensureHold;
  Completer<GpsReading>? readingHold;
  final ensureStarted = Completer<void>();
  final acquireStarted = Completer<void>();
  int ensureCalls = 0;
  int acquireCalls = 0;
  Object? acquireError;
  GpsReading reading = _accurateReading();

  @override
  Future<void> ensureLocationAccess() async {
    ensureCalls += 1;
    if (!ensureStarted.isCompleted) {
      ensureStarted.complete();
    }
    final hold = ensureHold;
    if (hold != null) {
      await hold.future;
    }
  }

  @override
  Future<GpsReading> acquireCurrentReading() async {
    acquireCalls += 1;
    if (!acquireStarted.isCompleted) {
      acquireStarted.complete();
    }
    if (acquireError != null) {
      throw acquireError!;
    }
    final hold = readingHold;
    if (hold != null) {
      return hold.future;
    }
    return reading;
  }
}

class _ScriptedSelfie extends SelfieCaptureService {
  _ScriptedSelfie() : super(picker: ImagePicker());

  Completer<Uint8List>? photoHold;
  final captureStarted = Completer<void>();
  int captureCalls = 0;
  int watermarkCalls = 0;
  Object? captureError;
  Uint8List photo = Uint8List.fromList(
    img.encodeJpg(img.Image(width: 8, height: 8), quality: 40),
  );
  double? watermarkLat;

  @override
  Future<Uint8List> captureLivePhoto({
    CameraDevice preferredCamera = CameraDevice.front,
    String? watermarkLabel,
    DateTime? timestamp,
    double? latitude,
    double? longitude,
  }) async {
    captureCalls += 1;
    if (!captureStarted.isCompleted) {
      captureStarted.complete();
    }
    if (captureError != null) {
      throw captureError!;
    }
    final hold = photoHold;
    if (hold != null) {
      return hold.future;
    }
    return photo;
  }

  @override
  Future<Uint8List> applyCheckpointWatermark({
    required Uint8List bytes,
    required String label,
    DateTime? timestamp,
    double? latitude,
    double? longitude,
  }) async {
    watermarkCalls += 1;
    watermarkLat = latitude;
    return bytes;
  }
}

class _FakeTimeGuard extends Fake implements DeviceTimeGuardService {
  @override
  Future<DeviceTimeCheckResult> validate({
    DateTime? lastCaptureAt,
    String module = 'overtime',
  }) async {
    return DeviceTimeCheckResult.ok(trustedUtc: DateTime.utc(2026, 3, 1, 8));
  }

  @override
  Future<void> syncSecurityEvents() async {}
}

class _FakeAddress extends AddressResolverService {
  @override
  Future<ResolvedAddress> resolveStructured(GpsSnapshot gps) async {
    return const ResolvedAddress(fullAddress: '1 Test St', city: 'Riyadh');
  }
}

class _FakeGpsSync extends Fake implements GpsAddressSyncService {
  @override
  Future<void> processQueue() async {}
}

class _FakeConnectivity extends Fake implements ConnectivityService {
  @override
  Future<bool> get isConnected async => true;

  @override
  Future<List<ConnectivityResult>> get connectionTypes async =>
      const [ConnectivityResult.wifi];
}

class _FakeTelemetry extends CheckpointTelemetryService {
  _FakeTelemetry() : super(connectivityService: _FakeConnectivity());

  @override
  Future<CheckpointTelemetry> capture() async {
    return const CheckpointTelemetry(batteryLevel: 80, networkStatus: 'wifi');
  }
}

class _FakeSettingsRepo extends Fake implements SettingsRepository {}

class _FakeMediaConfig extends GetOvertimeMediaConfigUseCase {
  _FakeMediaConfig() : super(_FakeSettingsRepo());

  @override
  Future<Result<OvertimeMediaConfigEntity>> call() async {
    return Success(OvertimeMediaConfigEntity.defaults());
  }
}

class _FakeSyncCubit extends Fake implements OvertimeSyncCubit {
  @override
  OvertimeSyncState get state => const OvertimeSyncState();

  @override
  Future<void> refreshPendingCount() async {}

  @override
  Future<void> syncNow({bool force = false, String reason = 'manual'}) async {}
}

class _CountingRepo extends Fake implements OvertimeRepository {
  @override
  Future<Result<OvertimeSession?>> getRunningSession() async =>
      const Success(null);
}

class _CountingStart extends StartOvertimeUseCase {
  _CountingStart() : super(_CountingRepo());

  int calls = 0;

  @override
  Future<Result<OvertimeSession>> call({
    required OvertimeType type,
    required GpsSnapshot gps,
    required List<int> photoBytes,
    List<int>? voiceBytes,
    double? voiceDurationSeconds,
    required String deviceId,
    required String clientRequestId,
    required String? address,
    bool isOvernight = false,
    String? notes,
    int? batteryLevel,
    String? networkStatus,
  }) async {
    calls += 1;
    return Success(_running());
  }
}

class _CountingCheckpoint extends RecordOvertimeCheckpointUseCase {
  _CountingCheckpoint() : super(_CountingRepo());

  int calls = 0;

  @override
  Future<Result<OvertimeSession>> call({
    required String sessionId,
    required OvertimeCheckpointStage stage,
    required GpsSnapshot gps,
    required List<int> photoBytes,
    List<int>? voiceBytes,
    double? voiceDurationSeconds,
    required String deviceId,
    required String? address,
    required String clientRequestId,
    String? notes,
    int? batteryLevel,
    String? networkStatus,
  }) async {
    calls += 1;
    return Success(_running());
  }
}

class _HarnessCubit extends OvertimeCubit {
  _HarnessCubit({
    required super.getRunningOvertimeUseCase,
    required super.startOvertimeUseCase,
    required super.endOvertimeUseCase,
    required super.recordCheckpointUseCase,
    required super.gpsService,
    required super.selfieCaptureService,
    required super.addressResolverService,
    required super.deviceTimeGuard,
    required super.gpsAddressSync,
    required super.preferencesService,
    required super.connectivityService,
    required super.checkpointTelemetryService,
    required super.sessionQueryCache,
    required super.localDataSource,
    required super.overtimeSyncCubit,
    required super.getMediaConfigUseCase,
    required super.uploadPolicyService,
    required super.loggerService,
  });

  void seed(OvertimeState next) => emit(next);
}

Future<
    ({
      _HarnessCubit cubit,
      _ScriptedGps gps,
      _ScriptedSelfie selfie,
      _CountingStart start,
      _CountingCheckpoint checkpoint,
    })> _openHarness() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = PreferencesService(await SharedPreferences.getInstance());
  final repo = _CountingRepo();
  final gps = _ScriptedGps();
  final selfie = _ScriptedSelfie();
  final start = _CountingStart();
  final checkpoint = _CountingCheckpoint();
  final connectivity = _FakeConnectivity();
  final cache = SessionQueryCache();
  final cubit = _HarnessCubit(
    getRunningOvertimeUseCase: GetRunningOvertimeUseCase(repo),
    startOvertimeUseCase: start,
    endOvertimeUseCase: EndOvertimeUseCase(repo),
    recordCheckpointUseCase: checkpoint,
    gpsService: gps,
    selfieCaptureService: selfie,
    addressResolverService: _FakeAddress(),
    deviceTimeGuard: _FakeTimeGuard(),
    gpsAddressSync: _FakeGpsSync(),
    preferencesService: prefs,
    connectivityService: connectivity,
    checkpointTelemetryService: _FakeTelemetry(),
    sessionQueryCache: cache,
    localDataSource: OvertimeLocalDataSource(prefs),
    overtimeSyncCubit: _FakeSyncCubit(),
    getMediaConfigUseCase: _FakeMediaConfig(),
    uploadPolicyService: OvertimeUploadPolicyService(
      connectivity: connectivity,
      sessionQueryCache: cache,
    ),
    loggerService: LoggerService(),
  );
  return (cubit: cubit, gps: gps, selfie: selfie, start: start, checkpoint: checkpoint);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('granted location starts GPS and camera without waiting for the fix',
      () async {
    final h = await _openHarness();
    addTearDown(h.cubit.close);
    h.gps.readingHold = Completer<GpsReading>();
    h.selfie.photoHold = Completer<Uint8List>();

    final started = h.cubit.start(type: OvertimeType.normal);
    await h.gps.ensureStarted.future;
    await h.gps.acquireStarted.future;
    await h.selfie.captureStarted.future;

    expect(h.gps.ensureCalls, 1);
    expect(h.gps.acquireCalls, 1);
    expect(h.selfie.captureCalls, 1);
    expect(h.gps.readingHold!.isCompleted, isFalse);
    expect(h.start.calls, 0);
    expect(h.selfie.watermarkCalls, 0);

    h.selfie.photoHold!.complete(h.selfie.photo);
    await Future<void>.delayed(Duration.zero);
    expect(h.start.calls, 0);

    h.gps.readingHold!.complete(_accurateReading());
    await started;

    expect(
      h.start.calls,
      1,
      reason: 'message=${h.cubit.state.message} status=${h.cubit.state.status}',
    );
    expect(h.selfie.watermarkCalls, 1);
    expect(h.selfie.watermarkLat, _accurateReading().latitude);
  });

  test('location permission is requested before the camera opens', () async {
    final h = await _openHarness();
    addTearDown(h.cubit.close);
    h.gps.ensureHold = Completer<void>();
    h.selfie.photoHold = Completer<Uint8List>();
    h.gps.readingHold = Completer<GpsReading>();

    final started = h.cubit.start(type: OvertimeType.normal);
    await h.gps.ensureStarted.future;
    await Future<void>.delayed(Duration.zero);

    expect(h.selfie.captureCalls, 0);
    expect(h.gps.acquireCalls, 0);

    h.gps.ensureHold!.complete();
    await h.selfie.captureStarted.future;
    await h.gps.acquireStarted.future;
    expect(h.selfie.captureCalls, 1);

    h.selfie.photoHold!.complete(h.selfie.photo);
    h.gps.readingHold!.complete(_accurateReading());
    await started;
    expect(h.start.calls, 1);
  });

  test('slow GPS still waits before submit after the photo is captured',
      () async {
    final h = await _openHarness();
    addTearDown(h.cubit.close);
    h.gps.readingHold = Completer<GpsReading>();

    final started = h.cubit.start(type: OvertimeType.normal);
    await h.selfie.captureStarted.future;
    await Future<void>.delayed(Duration.zero);
    expect(h.start.calls, 0);

    h.gps.readingHold!.complete(_accurateReading());
    await started;
    expect(h.start.calls, 1);
  });

  test('camera cancel does not submit and abandons pending GPS', () async {
    final h = await _openHarness();
    addTearDown(h.cubit.close);
    h.gps.readingHold = Completer<GpsReading>();
    h.selfie.captureError = const LivePhotoRequiredException();

    await h.cubit.start(type: OvertimeType.normal);

    expect(h.start.calls, 0);
    expect(h.cubit.state.message, 'livePhotoRequired');
    expect(h.selfie.watermarkCalls, 0);

    h.gps.readingHold!.complete(_accurateReading());
    await Future<void>.delayed(Duration.zero);
    expect(h.start.calls, 0);
  });

  test('GPS failure after photo rejects the stage as before', () async {
    final h = await _openHarness();
    addTearDown(h.cubit.close);
    h.gps.acquireError = LocationException(
      LocationFailureReason.timeout,
      'locationTimeout',
    );

    await h.cubit.start(type: OvertimeType.normal);

    expect(h.start.calls, 0);
    expect(h.cubit.state.message, 'locationTimeout');
    expect(h.cubit.state.isError, isTrue);
  });

  test('inaccurate GPS still blocks submit after the photo', () async {
    final h = await _openHarness();
    addTearDown(h.cubit.close);
    h.gps.reading = GpsReading(
      latitude: 24.7,
      longitude: 46.6,
      accuracy: 250,
      recordedAt: DateTime.utc(2026, 3, 1, 8),
    );

    await h.cubit.start(type: OvertimeType.normal);

    expect(h.start.calls, 0);
    expect(h.cubit.state.message, 'gpsAccuracyTooLow');
  });

  test('arrived checkpoint uses the same parallel capture path', () async {
    final h = await _openHarness();
    addTearDown(h.cubit.close);
    h.cubit.seed(
      OvertimeState(
        status: OvertimeLoadStatus.ready,
        session: _running(),
      ),
    );
    h.gps.readingHold = Completer<GpsReading>();
    h.selfie.photoHold = Completer<Uint8List>();

    final advanced = h.cubit.completeNextCheckpoint();
    await h.gps.acquireStarted.future;
    await h.selfie.captureStarted.future;
    expect(h.gps.readingHold!.isCompleted, isFalse);
    expect(h.checkpoint.calls, 0);

    h.selfie.photoHold!.complete(h.selfie.photo);
    h.gps.readingHold!.complete(_accurateReading());
    await advanced;

    expect(h.checkpoint.calls, 1);
    expect(h.start.calls, 0);
  });
}
