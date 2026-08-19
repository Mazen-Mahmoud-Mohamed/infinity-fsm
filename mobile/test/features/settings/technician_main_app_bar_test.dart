import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/cache/session_query_cache.dart';
import 'package:mobile/core/constants/permissions.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/core/services/auth_session_service.dart';
import 'package:mobile/core/widgets/technician_main_app_bar.dart';
import 'package:mobile/features/auth/domain/entities/current_user.dart';
import 'package:mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:mobile/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:mobile/features/auth/domain/usecases/logout_usecase.dart';
import 'package:mobile/features/auth/domain/usecases/restore_session_usecase.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/features/settings/presentation/pages/settings_hub_page.dart';
import 'package:mobile/features/settings/presentation/widgets/settings_app_bar_action.dart';

class _FakeAuthRepo extends Fake implements AuthRepository {}

Future<void> _pumpLocalizedApp({
  required WidgetTester tester,
  required Widget child,
  required Locale locale,
  GoRouter? router,
}) async {
  if (router != null) {
    await tester.pumpWidget(
      MaterialApp.router(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  } else {
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
        home: child,
      ),
    );
  }

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

Rect _settingsButtonRect(WidgetTester tester) {
  return tester.getRect(find.byIcon(Icons.settings_outlined));
}

Rect _appBarRect(WidgetTester tester) {
  return tester.getRect(find.byType(AppBar));
}

Scaffold _sectionScaffold({required String titleKey}) {
  return Scaffold(
    appBar: TechnicianMainAppBar(
      title: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          return Text(switch (titleKey) {
            'overtime' => l10n.overtime,
            'workOrders' => l10n.workOrders,
            'attendance' => l10n.attendance,
            'profile' => l10n.profile,
            _ => titleKey,
          });
        },
      ),
    ),
    body: const SizedBox.shrink(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TechnicianMainAppBar', () {
    testWidgets('LTR places Settings on the physical left', (tester) async {
      await _pumpLocalizedApp(
        tester: tester,
        locale: const Locale('en'),
        child: _sectionScaffold(titleKey: 'overtime'),
      );

      final appBar = _appBarRect(tester);
      final settings = _settingsButtonRect(tester);

      expect(settings.center.dx, lessThan(appBar.center.dx));
    });

    testWidgets('RTL places Settings on the physical right', (tester) async {
      await _pumpLocalizedApp(
        tester: tester,
        locale: const Locale('ar'),
        child: _sectionScaffold(titleKey: 'overtime'),
      );

      final appBar = _appBarRect(tester);
      final settings = _settingsButtonRect(tester);

      expect(settings.center.dx, greaterThan(appBar.center.dx));
    });

    testWidgets('tap navigates to the existing settings route', (tester) async {
      var visitedSettings = false;

      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const Scaffold(
              appBar: TechnicianMainAppBar(
                title: Text('Home'),
              ),
            ),
          ),
          GoRoute(
            path: RoutePaths.settings,
            builder: (context, state) {
              visitedSettings = true;
              return const Scaffold(body: Text('Settings Hub'));
            },
          ),
        ],
      );

      await _pumpLocalizedApp(
        tester: tester,
        locale: const Locale('en'),
        child: const SizedBox.shrink(),
        router: router,
      );

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      expect(visitedSettings, isTrue);
      expect(find.text('Settings Hub'), findsOneWidget);
    });

    testWidgets('remains visible when only one section is enabled', (tester) async {
      await _pumpLocalizedApp(
        tester: tester,
        locale: const Locale('en'),
        child: _sectionScaffold(titleKey: 'overtime'),
      );

      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    });
  });

  group('Technician main section pages', () {
    Future<void> expectSettingsOnSection({
      required WidgetTester tester,
      required String titleKey,
    }) async {
      await _pumpLocalizedApp(
        tester: tester,
        locale: const Locale('en'),
        child: _sectionScaffold(titleKey: titleKey),
      );

      expect(find.byType(TechnicianMainAppBar), findsOneWidget);
      expect(find.byType(SettingsAppBarAction), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    }

    testWidgets('overtime page app bar includes Settings', (tester) async {
      await expectSettingsOnSection(tester: tester, titleKey: 'overtime');
    });

    testWidgets('work orders page app bar includes Settings', (tester) async {
      await expectSettingsOnSection(tester: tester, titleKey: 'workOrders');
    });

    testWidgets('attendance page app bar includes Settings', (tester) async {
      await expectSettingsOnSection(tester: tester, titleKey: 'attendance');
    });

    testWidgets('profile page app bar includes Settings', (tester) async {
      await expectSettingsOnSection(tester: tester, titleKey: 'profile');
    });
  });

  group('Settings hub authorization', () {
    late AuthSessionService sessionService;
    late AuthCubit authCubit;

    const technician = CurrentUser(
      id: 'tech-1',
      companyId: 'c1',
      email: 'tech@example.com',
      firstName: 'Field',
      lastName: 'Tech',
      fullName: 'Field Tech',
      roles: ['TECHNICIAN'],
      permissions: [],
    );

    const admin = CurrentUser(
      id: 'admin-1',
      companyId: 'c1',
      email: 'admin@example.com',
      firstName: 'Admin',
      lastName: 'User',
      fullName: 'Admin User',
      roles: ['ADMIN'],
      permissions: [Permissions.settingsManage],
    );

    setUp(() {
      sessionService = AuthSessionService();
      authCubit = AuthCubit(
        restoreSessionUseCase: RestoreSessionUseCase(_FakeAuthRepo()),
        getCurrentUserUseCase: GetCurrentUserUseCase(_FakeAuthRepo()),
        logoutUseCase: LogoutUseCase(_FakeAuthRepo()),
        authSessionService: sessionService,
        sessionQueryCache: SessionQueryCache(),
      );
    });

    tearDown(() async {
      await authCubit.close();
      sessionService.dispose();
    });

    Future<void> pumpHub({
      required WidgetTester tester,
      required CurrentUser user,
    }) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      authCubit.setAuthenticated(user);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: BlocProvider.value(
            value: authCubit,
            child: const SettingsHubPage(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('technician hub hides admin-only Technician Interface tile',
        (tester) async {
      await pumpHub(tester: tester, user: technician);

      final l10n = lookupAppLocalizations(const Locale('en'));
      expect(find.text(l10n.settingsTechnicianInterfaceTitle), findsNothing);
    });

    testWidgets('admin hub shows Technician Interface tile', (tester) async {
      await pumpHub(tester: tester, user: admin);

      final l10n = lookupAppLocalizations(const Locale('en'));
      await tester.enterText(find.byType(TextField), 'technician');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text(l10n.settingsTechnicianInterfaceTitle), findsOneWidget);
    });
  });
}
