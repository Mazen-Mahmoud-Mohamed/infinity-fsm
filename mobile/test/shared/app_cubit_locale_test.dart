import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/services/connectivity_service.dart';
import 'package:mobile/core/services/connectivity_status.dart';
import 'package:mobile/core/services/sync_configuration_service.dart';
import 'package:mobile/core/storage/preferences_service.dart';
import 'package:mobile/features/settings/presentation/pages/account_settings_pages.dart';
import 'package:mobile/shared/presentation/cubit/app_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeConnectivity implements ConnectivityService {
  @override
  ConnectivitySnapshot get currentSnapshot => const ConnectivitySnapshot(
        level: ConnectivityLevel.online,
        networkAvailable: true,
        networkType: 'wifi',
        internetReachable: true,
        apiReachable: true,
      );

  @override
  Future<bool> get isConnected async => true;

  @override
  Future<List<ConnectivityResult>> get connectionTypes async =>
      const [ConnectivityResult.wifi];

  @override
  Stream<bool> get onConnectivityChanged => const Stream.empty();

  @override
  Stream<ConnectivitySnapshot> get onStatusChanged => const Stream.empty();

  @override
  Future<ConnectivitySnapshot> refreshStatus({
    String reason = 'manual',
    bool forceApiProbe = false,
  }) async =>
      currentSnapshot;

  @override
  Future<void> dispose() async {}

  @override
  void invalidateCachedProbe({String reason = 'invalidate'}) {}
}

void _setTestLocales(List<Locale> locales) {
  TestWidgetsFlutterBinding.instance.platformDispatcher.localesTestValue =
      locales;
}

