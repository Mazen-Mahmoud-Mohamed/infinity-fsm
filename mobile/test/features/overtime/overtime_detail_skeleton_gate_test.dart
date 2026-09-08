import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/cache/session_query_cache.dart';
import 'package:mobile/core/constants/permissions.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/services/auth_session_service.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/core/widgets/app_loader.dart';
import 'package:mobile/core/geo/gps_snapshot.dart';
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
import 'package:mobile/features/overtime/presentation/widgets/overtime_detail_skeleton.dart';

GpsSnapshot _gps(DateTime at) => GpsSnapshot(
      latitude: 24.7,
      longitude: 46.6,
      accuracy: 5,
      recordedAt: at,
      provider: 'gps',
    );

OvertimeSession _pendingSession() {
  final start = DateTime.utc(2026, 8, 12, 8);
  return OvertimeSession(
    id: 'ot-1',
    companyId: 'c1',
    userId: 'u1',
    type: OvertimeType.normal,
    status: OvertimeStatus.pendingReview,
    startAt: start,
    endAt: start.add(const Duration(hours: 8)),
    startGps: _gps(start),
    startDeviceId: 'd1',
    createdAt: start,
    totalDurationMinutes: 480,
    workingDurationMinutes: 360,
    eligibleOvertimeMinutes: 120,
    technician: const OvertimeTechnicianSummary(
      id: 'u1',
      fullName: 'Field Technician',
      email: 'test@gmail.com',
      roles: ['TECHNICIAN'],
    ),
    workflowVersion: OvertimeWorkflowVersion.v2,
    requiresManualReview: false,
  );
}

class _NoopOvertimeRepo extends Fake implements OvertimeRepository {}

class _DeferredGetById extends GetOvertimeByIdUseCase {
  _DeferredGetById() : super(_NoopOvertimeRepo());

  final Completer<Result<OvertimeSession>> gate = Completer();
  int calls = 0;

  @override
  Future<Result<OvertimeSession>> call(String id) {
    calls += 1;
    if (calls == 1 && firstResult != null) {
      return Future.value(firstResult);
    }
    return gate.future;
  }

  Result<OvertimeSession>? firstResult;
}

class _DeferredApprove extends ApproveOvertimeUseCase {
  _DeferredApprove() : super(_NoopOvertimeRepo());

  final Completer<Result<OvertimeSession>> gate = Completer();

  @override
  Future<Result<OvertimeSession>> call(
    String id, {
    String? reviewNotes,
    double? approvedHours,
  }) {
    return gate.future;
  }
}

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
  });

  tearDown(() async {
    await authCubit.close();
    sessionService.dispose();
  });

  Future<void> pumpPage(
    WidgetTester tester,
    OvertimeDetailCubit cubit, {
    Size size = const Size(400, 1200),
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
        home: BlocProvider.value(
          value: authCubit,
          child: OvertimeAdminDetailPage(
            sessionId: cubit.sessionId,
            detailCubit: cubit,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('initial loading with no data shows skeleton not spinner',
      (tester) async {
    final getById = _DeferredGetById();
    final cubit = OvertimeDetailCubit(
      getById: getById,
      approve: _FakeApprove(),
      reject: _FakeReject(),
      sessionId: 'ot-1',
    );
    addTearDown(cubit.close);
    unawaited(cubit.load());

    await pumpPage(tester, cubit);

    expect(find.byType(OvertimeDetailSkeleton), findsOneWidget);
    expect(find.byType(AppLoader), findsNothing);
    expect(find.text('Loading details...'), findsNothing);
    expect(find.text('Field Technician'), findsNothing);

    getById.gate.complete(Success(_pendingSession()));
    await tester.pump();
    expect(find.byType(OvertimeDetailSkeleton), findsNothing);
    expect(find.text('Field Technician'), findsOneWidget);
  });

  testWidgets('loading with existing data keeps real content', (tester) async {
    final getById = _DeferredGetById()..firstResult = Success(_pendingSession());
    final cubit = OvertimeDetailCubit(
      getById: getById,
      approve: _FakeApprove(),
      reject: _FakeReject(),
      sessionId: 'ot-1',
    );
    addTearDown(cubit.close);
    await cubit.load();

    await pumpPage(tester, cubit);
    expect(find.text('Field Technician'), findsOneWidget);
    expect(find.byType(OvertimeDetailSkeleton), findsNothing);

    unawaited(cubit.load());
    await tester.pump();

    expect(cubit.state.status, OvertimeDetailStatus.loading);
    expect(cubit.state.session, isNotNull);
    expect(find.text('Field Technician'), findsOneWidget);
    expect(find.byType(OvertimeDetailSkeleton), findsNothing);
    expect(find.byType(AppLoader), findsNothing);

    getById.gate.complete(Success(_pendingSession()));
    await tester.pump();
  });

  testWidgets('mutation loading keeps content and button spinner',
      (tester) async {
    final approve = _DeferredApprove();
    final cubit = OvertimeDetailCubit(
      getById: _FakeGetById(_pendingSession()),
      approve: approve,
      reject: _FakeReject(),
      sessionId: 'ot-1',
    );
    addTearDown(cubit.close);
    await cubit.load();

    await pumpPage(tester, cubit, size: const Size(1100, 900));
    expect(find.byKey(overtimeAdminReviewActionsKey), findsOneWidget);

    unawaited(cubit.approve());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    expect(cubit.state.isApproving, isTrue);
    expect(find.text('Field Technician'), findsOneWidget);
    expect(find.byType(OvertimeDetailSkeleton), findsNothing);
    expect(find.byType(AppLoader), findsNothing);
    expect(find.byKey(overtimeAdminReviewActionsKey), findsOneWidget);
    expect(find.text('Approve'), findsNothing);

    approve.gate.complete(Success(_pendingSession()));
    await tester.pump();
  });
}
