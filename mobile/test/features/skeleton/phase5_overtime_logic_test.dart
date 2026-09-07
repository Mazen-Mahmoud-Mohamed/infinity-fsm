import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/cache/session_query_cache.dart';
import 'package:mobile/core/geo/gps_snapshot.dart';
import 'package:mobile/core/storage/preferences_service.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/overtime/data/datasources/overtime_local_datasource.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_status.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_type.dart';
import 'package:mobile/features/overtime/domain/repositories/overtime_repository.dart';
import 'package:mobile/features/overtime/domain/usecases/list_admin_overtime_usecase.dart';
import 'package:mobile/features/overtime/domain/usecases/list_my_overtime_usecase.dart';
import 'package:mobile/features/overtime/presentation/cubit/overtime_admin_cubit.dart';
import 'package:mobile/features/overtime/presentation/cubit/overtime_history_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _PendingOtRepo extends Fake implements OvertimeRepository {
  final Completer<Result<OvertimeSessionPage>> pending = Completer();

  @override
  Future<Result<OvertimeSessionPage>> listMySessions({
    int page = 1,
    int limit = 20,
    OvertimeStatus? status,
  }) {
    return pending.future;
  }

  @override
  Future<Result<OvertimeSessionPage>> listAdminSessions({
    int page = 1,
    int limit = 20,
    OvertimeStatus? status,
    String? search,
  }) {
    return pending.future;
  }
}

OvertimeSession _session() {
  return OvertimeSession(
    id: 'ot-keep',
    companyId: 'c1',
    userId: 'u1',
    type: OvertimeType.normal,
    status: OvertimeStatus.approved,
    startAt: DateTime.utc(2026, 1, 2, 8),
    startGps: GpsSnapshot(
      latitude: 24.7,
      longitude: 46.7,
      accuracy: 5,
      recordedAt: DateTime.utc(2026, 1, 2, 8),
    ),
    startDeviceId: 'dev-1',
  );
}

void main() {
  test('history loadFirstPage with existing items uses isRefreshing', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = _PendingOtRepo();
    final cubit = OvertimeHistoryCubit(
      listMine: ListMyOvertimeUseCase(repo),
      sessionQueryCache: SessionQueryCache(),
      localDataSource: OvertimeLocalDataSource(
        PreferencesService(await SharedPreferences.getInstance()),
      ),
    );
    addTearDown(cubit.close);

    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    cubit.emit(
      OvertimeHistoryState(
        status: OvertimeHistoryStatus.success,
        items: [_session()],
      ),
    );

    final future = cubit.loadFirstPage();
    expect(cubit.state.isRefreshing, isTrue);
    expect(cubit.state.status, OvertimeHistoryStatus.success);
    expect(cubit.state.items.single.id, 'ot-keep');

    repo.pending.complete(
      Success(
        OvertimeSessionPage(
          items: [_session()],
          page: 1,
          limit: 20,
          total: 1,
          totalPages: 1,
        ),
      ),
    );
    await future;
    expect(cubit.state.isRefreshing, isFalse);
    expect(cubit.state.items.single.id, 'ot-keep');
  });

  test('admin loadFirstPage with existing items uses isRefreshing', () async {
    final repo = _PendingOtRepo();
    final cubit = OvertimeAdminCubit(
      listAdmin: ListAdminOvertimeUseCase(repo),
      sessionQueryCache: SessionQueryCache(),
    );
    addTearDown(cubit.close);

    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    cubit.emit(
      OvertimeAdminState(
        status: OvertimeAdminStatus.success,
        items: [_session()],
      ),
    );

    final future = cubit.loadFirstPage();
    expect(cubit.state.isRefreshing, isTrue);
    expect(cubit.state.status, OvertimeAdminStatus.success);
    expect(cubit.state.items.single.id, 'ot-keep');

    repo.pending.complete(
      Success(
        OvertimeSessionPage(
          items: [_session()],
          page: 1,
          limit: 20,
          total: 1,
          totalPages: 1,
        ),
      ),
    );
    await future;
    expect(cubit.state.isRefreshing, isFalse);
    expect(cubit.state.items.single.id, 'ot-keep');
  });
}
