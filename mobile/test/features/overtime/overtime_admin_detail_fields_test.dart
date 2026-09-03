import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/cache/session_query_cache.dart';
import 'package:mobile/core/constants/permissions.dart';
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
import 'package:mobile/features/attendance/domain/entities/gps_snapshot.dart';
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

GpsSnapshot _gps(DateTime at) => GpsSnapshot(
      latitude: 24.7,
      longitude: 46.6,
      accuracy: 5,
      recordedAt: at,
      provider: 'gps',
    );

OvertimeSession _travelSession({
  required bool overnight,
  required OvertimeStatus status,
}) {
  final start = DateTime.utc(2026, 8, 12, 8);

  return OvertimeSession(
    id: 'ot-travel-${overnight ? 'on' : 'off'}',
    companyId: 'c1',
    userId: 'u1',
    type: OvertimeType.travel,
    isOvernight: overnight,
    status: status,
    startAt: start,
    endAt: start.add(const Duration(hours: 8)),
    startGps: _gps(start),
    startDeviceId: 'd1',
    technician: const OvertimeTechnicianSummary(
      id: 'u1',
      fullName: 'Field Technician',
      email: 'test@gmail.com',
      roles: ['TECHNICIAN'],
    ),
    workflowVersion: OvertimeWorkflowVersion.v2,
    requiresManualReview: false,
    totalDurationMinutes: 480, // 8 hours
    workingDurationMinutes: 360, // 6 hours
    eligibleOvertimeMinutes: 120, // 2 hours
    approvedHours: 2.0,
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
  late OvertimeDetailCubit detailCubit;

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
    await detailCubit.close();
    await authCubit.close();
    sessionService.dispose();
  });

  Future<void> pumpPage({
    required WidgetTester tester,
    required OvertimeSession session,
    required Locale locale,
    required Size size,
  }) async {
    detailCubit = OvertimeDetailCubit(
      getById: _FakeGetById(session),
      approve: _FakeApprove(),
      reject: _FakeReject(),
      sessionId: session.id,
    );

    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await detailCubit.load();

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

  testWidgets(
    'Arabic: shows overnight word + renamed labels, and hides removed worked-hours label',
    (tester) async {
      await pumpPage(
        tester: tester,
        size: const Size(900, 900),
        locale: const Locale('ar'),
        session: _travelSession(overnight: true, status: OvertimeStatus.approved),
      );

      expect(find.text('بيات'), findsOneWidget);

      // Should not render yes/no wording.
      expect(find.text('البيات: نعم'), findsNothing);
      expect(find.text('البيات: لا'), findsNothing);
      expect(find.text('البيات'), findsNothing);

      // Renamed labels in the session details card.
      expect(find.text('ساعات العمل الرسمية'), findsOneWidget);
      expect(find.text('ساعات الإضافي'), findsOneWidget);
      expect(find.text('إجمالي ساعات العمل'), findsOneWidget);

      // Removed "ساعات العمل" (worked hours) field.
      expect(find.text('ساعات العمل'), findsNothing);

      // Old labels should no longer appear in this section.
      expect(find.text('مدة العمل'), findsNothing);
      expect(find.text('العمل الإضافي المؤهل'), findsNothing);
      expect(find.text('المدة الإجمالية'), findsNothing);
    },
  );

  testWidgets(
    'Arabic: hides overnight row entirely when overnight=false',
    (tester) async {
      await pumpPage(
        tester: tester,
        size: const Size(900, 900),
        locale: const Locale('ar'),
        session: _travelSession(overnight: false, status: OvertimeStatus.approved),
      );

      expect(find.text('بيات'), findsNothing);
      expect(find.text('البيات'), findsNothing);
    },
  );

  testWidgets(
    'English: shows "Overnight" only for overnight=true and uses renamed labels',
    (tester) async {
      await pumpPage(
        tester: tester,
        size: const Size(900, 900),
        locale: const Locale('en'),
        session: _travelSession(overnight: true, status: OvertimeStatus.approved),
      );

      expect(find.text('Overnight'), findsOneWidget);
      expect(find.text('Official Working Hours'), findsOneWidget);
      expect(find.text('Overtime Hours'), findsOneWidget);
      expect(find.text('Total Working Hours'), findsOneWidget);
    },
  );
}

