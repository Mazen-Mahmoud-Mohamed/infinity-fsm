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
import 'package:mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_status.dart';
import 'package:mobile/features/overtime/domain/repositories/overtime_repository.dart';
import 'package:mobile/features/overtime/domain/usecases/list_admin_overtime_usecase.dart';
import 'package:mobile/features/overtime/presentation/cubit/overtime_admin_cubit.dart';
import 'package:mobile/features/overtime/presentation/pages/overtime_admin_page.dart';

class _FakeAuthRepo extends Fake implements AuthRepository {}

class _FakeOtRepo extends Fake implements OvertimeRepository {
  @override
  Future<Result<OvertimeSessionPage>> listAdminSessions({
    int page = 1,
    int limit = 20,
    OvertimeStatus? status,
    String? search,
  }) async {
    return const Success(
      OvertimeSessionPage(
        items: [],
        page: 1,
        limit: 20,
        total: 0,
        totalPages: 1,
      ),
    );
  }
}

class _TestAdminCubit extends OvertimeAdminCubit {
  _TestAdminCubit(OvertimeAdminState initial)
      : super(
          listAdmin: ListAdminOvertimeUseCase(_FakeOtRepo()),
          sessionQueryCache: SessionQueryCache(),
        ) {
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    emit(initial);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthCubit authCubit;
  late AuthSessionService session;

  setUp(() {
    session = AuthSessionService();
    final fake = _FakeAuthRepo();
    authCubit = AuthCubit(
      restoreSessionUseCase: RestoreSessionUseCase(fake),
      getCurrentUserUseCase: GetCurrentUserUseCase(fake),
      logoutUseCase: LogoutUseCase(fake),
      logoutAllDevicesUseCase: LogoutAllDevicesUseCase(fake),
      authSessionService: session,
      sessionQueryCache: SessionQueryCache(),
    );
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    authCubit.emit(
      const AuthState(
        status: AuthStatus.authenticated,
        user: CurrentUser(
          id: 'a1',
          companyId: 'c1',
          email: 'a@x.com',
          firstName: 'A',
          lastName: 'B',
          fullName: 'A B',
          roles: ['ADMIN'],
          permissions: [Permissions.overtimeViewAll],
        ),
      ),
    );
  });

  tearDown(() async {
    await authCubit.close();
    session.dispose();
  });

  testWidgets('Arabic admin filters include ملغي with existing chips', (
    tester,
  ) async {
    final cubit = _TestAdminCubit(
      const OvertimeAdminState(status: OvertimeAdminStatus.success),
    );
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: const MediaQueryData(size: Size(400, 2200)),
          child: BlocProvider<AuthCubit>.value(
            value: authCubit,
            child: OvertimeAdminPage(debugCubit: cubit),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('الكل'), findsOneWidget);
    expect(find.text('قيد المراجعة'), findsOneWidget);
    expect(find.text('معتمد'), findsOneWidget);
    expect(find.text('مرفوض'), findsOneWidget);
    expect(find.text('ملغي'), findsOneWidget);
  });
}
