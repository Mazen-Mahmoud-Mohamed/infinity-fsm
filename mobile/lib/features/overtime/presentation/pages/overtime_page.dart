import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/app_formatters.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_app_message.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/core/widgets/app_loader.dart';
import 'package:mobile/core/widgets/technician_main_app_bar.dart';
import 'package:mobile/core/widgets/app_refresh_bar.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/features/attendance/presentation/widgets/working_timer.dart';
import 'package:mobile/features/auth/domain/entities/current_user.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/core/widgets/offline_banner.dart';
import 'package:mobile/features/notifications/presentation/widgets/notifications_bell_action.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_checkpoint.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_type.dart';
import 'package:mobile/features/overtime/domain/entities/pending_overtime_action.dart';
import 'package:mobile/features/overtime/presentation/pages/overtime_admin_page.dart';
import 'package:mobile/features/overtime/presentation/utils/overtime_labels.dart';
import 'package:mobile/features/overtime/presentation/cubit/overtime_cubit.dart';
import 'package:mobile/features/overtime/presentation/cubit/overtime_state.dart';
import 'package:mobile/features/overtime/presentation/cubit/overtime_sync_cubit.dart';
import 'package:mobile/features/overtime/presentation/widgets/overtime_journey_timeline.dart';
import 'package:mobile/features/overtime/domain/services/overtime_cellular_upload_prompt_service.dart';
import 'package:mobile/features/overtime/presentation/widgets/overtime_cellular_upload_dialog.dart';
import 'package:mobile/features/overtime/presentation/widgets/overtime_voice_note_section.dart';

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

class _OvertimeTrackingView extends StatefulWidget {
  const _OvertimeTrackingView();

  @override
  State<_OvertimeTrackingView> createState() => _OvertimeTrackingViewState();
}

class _OvertimeTrackingViewState extends State<_OvertimeTrackingView> {
  @override
  void initState() {
    super.initState();
    getIt<OvertimeCellularUploadPromptService>().register(
      () => showCellularUploadPrompt(context),
    );
  }

