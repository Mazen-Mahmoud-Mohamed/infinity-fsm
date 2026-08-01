import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/localization/app_formatters.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/duration_formatter.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_app_message.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/core/widgets/app_loader.dart';
import 'package:mobile/core/widgets/app_refresh_bar.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/features/attendance/presentation/widgets/working_timer.dart';
import 'package:mobile/features/auth/domain/entities/current_user.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/core/widgets/offline_banner.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:mobile/features/overtime/presentation/pages/overtime_admin_page.dart';
import 'package:mobile/features/overtime/presentation/utils/overtime_labels.dart';
import 'package:mobile/features/overtime/presentation/cubit/overtime_cubit.dart';
import 'package:mobile/features/overtime/presentation/cubit/overtime_state.dart';

/// Bottom-nav / `/overtime` entry.
///
/// Admin & Supervisor open [OvertimeAdminPage] (management).
/// Technicians open personal Start/End tracking.
class OvertimePage extends StatelessWidget {
  const OvertimePage({super.key});

  static bool opensManagementFor(CurrentUser? user) {
    if (user == null) return false;
    final roles = user.roles.map((role) => role.toUpperCase());
    if (roles.contains('ADMIN') || roles.contains('SUPERVISOR')) {
      return true;
    }
    final permissions = user.permissionChecker;
    return permissions.canViewAllOvertime() || permissions.canApproveOvertime();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.user;
    if (opensManagementFor(user)) {
      return const OvertimeAdminPage();
    }

    return BlocProvider(
      create: (_) => getIt<OvertimeCubit>()..initialize(),
      child: const _OvertimeTrackingView(),
    );
  }
}