Future<AppCubit> _createCubit(Map<String, Object> prefs) async {
  SharedPreferences.setMockInitialValues(prefs);
  final preferences = PreferencesService(await SharedPreferences.getInstance());
  final syncConfiguration = SyncConfigurationService(preferences);
  await syncConfiguration.load();
  return AppCubit(_FakeConnectivity(), preferences, syncConfiguration);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.clearLocalesTestValue();
  });

  group('AppCubit locale resolution', () {
    test('no saved preference + Arabic device -> ar/system', () async {
      _setTestLocales(const [Locale('ar')]);

      final cubit = await _createCubit({});
      await cubit.initialize();

      expect(cubit.state.localeCode, 'ar');
      expect(cubit.state.localePreference, 'system');
      await cubit.close();
    });

    test('no saved preference + English device -> en/system', () async {
      _setTestLocales(const [Locale('en')]);

      final cubit = await _createCubit({});
      await cubit.initialize();

      expect(cubit.state.localeCode, 'en');
      expect(cubit.state.localePreference, 'system');
      await cubit.close();
    });

    test('no saved preference + unsupported device -> en/system', () async {
      _setTestLocales(const [Locale('fr')]);

      final cubit = await _createCubit({});
      await cubit.initialize();

      expect(cubit.state.localeCode, 'en');
      expect(cubit.state.localePreference, 'system');
      await cubit.close();
    });

    test('saved ar + English device -> ar/ar', () async {
      _setTestLocales(const [Locale('en')]);

      final cubit = await _createCubit({'app_locale_code': 'ar'});
      await cubit.initialize();

      expect(cubit.state.localeCode, 'ar');
      expect(cubit.state.localePreference, 'ar');
      await cubit.close();
    });

    test('saved en + Arabic device -> en/en', () async {
      _setTestLocales(const [Locale('ar')]);

      final cubit = await _createCubit({'app_locale_code': 'en'});
      await cubit.initialize();

      expect(cubit.state.localeCode, 'en');
      expect(cubit.state.localePreference, 'en');
      await cubit.close();
    });

    test('saved preference survives re-initialization', () async {
      _setTestLocales(const [Locale('en')]);

      final cubit = await _createCubit({'app_locale_code': 'ar'});
      await cubit.initialize();
      await cubit.close();

      final cubit2 = await _createCubit({'app_locale_code': 'ar'});
      await cubit2.initialize();

      expect(cubit2.state.localeCode, 'ar');
      expect(cubit2.state.localePreference, 'ar');
      await cubit2.close();
    });

    test('device language change does not override saved ar', () async {
      _setTestLocales(const [Locale('en')]);

      final cubit = await _createCubit({'app_locale_code': 'ar'});
      await cubit.initialize();
      expect(cubit.state.localeCode, 'ar');

      _setTestLocales(const [Locale('ar')]);
      await cubit.initialize();

      expect(cubit.state.localeCode, 'ar');
      expect(cubit.state.localePreference, 'ar');
      await cubit.close();
    });

    test('setLocaleCode(ar) persists and updates state', () async {
      _setTestLocales(const [Locale('en')]);

      final cubit = await _createCubit({});
      await cubit.initialize();
      await cubit.setLocaleCode('ar');

      expect(cubit.state.localeCode, 'ar');
      expect(cubit.state.localePreference, 'ar');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_locale_code'), 'ar');
      await cubit.close();
    });

    test('setLocaleCode(en) persists and updates state', () async {
      _setTestLocales(const [Locale('ar')]);

      final cubit = await _createCubit({});
      await cubit.initialize();
      await cubit.setLocaleCode('en');

      expect(cubit.state.localeCode, 'en');
      expect(cubit.state.localePreference, 'en');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_locale_code'), 'en');
      await cubit.close();
    });

    test('setLocaleToSystem persists system and follows device', () async {
      _setTestLocales(const [Locale('ar')]);

      final cubit = await _createCubit({'app_locale_code': 'en'});
      await cubit.initialize();
      await cubit.setLocaleToSystem();

      expect(cubit.state.localePreference, 'system');
      expect(cubit.state.localeCode, 'ar');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_locale_code'), 'system');
      await cubit.close();
    });

    test('restoreDefaultPreferences sets language to system mode', () async {
      _setTestLocales(const [Locale('ar')]);

      final cubit = await _createCubit({'app_locale_code': 'en'});
      await cubit.initialize();
      await cubit.restoreDefaultPreferences();

      expect(cubit.state.localePreference, 'system');
      expect(cubit.state.localeCode, 'ar');
      expect(cubit.state.themeMode, ThemeMode.system);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_locale_code'), 'system');
      await cubit.close();
    });
  });

  group('AppCubit.resolveLocaleCode static helper', () {
    test('resolveLocaleCode honors explicit stored values', () {
      expect(AppCubit.resolveLocaleCode('ar'), 'ar');
      expect(AppCubit.resolveLocaleCode('en'), 'en');
    });
  });

  group('RTL / LTR through MaterialApp locale', () {
    testWidgets('Arabic locale uses RTL', (tester) async {
      _setTestLocales(const [Locale('ar')]);

      final cubit = await _createCubit({});
      await cubit.initialize();

      await tester.pumpWidget(
        BlocProvider.value(
          value: cubit,
          child: MaterialApp(
            locale: cubit.state.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) {
                return Text(Directionality.of(context).name);
              },
            ),
          ),
        ),
      );

      expect(find.text('rtl'), findsOneWidget);
      await cubit.close();
    });

    testWidgets('English locale uses LTR', (tester) async {
      _setTestLocales(const [Locale('en')]);

      final cubit = await _createCubit({'app_locale_code': 'en'});
      await cubit.initialize();

      await tester.pumpWidget(
        BlocProvider.value(
          value: cubit,
          child: MaterialApp(
            locale: cubit.state.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) {
                return Text(Directionality.of(context).name);
              },
            ),
          ),
        ),
      );

      expect(find.text('ltr'), findsOneWidget);
      await cubit.close();
    });
  });

  group('LanguageSettingsPage', () {
    testWidgets('shows System default option bound to localePreference',
        (tester) async {
      _setTestLocales(const [Locale('ar')]);

      final cubit = await _createCubit({});
      await cubit.initialize();
      expect(cubit.state.localePreference, 'system');

      await tester.pumpWidget(
        BlocProvider.value(
          value: cubit,
          child: const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: LanguageSettingsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('System default'), findsOneWidget);
      expect(find.text('Arabic'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(cubit.state.localePreference, 'system');

      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      expect(cubit.state.localePreference, 'en');
      expect(cubit.state.localeCode, 'en');

      await tester.tap(find.text('System default'));
      await tester.pumpAndSettle();
      expect(cubit.state.localePreference, 'system');
      expect(cubit.state.localeCode, 'ar');

      await cubit.close();
    });

    testWidgets('system stays selected when resolved locale is Arabic',
        (tester) async {
      _setTestLocales(const [Locale('ar')]);

      final cubit = await _createCubit({});
      await cubit.initialize();

      expect(cubit.state.localeCode, 'ar');
      expect(cubit.state.localePreference, 'system');

      await tester.pumpWidget(
        BlocProvider.value(
          value: cubit,
          child: MaterialApp(
            locale: cubit.state.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const LanguageSettingsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(cubit.state.localePreference, 'system');
      expect(cubit.state.localeCode, 'ar');

      await cubit.close();
    });
  });
}