  @override
  void dispose() {
    getIt<OvertimeCellularUploadPromptService>().unregister();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final permissions = context
        .watch<AuthCubit>()
        .state
        .user
        ?.permissionChecker;
    final syncState = context.watch<OvertimeSyncCubit>().state;

    return Scaffold(
      appBar: TechnicianMainAppBar(
        title: Text(l10n.overtime),
        actions: [
          const NotificationsBellAction(),
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
              previous.isRefreshing != current.isRefreshing ||
              previous.offerContinueSession != current.offerContinueSession ||
              previous.liveBatteryLevel != current.liveBatteryLevel ||
              previous.liveNetworkStatus != current.liveNetworkStatus ||
              previous.gpsAccuracyMeters != current.gpsAccuracyMeters ||
              previous.notesDraft != current.notesDraft ||
              previous.voiceDraft != current.voiceDraft;
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
          final isContinuePrompt =
              state.message == 'overtimeContinueExistingSession';
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(localizeAppMessage(l10n, state.message)),
                action: isContinuePrompt
                    ? SnackBarAction(
                        label: l10n.overtimeContinueSession,
                        onPressed: () => context
                            .read<OvertimeCubit>()
                            .continueExistingSession(),
                      )
                    : null,
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
                state.message != null
                    ? localizeAppMessage(l10n, state.message)
                    : l10n.overtimeLoadFailed,
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
                      if (state.offerContinueSession && state.isRunning) ...[
                        _ContinueSessionBanner(
                          onContinue: () => context
                              .read<OvertimeCubit>()
                              .continueExistingSession(),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      if (state.completedSession != null) ...[
                        _CompletedSummaryCard(session: state.completedSession!),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      if (state.isRunning && state.session != null)
                        _RunningSessionCard(
                          session: state.session!,
                          address: state.currentAddress,
                          isBusy: state.isBusy,
                          busyAction: state.busyAction,
                          liveBatteryLevel: state.liveBatteryLevel,
                          liveNetworkStatus: state.liveNetworkStatus,
                          gpsAccuracyMeters: state.gpsAccuracyMeters,
                          pendingSyncCount: syncState.pendingCount,
                          pendingActions: syncState.pendingActions,
                          isOffline: state.isOffline || !syncState.isOnline,
                          onAdvance: () => context
                              .read<OvertimeCubit>()
                              .completeNextCheckpoint(),
                        )
                      else
                        _StartActions(
                          isBusy: state.isBusy,
                          isStarting: state.isStarting,
                          offerContinueSession: state.offerContinueSession,
                          onStart:
                              ({
                                required bool travel,
                                required bool overnight,
                              }) {
                                final cubit = context.read<OvertimeCubit>();
                                if (!travel) {
                                  cubit.start(type: OvertimeType.normal);
                                } else {
                                  cubit.start(
                                    type: OvertimeType.travel,
                                    isOvernight: overnight,
                                  );
                                }
                              },
                          onContinue: () => context
                              .read<OvertimeCubit>()
                              .continueExistingSession(),
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

class _ContinueSessionBanner extends StatelessWidget {
  const _ContinueSessionBanner({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: colorScheme.onTertiaryContainer),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              l10n.overtimeContinueExistingSession,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onTertiaryContainer,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton.tonal(
            onPressed: onContinue,
            child: Text(l10n.overtimeContinueSession),
          ),
        ],
      ),
    );
  }
}

class _StartActions extends StatefulWidget {
  const _StartActions({
    required this.isBusy,
    required this.isStarting,
    required this.onStart,
    this.offerContinueSession = false,
    this.onContinue,
  });

  final bool isBusy;
  final bool isStarting;
  final bool offerContinueSession;
  final void Function({required bool travel, required bool overnight}) onStart;
  final VoidCallback? onContinue;

  @override
  State<_StartActions> createState() => _StartActionsState();
}

class _StartActionsState extends State<_StartActions> {
  bool _travel = false;
  bool _overnight = false;

  void _onTravelChanged(bool? value) {
    final next = value ?? false;
    setState(() {
      _travel = next;
      if (!next) {
        _overnight = false;
      }
    });
  }

  void _onOvernightChanged(bool? value) {
    if (!_travel) return;
    setState(() => _overnight = value ?? false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isBusy = widget.isBusy;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.offerContinueSession && widget.onContinue != null) ...[
          _ContinueSessionBanner(onContinue: widget.onContinue!),
          const SizedBox(height: AppSpacing.lg),
        ],
        Text(l10n.overtimeStartTitle, style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.xl),
        TextField(
          enabled: !isBusy,
          maxLines: 2,
          maxLength: 1000,
          decoration: InputDecoration(
            labelText: l10n.overtimeNotes,
            hintText: l10n.overtimeNotesOptionalHint,
            border: const OutlineInputBorder(),
          ),
          onChanged: (value) =>
              context.read<OvertimeCubit>().updateNotesDraft(value),
        ),
        const SizedBox(height: AppSpacing.md),
        CheckboxListTile(
          value: _travel,
          onChanged: isBusy ? null : _onTravelChanged,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.overtimeTravel),
          secondary: Icon(
            Icons.directions_car_outlined,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: !_travel
              ? const SizedBox.shrink()
              : CheckboxListTile(
                  value: _overnight,
                  onChanged: isBusy ? null : _onOvernightChanged,
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: const EdgeInsets.only(left: AppSpacing.lg),
                  title: Text(l10n.overtimeOvernightStay),
                  secondary: Icon(
                    Icons.hotel_outlined,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
        ),
        const SizedBox(height: AppSpacing.md),
        OvertimeVoiceNoteSection(
          key: const ValueKey('overtime-start-voice'),
          maxDurationSeconds: context.select(
            (OvertimeCubit c) => c.state.voiceMaxDurationSeconds,
          ),
          voiceRecordingQuality: context.select(
            (OvertimeCubit c) => c.state.voiceRecordingQuality,
          ),
          localBytes: context.read<OvertimeCubit>().state.voiceDraft?.bytes,
          durationSeconds: context
              .read<OvertimeCubit>()
              .state
              .voiceDraft
              ?.durationSeconds,
          enabled: !isBusy,
          onDraftChanged: (OvertimeVoiceDraft? draft) =>
              context.read<OvertimeCubit>().updateVoiceDraft(draft),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton.icon(
          onPressed: isBusy
              ? null
              : () => widget.onStart(travel: _travel, overnight: _overnight),
          icon: widget.isStarting
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.onPrimary,
                  ),
                )
              : const Icon(Icons.more_time),
          label: Text(l10n.overtimeStart),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
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
    required this.busyAction,
    required this.onAdvance,
    this.liveBatteryLevel,
    this.liveNetworkStatus,
    this.gpsAccuracyMeters,
    this.pendingSyncCount = 0,
    this.pendingActions = const [],
    this.isOffline = false,
  });

  final OvertimeSession session;
  final String? address;
  final bool isBusy;
  final OvertimeBusyAction? busyAction;
  final VoidCallback onAdvance;
  final int? liveBatteryLevel;
  final String? liveNetworkStatus;
  final double? gpsAccuracyMeters;
  final int pendingSyncCount;
  final List<PendingOvertimeAction> pendingActions;
  final bool isOffline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final next = session.effectiveNextCheckpoint;
    final actionLabel = _nextActionLabel(l10n, next);
    final isAdvancing =
        busyAction == OvertimeBusyAction.arrivedAtWorkSite ||
        busyAction == OvertimeBusyAction.finishedWork ||
        busyAction == OvertimeBusyAction.end;
    final completed = overtimeCompletedCheckpointCount(session);
    final total = overtimeTotalCheckpointCount(session);
    final currentStageTitle = _currentStageTitle(l10n, next, session);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        overtimeTypeLabel(l10n, session.type),
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    _SyncStatusChip(
                      pendingCount: pendingSyncCount,
                      isOffline: isOffline,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                _MetaRow(
                  label: l10n.overtimeCurrentStage,
                  value: currentStageTitle,
                ),
                _MetaRow(
                  label: l10n.overtimeProgress,
                  value: l10n.overtimeProgressOf(completed, total),
                ),
                if (address != null && address!.isNotEmpty)
                  _MetaRow(label: l10n.overtimeLocation, value: address!),
                if (gpsAccuracyMeters != null)
                  _MetaRow(
                    label: l10n.overtimeGpsStatus,
                    value: '${gpsAccuracyMeters!.toStringAsFixed(0)} m',
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
                    l10n.overtimeRunningTimer,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    if (liveBatteryLevel != null)
                      _TelemetryChip(
                        icon: Icons.battery_std_outlined,
                        label: '$liveBatteryLevel%',
                      ),
                    if (liveNetworkStatus != null &&
                        liveNetworkStatus!.isNotEmpty)
                      _TelemetryChip(
                        icon: liveNetworkStatus == 'offline'
                            ? Icons.wifi_off_outlined
                            : Icons.wifi_outlined,
                        label: liveNetworkStatus!,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(l10n.overtimeProgress, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        OvertimeJourneyProgressStrip(session: session),
        const SizedBox(height: AppSpacing.lg),
        Text(l10n.overtimeJourneyTimeline, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.md),
        OvertimeJourneyTimeline(
          session: session,
          // Technicians track stages; live-location review is for admins/supervisors.
          showOpenLiveLocation: false,
          maxDurationSeconds: context.select(
            (OvertimeCubit c) => c.state.voiceMaxDurationSeconds,
          ),
          voiceRecordingQuality: context.select(
            (OvertimeCubit c) => c.state.voiceRecordingQuality,
          ),
          pendingActions: pendingActions,
          isOffline: isOffline,
          isSyncing:
              context.watch<OvertimeSyncCubit>().state.status ==
              OvertimeSyncStatus.syncing,
          onPendingVoiceChanged: (stage, draft) {
            context.read<OvertimeCubit>().updatePendingStageVoice(
              stage: stage,
              draft: draft,
            );
            context.read<OvertimeSyncCubit>().refreshPendingCount();
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          // Fresh EditableText state per stage (mirrors Voice Note keying).
          key: ValueKey('overtime-active-notes-${next?.apiValue ?? 'none'}'),
          enabled: !isBusy,
          maxLines: 2,
          maxLength: 1000,
          decoration: InputDecoration(
            labelText: l10n.overtimeNotes,
            hintText: l10n.overtimeNotesOptionalHint,
            border: const OutlineInputBorder(),
          ),
          onChanged: (value) =>
              context.read<OvertimeCubit>().updateNotesDraft(value),
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        ),
        const SizedBox(height: AppSpacing.md),
        OvertimeVoiceNoteSection(
          // Fresh State per journey stage so prior recordings never linger
          // in the active recorder UI after advancing.
          key: ValueKey('overtime-active-voice-${next?.apiValue ?? 'none'}'),
          maxDurationSeconds: context.select(
            (OvertimeCubit c) => c.state.voiceMaxDurationSeconds,
          ),
          voiceRecordingQuality: context.select(
            (OvertimeCubit c) => c.state.voiceRecordingQuality,
          ),
          localBytes: context.read<OvertimeCubit>().state.voiceDraft?.bytes,
          durationSeconds: context
              .read<OvertimeCubit>()
              .state
              .voiceDraft
              ?.durationSeconds,
          enabled: !isBusy,
          onDraftChanged: (OvertimeVoiceDraft? draft) =>
              context.read<OvertimeCubit>().updateVoiceDraft(draft),
        ),
        const SizedBox(height: AppSpacing.md),
        ElevatedButton.icon(
          onPressed: isBusy || next == null ? null : onAdvance,
          icon: isAdvancing
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.onPrimary,
                  ),
                )
              : Icon(_nextActionIcon(next)),
          label: Text(actionLabel),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 20),
            textStyle: theme.textTheme.titleMedium,
          ),
        ),
      ],
    );
  }

  static String _currentStageTitle(
    AppLocalizations l10n,
    OvertimeCheckpointStage? next,
    OvertimeSession session,
  ) {
    if (next == null) {
      return l10n.overtimeStageEndJourney;
    }
    switch (next) {
      case OvertimeCheckpointStage.startJourney:
        return l10n.overtimeStageStartJourney;
      case OvertimeCheckpointStage.arrivedAtWorkSite:
        return l10n.overtimeStageArrivedAtWorkSite;
      case OvertimeCheckpointStage.finishedWork:
        return l10n.overtimeStageFinishedWork;
      case OvertimeCheckpointStage.endJourney:
        return l10n.overtimeStageEndJourney;
    }
  }

  static String _nextActionLabel(
    AppLocalizations l10n,
    OvertimeCheckpointStage? next,
  ) {
    switch (next) {
      case OvertimeCheckpointStage.arrivedAtWorkSite:
        return l10n.overtimeArrivedAtWorkSite;
      case OvertimeCheckpointStage.finishedWork:
        return l10n.overtimeFinishedWork;
      case OvertimeCheckpointStage.endJourney:
        return l10n.overtimeEnd;
      case OvertimeCheckpointStage.startJourney:
      case null:
        return l10n.overtimeEnd;
    }
  }

  static IconData _nextActionIcon(OvertimeCheckpointStage? next) {
    switch (next) {
      case OvertimeCheckpointStage.arrivedAtWorkSite:
        return Icons.location_on_outlined;
      case OvertimeCheckpointStage.finishedWork:
        return Icons.handyman_outlined;
      case OvertimeCheckpointStage.endJourney:
        return Icons.flag_outlined;
      case OvertimeCheckpointStage.startJourney:
      case null:
        return Icons.stop_circle_outlined;
    }
  }
}

class _SyncStatusChip extends StatelessWidget {
  const _SyncStatusChip({required this.pendingCount, required this.isOffline});

  final int pendingCount;
  final bool isOffline;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final (label, color, icon) = isOffline
        ? (
            l10n.overtimeSyncOffline,
            colorScheme.outline,
            Icons.cloud_off_outlined,
          )
        : pendingCount > 0
        ? (
            l10n.overtimeSyncPending,
            colorScheme.tertiary,
            Icons.cloud_upload_outlined,
          )
        : (
            l10n.overtimeSyncSynced,
            colorScheme.primary,
            Icons.cloud_done_outlined,
          );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _TelemetryChip extends StatelessWidget {
  const _TelemetryChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
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
    final timeFormat = AppFormatters.mediumDateTime(context);

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
            _MetaRow(
              label: l10n.labelType,
              value: overtimeTypeLabel(l10n, session.type),
            ),
            _MetaRow(
              label: l10n.overtimeStatusLabel,
              value: overtimeStatusLabel(l10n, session.status),
            ),
            _MetaRow(
              label: l10n.overtimeStartTime,
              value: timeFormat.format(session.startAt.toLocal()),
            ),
            if (session.endAt != null)
              _MetaRow(
                label: l10n.overtimeEndTime,
                value: timeFormat.format(session.endAt!.toLocal()),
              ),
            if (session.rejectionReason != null &&
                session.rejectionReason!.trim().isNotEmpty)
              _MetaRow(
                label: l10n.overtimeRejectionReason,
                value: session.rejectionReason!.trim(),
              ),
            if (session.reviewNotes != null &&
                session.reviewNotes!.trim().isNotEmpty)
              _MetaRow(
                label: l10n.overtimeReviewNotes,
                value: session.reviewNotes!.trim(),
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
          Expanded(child: Text(value, style: theme.textTheme.bodyLarge)),
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