class _OvertimeTrackingView extends StatelessWidget {
  const _OvertimeTrackingView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final permissions =
        context.watch<AuthCubit>().state.user?.permissionChecker;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.overtime),
        actions: [
          IconButton(
            tooltip: l10n.overtimeMyTooltip,
            onPressed: () => context.push(RoutePaths.overtimeHistory),
            icon: const Icon(Icons.history),
          ),
          if (permissions?.canViewAllOvertime() == true)
            IconButton(
              tooltip: l10n.overtimeManageTooltip,
              onPressed: () => context.push(RoutePaths.overtimeAdmin),
              icon: const Icon(Icons.admin_panel_settings_outlined),
            ),
        ],
      ),
      body: BlocConsumer<OvertimeCubit, OvertimeState>(
        buildWhen: (previous, current) {
          // Elapsed ticker only bumps [elapsedSeconds]; keep heavy body
          // off the 1 Hz path (timer UI uses BlocSelector below).
          if (identical(previous, current)) return false;
          return previous.status != current.status ||
              previous.session != current.session ||
              previous.completedSession != current.completedSession ||
              previous.busyAction != current.busyAction ||
              previous.isOffline != current.isOffline ||
              previous.message != current.message ||
              previous.isError != current.isError ||
              previous.currentAddress != current.currentAddress ||
              previous.isRefreshing != current.isRefreshing;
        },
        listenWhen: (previous, current) =>
            previous.message != current.message &&
            current.message != null &&
            !current.isOffline &&
            !isUserFacingNetworkNoise(current.message),
        listener: (context, state) {
          if (state.message == null ||
              isUserFacingNetworkNoise(state.message)) {
            return;
          }
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(localizeAppMessage(l10n, state.message)),
                backgroundColor: state.isError
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.inverseSurface,
                behavior: SnackBarBehavior.floating,
              ),
            );
          context.read<OvertimeCubit>().clearFeedback();
        },
        builder: (context, state) {
          if (state.status == OvertimeLoadStatus.loading &&
              state.session == null &&
              !state.isRefreshing) {
            return AppLoader(message: l10n.overtimeLoading);
          }

          if (state.status == OvertimeLoadStatus.failure &&
              state.session == null &&
              !state.isOffline &&
              !isUserFacingNetworkNoise(state.message)) {
            return _ErrorView(
              message: localizeAppMessage(
                l10n,
                state.message ?? 'overtimeLoadFailed',
              ),
              onRetry: () => context.read<OvertimeCubit>().initialize(),
            );
          }

          return Column(
            children: [
              AppRefreshBar(visible: state.isRefreshing),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => context.read<OvertimeCubit>().refresh(),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: AppScrollPadding.resolve(
                      context,
                      base: const EdgeInsets.all(AppSpacing.lg),
                      chrome: AppBottomChrome.system,
                    ),
                    children: [
                      if (state.completedSession != null) ...[
                        _CompletedSummaryCard(
                          session: state.completedSession!,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      if (state.isRunning && state.session != null)
                        _RunningSessionCard(
                          session: state.session!,
                          address: state.currentAddress,
                          isBusy: state.isBusy,
                          isEnding: state.isEnding,
                          onEnd: () =>
                              context.read<OvertimeCubit>().endSession(),
                        )
                      else
                        _StartActions(
                          isBusy: state.isBusy,
                          isNormalBusy: state.isStartingNormal,
                          isTravelBusy: state.isStartingTravel,
                          onStartNormal: () =>
                              context.read<OvertimeCubit>().startNormal(),
                          onStartTravel: () =>
                              context.read<OvertimeCubit>().startTravel(),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StartActions extends StatelessWidget {
  const _StartActions({
    required this.isBusy,
    required this.isNormalBusy,
    required this.isTravelBusy,
    required this.onStartNormal,
    required this.onStartTravel,
  });

  final bool isBusy;
  final bool isNormalBusy;
  final bool isTravelBusy;
  final VoidCallback onStartNormal;
  final VoidCallback onStartTravel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.overtimeStartTitle,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.overtimeStartHint,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        ElevatedButton.icon(
          onPressed: isBusy ? null : onStartNormal,
          icon: isNormalBusy
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.onPrimary,
                  ),
                )
              : const Icon(Icons.more_time),
          label: Text(l10n.overtimeStartNormal),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: isBusy ? null : onStartTravel,
          icon: isTravelBusy
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.primary,
                  ),
                )
              : const Icon(Icons.directions_car_outlined),
          label: Text(l10n.overtimeStartTravel),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }
}

class _RunningSessionCard extends StatelessWidget {
  const _RunningSessionCard({
    required this.session,
    required this.address,
    required this.isBusy,
    required this.isEnding,
    required this.onEnd,
  });

  final OvertimeSession session;
  final String? address;
  final bool isBusy;
  final bool isEnding;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormat = AppFormatters.jm(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  overtimeTypeLabel(AppLocalizations.of(context), session.type),
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                _MetaRow(
                  label: AppLocalizations.of(context).overtimeStatusLabel,
                  value: overtimeStatusLabel(
                    AppLocalizations.of(context),
                    session.status,
                  ),
                ),
                _MetaRow(
                  label: AppLocalizations.of(context).overtimeStartTime,
                  value: timeFormat.format(session.startAt.toLocal()),
                ),
                _MetaRow(
                  label: AppLocalizations.of(context).overtimeLocation,
                  value: address?.isNotEmpty == true
                      ? address!
                      : '${session.startGps.latitude.toStringAsFixed(5)}, ${session.startGps.longitude.toStringAsFixed(5)}',
                ),
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: BlocSelector<OvertimeCubit, OvertimeState, int>(
                    selector: (state) => state.elapsedSeconds,
                    builder: (context, seconds) =>
                        WorkingTimer(seconds: seconds),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Center(
                  child: Text(
                    AppLocalizations.of(context).overtimeRunningTimer,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        ElevatedButton.icon(
          onPressed: isBusy ? null : onEnd,
          icon: isEnding
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.onPrimary,
                  ),
                )
              : const Icon(Icons.stop_circle_outlined),
          label: Text(AppLocalizations.of(context).overtimeEnd),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }
}

class _CompletedSummaryCard extends StatelessWidget {
  const _CompletedSummaryCard({required this.session});

  final OvertimeSession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).overtimeLastSessionSummary,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            _MetaRow(label: l10n.labelType, value: overtimeTypeLabel(l10n, session.type)),
            _MetaRow(
              label: l10n.overtimeTotalDuration,
              value: DurationFormatter.fromMinutes(
                session.totalDurationMinutes,
                l10n,
              ),
            ),
            _MetaRow(
              label: l10n.overtimeWorkingDuration,
              value: DurationFormatter.fromMinutes(
                session.workingDurationMinutes,
                l10n,
              ),
            ),
            _MetaRow(
              label: AppLocalizations.of(context).overtimeEligible,
              value: DurationFormatter.fromMinutes(
                session.eligibleOvertimeMinutes,
                l10n,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: onRetry,
              child: Text(AppLocalizations.of(context).retry),
            ),
          ],
        ),
      ),
    );
  }
}
