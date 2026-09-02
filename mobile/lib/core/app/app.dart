import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/config/app_config.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_app_message.dart';
import 'package:mobile/core/theme/app_system_ui.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/push/push_notification_service.dart';
import 'package:mobile/features/app_update/data/services/app_update_notification_service.dart';
import 'package:mobile/features/app_update/presentation/cubit/update_center_cubit.dart';
import 'package:mobile/features/attendance/presentation/cubit/attendance_cubit.dart';
import 'package:mobile/features/attendance/presentation/cubit/attendance_sync_cubit.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/core/widgets/offline_banner.dart';
import 'package:mobile/features/global_search/presentation/widgets/global_search_dialog.dart';
import 'package:mobile/features/notifications/presentation/cubit/notifications_unread_cubit.dart';
import 'package:mobile/features/overtime/presentation/cubit/overtime_sync_cubit.dart';
import 'package:mobile/features/settings/presentation/cubit/technician_interface_cubits.dart';
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
        BlocProvider<NotificationsUnreadCubit>.value(
          value: getIt<NotificationsUnreadCubit>(),
        ),
        BlocProvider<TechnicianInterfaceCubit>.value(
          value: getIt<TechnicianInterfaceCubit>(),
        ),
        BlocProvider<UpdateCenterCubit>.value(
          value: getIt<UpdateCenterCubit>(),
        ),
      ],
      child: const _InfinityAppUpdateBootstrap(
        child: _InfinityAppAuthSyncBootstrap(
          child: _InfinityAppShell(),
        ),
      ),
    );
  }
}

/// Ensures overtime/attendance sync is armed when Auth is already authenticated
/// (BlocListener does not fire for the initial state).
class _InfinityAppAuthSyncBootstrap extends StatefulWidget {
  const _InfinityAppAuthSyncBootstrap({required this.child});

  final Widget child;

  @override
  State<_InfinityAppAuthSyncBootstrap> createState() =>
      _InfinityAppAuthSyncBootstrapState();
}

class _InfinityAppAuthSyncBootstrapState
    extends State<_InfinityAppAuthSyncBootstrap> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (context.read<AuthCubit>().state.status == AuthStatus.authenticated) {
        context.read<OvertimeSyncCubit>().resumeAuthenticatedSync();
        context.read<AttendanceSyncCubit>().resumeAuthenticatedSync();
        getIt<PushNotificationService>().onAuthenticated();
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _InfinityAppUpdateBootstrap extends StatefulWidget {
  const _InfinityAppUpdateBootstrap({required this.child});

  final Widget child;

  @override
  State<_InfinityAppUpdateBootstrap> createState() =>
      _InfinityAppUpdateBootstrapState();
}

class _InfinityAppUpdateBootstrapState extends State<_InfinityAppUpdateBootstrap>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthCubit>().state.status ==
          AuthStatus.authenticated;
      getIt<UpdateCenterCubit>().bindReleaseChannel(
        context.read<AppCubit>().state.releaseChannel,
      );
      unawaited(getIt<UpdateCenterCubit>().onAppReady(isAuthenticated: auth));
      unawaited(getIt<AppUpdateNotificationService>().initialize());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        context.read<AuthCubit>().state.status == AuthStatus.authenticated) {
      getIt<UpdateCenterCubit>().maybeAutoCheck(
        reason: AppUpdateAutoCheckReason.resumed,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AppCubit, AppState>(
          listenWhen: (previous, current) =>
              previous.releaseChannel != current.releaseChannel,
          listener: (_, state) {
            getIt<UpdateCenterCubit>().bindReleaseChannel(state.releaseChannel);
          },
        ),
        BlocListener<AppCubit, AppState>(
          listenWhen: (previous, current) =>
              !previous.connectivity.canSync && current.connectivity.canSync,
          listener: (_, state) {
            if (context.read<AuthCubit>().state.status !=
                AuthStatus.authenticated) {
              return;
            }
            getIt<UpdateCenterCubit>().maybeAutoCheck(
              reason: AppUpdateAutoCheckReason.connectivityRestored,
            );
          },
        ),
        BlocListener<AuthCubit, AuthState>(
          listenWhen: (previous, current) =>
              previous.status != current.status &&
              current.status == AuthStatus.authenticated,
          listener: (_, state) {
            getIt<UpdateCenterCubit>().onAppReady(isAuthenticated: true);
          },
        ),
      ],
      child: widget.child,
    );
  }
}

