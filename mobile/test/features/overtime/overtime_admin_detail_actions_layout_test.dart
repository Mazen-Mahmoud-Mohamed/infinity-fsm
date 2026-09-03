import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/cache/session_query_cache.dart';
import 'package:mobile/core/constants/permissions.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/services/auth_session_service.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
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
      email: 'test@gmail.com',
      roles: ['TECHNICIAN'],
    ),
    workflowVersion: OvertimeWorkflowVersion.v2,
    requiresManualReview: true,
    reviewReason: 'Session duration exceeded company policy of 16 hours',
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

    detailCubit = OvertimeDetailCubit(
      getById: _FakeGetById(_pendingSession()),
      approve: _FakeApprove(),
      reject: _FakeReject(),
      sessionId: 'ot-1',
    );
  });

  tearDown(() async {
    await detailCubit.close();
    await authCubit.close();
    sessionService.dispose();
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    required Size size,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
            sessionId: 'ot-1',
            detailCubit: detailCubit,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  Finder reviewActions() => find.byKey(overtimeAdminReviewActionsKey);

  Future<void> scrollListUntil(WidgetTester tester, Finder target) async {
    final list = find.byType(ListView);
    for (var i = 0; i < 24 && target.evaluate().isEmpty; i++) {
      await tester.drag(list, const Offset(0, -350));
      await tester.pump();
    }
  }

  testWidgets(
    'mobile review actions are inside the scrollable content, not a sticky overlay',
    (tester) async {
      await pumpPage(tester, size: const Size(360, 640));

      expect(find.byType(AppBottomSafeListView), findsOneWidget);
      expect(find.text('Overtime Details'), findsOneWidget);

      // Pinned/sticky actions would already be in the tree on the first frame.
      expect(find.text('Approve'), findsNothing);
      expect(reviewActions(), findsNothing);

      await scrollListUntil(tester, find.text('Approve'));

      expect(find.text('Approve'), findsOneWidget);
      expect(find.text('Approve Partial'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);

      expect(
        find.descendant(
          of: find.byType(AppBottomSafeListView),
          matching: reviewActions(),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(ListView),
          matching: reviewActions(),
        ),
        findsOneWidget,
      );

      final listView = tester.widget<ListView>(find.byType(ListView));
      final padding = listView.padding;
      expect(padding, isA<EdgeInsets>());
      expect((padding! as EdgeInsets).bottom, lessThan(72));

      expect(
        find.widgetWithText(ElevatedButton, 'Approve').hitTestable(),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'tablet/desktop review actions stay pinned outside the scroll view',
    (tester) async {
      await pumpPage(tester, size: const Size(900, 800));

      expect(find.text('Approve'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ListView),
          matching: reviewActions(),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(SafeArea),
          matching: reviewActions(),
        ),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(ElevatedButton, 'Approve').hitTestable(),
        findsOneWidget,
      );
    },
  );
}
