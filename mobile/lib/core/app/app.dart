import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/config/app_config.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_app_message.dart';
import 'package:mobile/core/theme/app_system_ui.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/attendance/presentation/cubit/attendance_sync_cubit.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/core/widgets/offline_banner.dart';
import 'package:mobile/features/overtime/presentation/cubit/overtime_sync_cubit.dart';
import 'package:mobile/shared/presentation/cubit/app_cubit.dart';

class InfinityApp extends StatelessWidget {
  const InfinityApp({super.key});

  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AppCubit>.value(value: getIt<AppCubit>()),
        BlocProvider<AuthCubit>.value(value: getIt<AuthCubit>()),
        BlocProvider<AttendanceSyncCubit>.value(
          value: getIt<AttendanceSyncCubit>(),
        ),
        BlocProvider<OvertimeSyncCubit>.value(
          value: getIt<OvertimeSyncCubit>(),
        ),
      ],
      child: BlocListener<AuthCubit, AuthState>(
        listenWhen: (previous, current) =>
            previous.message != current.message &&
            current.message != null &&
            !isUserFacingNetworkNoise(current.message),
        listener: (context, state) {
          if (state.message == null ||
              isUserFacingNetworkNoise(state.message)) {
            return;
          }
          scaffoldMessengerKey.currentState
            ?..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  localizeAppMessage(
                    AppLocalizations.of(context),
                    state.message,
                  ),
                ),
              ),
            );
        },
        child: BlocBuilder<AppCubit, AppState>(
          buildWhen: (previous, current) =>
              previous.themeMode != current.themeMode ||
              previous.localeCode != current.localeCode,
          builder: (context, appState) {
            return MaterialApp.router(
              scaffoldMessengerKey: scaffoldMessengerKey,
              title: AppConfig.appName,
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: appState.themeMode,
              locale: appState.locale,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              routerConfig: getIt<GoRouter>(),
              builder: (context, child) {
                final theme = Theme.of(context);
                AppSystemUi.apply(theme);
                return AnnotatedRegion(
                  value: AppSystemUi.overlayFor(theme),
                  child: child ?? const SizedBox.shrink(),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