class _InfinityAppShell extends StatelessWidget {
  const _InfinityAppShell();

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthCubit, AuthState>(
          listenWhen: (previous, current) =>
              previous.status != current.status &&
              current.status == AuthStatus.unauthenticated,
          listener: (context, state) {
            getIt<TechnicianInterfaceCubit>().clear();
          },
        ),
        BlocListener<AuthCubit, AuthState>(
          listenWhen: (previous, current) =>
              previous.message != current.message &&
              current.message != null &&
              !isUserFacingNetworkNoise(current.message),
          listener: (context, state) {
            if (state.message == null ||
                isUserFacingNetworkNoise(state.message)) {
              return;
            }
            InfinityApp.scaffoldMessengerKey.currentState
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
        ),
        BlocListener<AuthCubit, AuthState>(
          listenWhen: (previous, current) =>
              previous.status != current.status,
          listener: (context, state) {
            final unread = context.read<NotificationsUnreadCubit>();
            final attendanceSync = context.read<AttendanceSyncCubit>();
            final overtimeSync = context.read<OvertimeSyncCubit>();
            if (state.status == AuthStatus.authenticated) {
              unread.refresh();
              attendanceSync.resumeAuthenticatedSync();
              overtimeSync.resumeAuthenticatedSync();
              getIt<PushNotificationService>().onAuthenticated();
            } else if (state.status == AuthStatus.unauthenticated) {
              unread.clear();
              getIt<AttendanceCubit>().resetForLogout();
              attendanceSync.pauseAuthenticatedSync();
              overtimeSync.pauseAuthenticatedSync();
              getIt<PushNotificationService>().onLoggedOut();
            }
          },
        ),
      ],
      child: BlocBuilder<AppCubit, AppState>(
        buildWhen: (previous, current) =>
            previous.themeMode != current.themeMode ||
            previous.localeCode != current.localeCode ||
            previous.largeText != current.largeText ||
            previous.reduceAnimations != current.reduceAnimations ||
            previous.highContrast != current.highContrast,
        builder: (context, appState) {
          return MaterialApp.router(
            scaffoldMessengerKey: InfinityApp.scaffoldMessengerKey,
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
              final media = MediaQuery.of(context);
              final scaled = media.copyWith(
                textScaler: TextScaler.linear(
                  appState.largeText ? 1.2 : media.textScaler.scale(1),
                ),
                disableAnimations: appState.reduceAnimations,
                boldText: appState.highContrast ? true : media.boldText,
              );
              return MediaQuery(
                data: scaled,
                child: AnnotatedRegion(
                  value: AppSystemUi.overlayFor(theme),
                  child: Shortcuts(
                    shortcuts: const <ShortcutActivator, Intent>{
                      SingleActivator(LogicalKeyboardKey.keyK, control: true):
                          OpenGlobalSearchIntent(),
                      SingleActivator(LogicalKeyboardKey.keyK, meta: true):
                          OpenGlobalSearchIntent(),
                    },
                    child: Actions(
                      actions: <Type, Action<Intent>>{
                        OpenGlobalSearchIntent:
                            CallbackAction<OpenGlobalSearchIntent>(
                          onInvoke: (_) {
                            openGlobalSearch(context);
                            return null;
                          },
                        ),
                      },
                      child: child ?? const SizedBox.shrink(),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
