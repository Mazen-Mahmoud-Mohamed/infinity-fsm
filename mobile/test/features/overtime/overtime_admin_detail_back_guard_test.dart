import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/cache/session_query_cache.dart';
import 'package:mobile/core/constants/permissions.dart';
import 'package:mobile/core/geo/gps_snapshot.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/services/auth_session_service.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/auth/domain/entities/current_user.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobile/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:mobile/features/auth/domain/usecases/logout_all_devices_usecase.dart';
import 'package:mobile/features/auth/domain/usecases/logout_usecase.dart';
import 'package:mobile/features/auth/domain/usecases/restore_session_usecase.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_status.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_type.dart';
import 'package:mobile/features/overtime/domain/repositories/overtime_repository.dart';
import 'package:mobile/features/overtime/domain/usecases/approve_overtime_usecase.dart';
import 'package:mobile/features/overtime/domain/usecases/get_overtime_by_id_usecase.dart';
import 'package:mobile/features/overtime/domain/usecases/reject_overtime_usecase.dart';
import 'package:mobile/features/overtime/presentation/cubit/overtime_detail_cubit.dart';
import 'package:mobile/features/overtime/presentation/pages/overtime_admin_detail_page.dart';

GpsSnapshot _gps() => GpsSnapshot(
      latitude: 24.7,
      longitude: 46.6,
      accuracy: 5,
      recordedAt: DateTime.utc(2026, 8, 12, 8),
      provider: 'gps',
    );

OvertimeSession _pending() {
  final start = DateTime.utc(2026, 8, 12, 8);
  return OvertimeSession(
    id: 'ot-1',
    companyId: 'c1',
    userId: 'u1',
    type: OvertimeType.normal,
    status: OvertimeStatus.pendingReview,
    startAt: start,
    endAt: start.add(const Duration(hours: 8)),
    startGps: _gps(),
    startDeviceId: 'd1',
    eligibleOvertimeMinutes: 120,
  );
}

class _NoopRepo extends Fake implements OvertimeRepository {}

class _FakeGetById extends GetOvertimeByIdUseCase {
  _FakeGetById(this.session) : super(_NoopRepo());
  final OvertimeSession session;

  @override
  Future<Result<OvertimeSession>> call(String id) async => Success(session);
}

class _HeldApprove extends ApproveOvertimeUseCase {
  _HeldApprove() : super(_NoopRepo());

  Result<OvertimeSession> result =
      Success(_pending());
  var completeAfter = Duration.zero;

  @override
  Future<Result<OvertimeSession>> call(
    String id, {
    String? reviewNotes,
    double? approvedHours,
  }) async {
    if (completeAfter > Duration.zero) {
      await Future<void>.delayed(completeAfter);
    }
    return result;
  }
}

class _HeldReject extends RejectOvertimeUseCase {
  _HeldReject() : super(_NoopRepo());

  Result<OvertimeSession> result =
      Success(_pending());
  var completeAfter = Duration.zero;

  @override
  Future<Result<OvertimeSession>> call(
    String id, {
    String? rejectionReason,
    String? reviewNotes,
  }) async {
    if (completeAfter > Duration.zero) {
      await Future<void>.delayed(completeAfter);
    }
    return result;
  }
}

class _FakeAuthRepo extends Fake implements AuthRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthSessionService sessionService;
  late AuthCubit authCubit;
  late OvertimeDetailCubit detailCubit;
  late _HeldApprove approve;
  late _HeldReject reject;

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
    approve = _HeldApprove();
    reject = _HeldReject();
    detailCubit = OvertimeDetailCubit(
      getById: _FakeGetById(_pending()),
      approve: approve,
      reject: reject,
      sessionId: 'ot-1',
    );
  });

  tearDown(() async {
    await detailCubit.close();
    await authCubit.close();
    sessionService.dispose();
  });

  Future<void> pumpDetail(WidgetTester tester, {bool load = true}) async {
    if (load) {
      await detailCubit.load();
    }
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
          child: Builder(
            builder: (context) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).push(
                  MaterialPageRoute<OvertimeSession>(
                    builder: (_) => BlocProvider.value(
                      value: authCubit,
                      child: OvertimeAdminDetailPage(
                        sessionId: 'ot-1',
                        detailCubit: detailCubit,
                      ),
                    ),
                  ),
                );
              });
              return const Scaffold(body: Text('summary'));
            },
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  Future<void> attemptBack(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await tester.pump();
  }

  testWidgets('back is ignored while a review mutation is in progress',
      (tester) async {
    await pumpDetail(tester);
    approve
      ..completeAfter = const Duration(seconds: 5)
      ..result = Success(
        OvertimeSession(
          id: 'ot-1',
          companyId: 'c1',
          userId: 'u1',
          type: OvertimeType.normal,
          status: OvertimeStatus.approved,
          startAt: DateTime.utc(2026, 8, 12, 8),
          endAt: DateTime.utc(2026, 8, 12, 16),
          startGps: _gps(),
          startDeviceId: 'd1',
          eligibleOvertimeMinutes: 120,
        ),
      );
    unawaited(detailCubit.approve());
    await tester.pump();

    expect(detailCubit.state.isBusy, isTrue);
    expect(
      tester
          .widget<IconButton>(
            find.byKey(const Key('overtime-admin-detail-back')),
          )
          .onPressed,
      isNull,
    );
    await attemptBack(tester);
    expect(find.byType(OvertimeAdminDetailPage), findsOneWidget);
    expect(detailCubit.state.isBusy, isTrue);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('back is allowed after a successful review mutation',
      (tester) async {
    await pumpDetail(tester);
    approve
      ..completeAfter = const Duration(milliseconds: 20)
      ..result = Success(
        OvertimeSession(
          id: 'ot-1',
          companyId: 'c1',
          userId: 'u1',
          type: OvertimeType.normal,
          status: OvertimeStatus.approved,
          startAt: DateTime.utc(2026, 8, 12, 8),
          endAt: DateTime.utc(2026, 8, 12, 16),
          startGps: _gps(),
          startDeviceId: 'd1',
          eligibleOvertimeMinutes: 120,
        ),
      );
    unawaited(detailCubit.approve());
    await tester.pump();
    expect(detailCubit.state.isBusy, isTrue);
    await tester.pump(const Duration(milliseconds: 30));

    expect(detailCubit.state.isBusy, isFalse);
    expect(
      tester
          .widget<IconButton>(
            find.byKey(const Key('overtime-admin-detail-back')),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('back is allowed after a failed review mutation', (tester) async {
    await detailCubit.load();
    reject.result = const Failure<OvertimeSession>('denied', code: 'HTTP_400');
    await detailCubit.reject(rejectionReason: 'denied');
    expect(detailCubit.state.isBusy, isFalse);
    expect(detailCubit.state.isError, isTrue);

    await pumpDetail(tester, load: false);
    expect(
      tester
          .widget<IconButton>(
            find.byKey(const Key('overtime-admin-detail-back')),
          )
          .onPressed,
      isNotNull,
    );
  });
}
