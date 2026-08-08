import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/attendance/domain/entities/gps_snapshot.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_checkpoint.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_status.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_type.dart';
import 'package:mobile/features/overtime/domain/repositories/overtime_repository.dart';
import 'package:mobile/features/overtime/domain/usecases/approve_overtime_usecase.dart';
import 'package:mobile/features/overtime/domain/usecases/get_overtime_by_id_usecase.dart';
import 'package:mobile/features/overtime/domain/usecases/reject_overtime_usecase.dart';
import 'package:mobile/features/overtime/presentation/cubit/overtime_detail_cubit.dart';

GpsSnapshot _gps(DateTime at) => GpsSnapshot(
      latitude: 24.7,
      longitude: 46.6,
      accuracy: 5,
      recordedAt: at,
      provider: 'gps',
    );

OvertimeSession _session({
  OvertimeStatus status = OvertimeStatus.pendingReview,
  int eligibleMinutes = 870,
}) {
  final start = DateTime.utc(2026, 8, 8, 10);
  return OvertimeSession(
    id: 'ot-1',
    companyId: 'c1',
    userId: 'u1',
    type: OvertimeType.normal,
    status: status,
    startAt: start,
    startGps: _gps(start),
    startDeviceId: 'd1',
    createdAt: start,
    eligibleOvertimeMinutes: eligibleMinutes,
    workflowVersion: OvertimeWorkflowVersion.v2,
  );
}

class _NoopRepo extends Fake implements OvertimeRepository {}

class _FakeGetById extends GetOvertimeByIdUseCase {
  _FakeGetById(this.session) : super(_NoopRepo());

  OvertimeSession session;

  @override
  Future<Result<OvertimeSession>> call(String id) async => Success(session);
}

class _FakeApprove extends ApproveOvertimeUseCase {
  _FakeApprove() : super(_NoopRepo());

  final calls = <Map<String, Object?>>[];
  Completer<Result<OvertimeSession>>? gate;
  OvertimeSession? resultSession;

  @override
  Future<Result<OvertimeSession>> call(
    String id, {
    String? reviewNotes,
    double? approvedHours,
  }) async {
    calls.add({
      'id': id,
      'reviewNotes': reviewNotes,
      'approvedHours': approvedHours,
    });
    if (gate != null) {
      return gate!.future;
    }
    return Success(resultSession ?? _session(status: OvertimeStatus.approved));
  }
}

class _FakeReject extends RejectOvertimeUseCase {
  _FakeReject() : super(_NoopRepo());

  final calls = <Map<String, Object?>>[];
  Completer<Result<OvertimeSession>>? gate;

  @override
  Future<Result<OvertimeSession>> call(
    String id, {
    String? rejectionReason,
    String? reviewNotes,
  }) async {
    calls.add({
      'id': id,
      'rejectionReason': rejectionReason,
      'reviewNotes': reviewNotes,
    });
    if (gate != null) {
      return gate!.future;
    }
    return Success(_session(status: OvertimeStatus.rejected));
  }
}

void main() {
  late _FakeGetById getById;
  late _FakeApprove approve;
  late _FakeReject reject;
  late OvertimeDetailCubit cubit;

  setUp(() {
    getById = _FakeGetById(_session());
    approve = _FakeApprove();
    reject = _FakeReject();
    cubit = OvertimeDetailCubit(
      getById: getById,
      approve: approve,
      reject: reject,
      sessionId: 'ot-1',
    );
  });

  tearDown(() async {
    await cubit.close();
  });

  Future<void> loadReady() async {
    await cubit.load();
    expect(cubit.state.status, OvertimeDetailStatus.success);
  }

  test('full approve sets isApproving, not isApprovingPartial', () async {
    await loadReady();
    approve.gate = Completer<Result<OvertimeSession>>();

    final future = cubit.approve(reviewNotes: 'ok');
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.isApproving, isTrue);
    expect(cubit.state.isApprovingPartial, isFalse);
    expect(cubit.state.isRejecting, isFalse);
    expect(cubit.state.isBusy, isTrue);

    approve.gate!.complete(
      Success(_session(status: OvertimeStatus.approved)),
    );
    await future;
    expect(cubit.state.isBusy, isFalse);
    expect(approve.calls, hasLength(1));
    expect(approve.calls.single['approvedHours'], isNull);
  });

  test('partial approve sets isApprovingPartial, not isApproving', () async {
    await loadReady();
    approve.gate = Completer<Result<OvertimeSession>>();

    final future = cubit.approvePartial(approvedHours: 14.5);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.isApprovingPartial, isTrue);
    expect(cubit.state.isApproving, isFalse);
    expect(cubit.state.isRejecting, isFalse);

    approve.gate!.complete(
      Success(_session(status: OvertimeStatus.approved)),
    );
    await future;
    expect(cubit.state.isBusy, isFalse);
    expect(approve.calls.single['approvedHours'], 14.5);
  });

  test('reject sets isRejecting only', () async {
    await loadReady();
    reject.gate = Completer<Result<OvertimeSession>>();

    final future = cubit.reject(rejectionReason: 'no');
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.isRejecting, isTrue);
    expect(cubit.state.isApproving, isFalse);
    expect(cubit.state.isApprovingPartial, isFalse);

    reject.gate!.complete(
      Success(_session(status: OvertimeStatus.rejected)),
    );
    await future;
    expect(cubit.state.isBusy, isFalse);
  });

  test('prevents duplicate submissions while busy', () async {
    await loadReady();
    approve.gate = Completer<Result<OvertimeSession>>();

    final first = cubit.approve();
    await Future<void>.delayed(Duration.zero);
    await cubit.approvePartial(approvedHours: 1);
    await cubit.reject(rejectionReason: 'x');

    expect(approve.calls, hasLength(1));
    expect(reject.calls, isEmpty);

    approve.gate!.complete(
      Success(_session(status: OvertimeStatus.approved)),
    );
    await first;
  });
}
