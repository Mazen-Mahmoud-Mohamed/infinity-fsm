import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/localization/app_formatters.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/constants/app_breakpoints.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_app_message.dart';
import 'package:mobile/core/localization/localize_rbac.dart';
import 'package:mobile/core/widgets/app_cached_network_image.dart';
import 'package:mobile/core/widgets/app_loader.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_session.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_status.dart';
import 'package:mobile/features/overtime/domain/entities/overtime_type.dart';
import 'package:mobile/features/overtime/presentation/cubit/overtime_detail_cubit.dart';
import 'package:mobile/features/overtime/presentation/utils/approved_hours_hhmm.dart';
import 'package:mobile/features/overtime/presentation/utils/overtime_formatters.dart';
import 'package:mobile/features/overtime/presentation/utils/overtime_labels.dart';
import 'package:mobile/features/overtime/presentation/widgets/overtime_fullscreen_image.dart';
import 'package:mobile/features/overtime/presentation/widgets/overtime_journey_timeline.dart';
import 'package:mobile/features/overtime/presentation/widgets/overtime_location_map.dart';
import 'package:mobile/features/overtime/presentation/widgets/overtime_status_badge.dart';

class OvertimeAdminDetailPage extends StatelessWidget {
  const OvertimeAdminDetailPage({
    super.key,
    required this.sessionId,
    @visibleForTesting this.detailCubit,
  });

  final String sessionId;
  final OvertimeDetailCubit? detailCubit;

  @override
  Widget build(BuildContext context) {
    const view = _OvertimeDetailView();
    final cubit = detailCubit;
    if (cubit != null) {
      return BlocProvider<OvertimeDetailCubit>.value(
        value: cubit,
        child: view,
      );
    }
    return BlocProvider(
      create: (_) => getIt<OvertimeDetailCubit>(param1: sessionId)..load(),
      child: view,
    );
  }
}

class _OvertimeDetailView extends StatefulWidget {
  const _OvertimeDetailView();

  @override
  State<_OvertimeDetailView> createState() => _OvertimeDetailViewState();
}

class _OvertimeDetailViewState extends State<_OvertimeDetailView> {
  final OvertimeJourneyFocus _journeyFocus = OvertimeJourneyFocus();

  @override
  void dispose() {
    _journeyFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dateFormat = AppFormatters.mediumDateTime(context);
    final permissions =
        context.watch<AuthCubit>().state.user?.permissionChecker;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.overtimeDetails)),
      body: BlocConsumer<OvertimeDetailCubit, OvertimeDetailState>(
        listenWhen: (previous, current) =>
            previous.message != current.message && current.message != null,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(localizeAppMessage(l10n, state.message)),
              ),
            );
          context.read<OvertimeDetailCubit>().clearFeedback();
        },
        builder: (context, state) {
          if (state.status == OvertimeDetailStatus.loading ||
              state.session == null &&
                  state.status != OvertimeDetailStatus.failure) {
            return AppLoader(message: l10n.overtimeDetailsLoading);
          }

          if (state.status == OvertimeDetailStatus.failure ||
              state.session == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      state.message != null
                          ? localizeAppMessage(l10n, state.message)
                          : l10n.overtimeDetailsLoadFailed,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ElevatedButton(
                      onPressed: () =>
                          context.read<OvertimeDetailCubit>().load(),
                      child: Text(l10n.retry),
                    ),                  ],
                ),
              ),
            );
          }

          final session = state.session!;
          final canApprove = permissions?.canApproveOvertime() == true &&
              session.isPendingReview;
          final canReject = permissions?.canRejectOvertime() == true &&
              session.isPendingReview;

          final showReviewActions = canApprove || canReject;
          final isPhone = AppBreakpoints.isPhoneOf(context);
          final pinActionsToViewport = showReviewActions && !isPhone;
          final isDesktop = AppBreakpoints.isDesktopOf(context);
          final reviewActions = showReviewActions
              ? _OvertimeReviewActions(
                  canApprove: canApprove,
                  canReject: canReject,
                  isBusy: state.isBusy,
                  isApproving: state.isApproving,
                  isApprovingPartial: state.isApprovingPartial,
                  isRejecting: state.isRejecting,
                  onApprove: () => _showApproveDialog(context),
                  onApprovePartial: () => _showApprovePartialDialog(context),
                  onReject: () => _showRejectDialog(context),
                )
              : null;

          final technicianCard = _SectionCard(
            title: l10n.overtimeTechnicianInfo,
            dense: isDesktop,
            fillHeight: isDesktop,
            children: [
              _DetailRow(
                label: l10n.labelName,
                value: session.technician?.displayName ?? '-',
                dense: isDesktop,
              ),
              _DetailRow(
                label: l10n.email,
                value: session.technician?.email ?? '-',
                dense: isDesktop,
              ),
              _DetailRow(
                label: l10n.roleLabel,
                value: localizeRoleLabel(
                  l10n,
                  session.technician?.primaryRole,
                ),
                dense: isDesktop,
              ),
            ],
          );

          final sessionFields = <(String, String)>[
            (l10n.labelType, overtimeTypeLabel(l10n, session.type)),
            if (session.type == OvertimeType.travel && session.isOvernight)
              ('', l10n.overtimeOvernightShort),
            (
              l10n.overtimeStartTime,
              dateFormat.format(session.startAt.toLocal()),
            ),
            (
              l10n.overtimeEndTime,
              session.endAt == null
                  ? '-'
                  : dateFormat.format(session.endAt!.toLocal()),
            ),
            (
              l10n.overtimeTotalDuration,
              OvertimeFormatters.durationFromMinutes(
                session.totalDurationMinutes,
                l10n,
              ),
            ),
            (
              l10n.overtimeWorkingDuration,
              OvertimeFormatters.durationFromMinutes(
                session.workingDurationMinutes,
                l10n,
              ),
            ),
            (
              l10n.overtimeEligible,
              OvertimeFormatters.durationFromMinutes(
                session.eligibleOvertimeMinutes,
                l10n,
              ),
            ),
            if (session.status == OvertimeStatus.approved)
              (
                l10n.overtimeApprovedHours,
                OvertimeFormatters.hoursValue(
                  session.effectiveApprovedHours,
                  l10n,
                ),
              ),
            if (session.rejectionReason != null &&
                session.rejectionReason!.isNotEmpty)
              (l10n.overtimeRejectionReason, session.rejectionReason!),
            if (session.reviewNotes != null && session.reviewNotes!.isNotEmpty)
              (l10n.overtimeReviewNotes, session.reviewNotes!),
            if (session.approvedBy != null)
              (l10n.overtimeApprovedBy, session.approvedBy!.displayName),
            if (session.approvedAt != null)
              (
                l10n.overtimeApprovedAt,
                dateFormat.format(session.approvedAt!.toLocal()),
              ),
            if (session.rejectedBy != null)
              (l10n.overtimeRejectedBy, session.rejectedBy!.displayName),
            if (session.rejectedAt != null)
              (
                l10n.overtimeRejectedAt,
                dateFormat.format(session.rejectedAt!.toLocal()),
              ),
          ];

          final sessionCard = _SectionCard(
            title: l10n.overtimeSessionInfo,
            dense: isDesktop,
            fillHeight: isDesktop,
            trailing: OvertimeStatusBadge(status: session.status),
            children: [
              if (isDesktop)
                _DesktopSessionFieldsGrid(fields: sessionFields)
              else
                for (final field in sessionFields)
                  _DetailRow(
                    label: field.$1,
                    value: field.$2,
                  ),
            ],
          );

          final timelineSection = _SectionCard(
            title: l10n.overtimeJourneyTimeline,
            children: [
              OvertimeJourneyProgressStrip(session: session),
              const SizedBox(height: AppSpacing.md),
              OvertimeJourneyTimeline(
                session: session,
                // Desktop places Journey Overview as its own full-width section.
                includeJourneyOverview: !isDesktop,
                focus: isDesktop ? _journeyFocus : null,
                desktopCompactPhotos: isDesktop,
              ),
            ],
          );

          final legacySections = <Widget>[
            if (!session.isV2Workflow) ...[
              const SizedBox(height: AppSpacing.lg),
              OvertimeLocationSection(
                startGps: session.startGps,
                endGps: session.endGps,
                startAddress: session.startAddress,
                endAddress: session.endAddress,
              ),
              const SizedBox(height: AppSpacing.lg),
              _SectionCard(
                title: l10n.overtimeImages,
                children: [
                  _ResponsivePhotoGrid(
                    items: [
                      _PhotoGridItem(
                        label: l10n.overtimeStartPhoto,
                        imageUrl: session.startPhotoUrl,
                      ),
                      _PhotoGridItem(
                        label: l10n.overtimeEndPhoto,
                        imageUrl: session.endPhotoUrl,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _SectionCard(
                title: l10n.overtimeDeviceInfo,
                children: [
                  _DetailRow(
                    label: l10n.overtimeStartDevice,
                    value: session.startDeviceId,
                  ),
                  _DetailRow(
                    label: l10n.overtimeEndDevice,
                    value: session.endDeviceId ?? '-',
                  ),
                ],
              ),
            ],
          ];

          return Column(
            children: [
              Expanded(
                child: AppBottomSafeListView(
                  basePadding: EdgeInsets.all(
                    isDesktop ? AppSpacing.xl : AppSpacing.lg,
                  ),
                  chrome: pinActionsToViewport
                      ? AppBottomChrome.stickyActions
                      : AppBottomChrome.system,
                  children: [
                    if (isDesktop) ...[
                      if (session.requiresManualReview) ...[
                        _ManualReviewBanner(
                          reason: session.reviewReason,
                          totalDurationMinutes: session.totalDurationMinutes,
                          l10n: l10n,
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      _DesktopOvertimeDetailLayout(
                        technicianCard: technicianCard,
                        sessionCard: sessionCard,
                        timelineSection: timelineSection,
                        overviewSection: OvertimeJourneyOverview(
                          session: session,
                          mapHeight: OvertimeJourneyOverview.desktopMapHeight,
                          topSpacing: AppSpacing.lg,
                          focus: _journeyFocus,
                        ),
                      ),
                      ...legacySections,
                    ] else ...[
                      if (session.requiresManualReview) ...[
                        _ManualReviewBanner(
                          reason: session.reviewReason,
                          totalDurationMinutes: session.totalDurationMinutes,
                          l10n: l10n,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      technicianCard,
                      const SizedBox(height: AppSpacing.lg),
                      sessionCard,
                      const SizedBox(height: AppSpacing.lg),
                      timelineSection,
                      ...legacySections,
                    ],
                    if (reviewActions != null && !pinActionsToViewport) ...[
                      const SizedBox(height: AppSpacing.lg),
                      reviewActions,
                    ],
                  ],
                ),
              ),
              if (pinActionsToViewport)
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    child: reviewActions!,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showApproveDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final session = context.read<OvertimeDetailCubit>().state.session;
    final notesController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.approve),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (session != null) ...[
                Text(
                  '${l10n.overtimeWorkedHours}: '
                  '${OvertimeFormatters.hoursValue(session.workedHours, l10n)}',
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              TextField(
                controller: notesController,
                maxLines: 3,
                maxLength: 2000,
                decoration: InputDecoration(
                  labelText: l10n.overtimeReviewNotes,
                  hintText: l10n.overtimeReviewNotesHint,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.approve),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final notes = notesController.text.trim();
    // Full approval — omit approvedHours so backend sets worked hours.
    await context.read<OvertimeDetailCubit>().approve(
          reviewNotes: notes.isEmpty ? null : notes,
        );
  }

  Future<void> _showApprovePartialDialog(BuildContext context) async {
    final cubit = context.read<OvertimeDetailCubit>();
    final session = cubit.state.session;
    if (session == null) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _PartialApproveDialog(
          cubit: cubit,
          session: session,
        );
      },
    );
  }

  Future<void> _showRejectDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    final notesController = TextEditingController();
    final reason = await showDialog<String?>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.overtimeRejectDialogTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                maxLines: 3,
                maxLength: 1000,
                decoration: InputDecoration(
                  hintText: l10n.overtimeRejectReasonHint,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: notesController,
                maxLines: 2,
                maxLength: 2000,
                decoration: InputDecoration(
                  labelText: l10n.overtimeReviewNotes,
                  hintText: l10n.overtimeReviewNotesHint,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: Text(l10n.workOrderReject),
            ),
          ],
        );
      },
    );

    if (reason == null || !context.mounted) {
      return;
    }

    final notes = notesController.text.trim();
    await context.read<OvertimeDetailCubit>().reject(
          rejectionReason: reason.isEmpty ? null : reason,
          reviewNotes: notes.isEmpty ? null : notes,
        );
  }
}

const overtimeAdminReviewActionsKey = Key('overtimeAdminReviewActions');

@visibleForTesting
const overtimeAdminDesktopDetailLayoutKey =
    Key('overtimeAdminDesktopDetailLayout');

/// Flex pair for the desktop top row: Technician | Session ≈ 35% / 65%.
@visibleForTesting
({int startFlex, int endFlex}) overtimeDesktopDetailColumnFlex(double width) {
  // 7:13 = 35%:65% at every desktop width.
  return (startFlex: 7, endFlex: 13);
}

class _OvertimeReviewActions extends StatelessWidget {
  const _OvertimeReviewActions({
    required this.canApprove,
    required this.canReject,
    required this.isBusy,
    required this.isApproving,
    required this.isApprovingPartial,
    required this.isRejecting,
    required this.onApprove,
    required this.onApprovePartial,
    required this.onReject,
  }) : super(key: overtimeAdminReviewActionsKey);

  final bool canApprove;
  final bool canReject;
  final bool isBusy;
  final bool isApproving;
  final bool isApprovingPartial;
  final bool isRejecting;
  final VoidCallback onApprove;
  final VoidCallback onApprovePartial;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 520;
        final rejectBtn = canReject
            ? OutlinedButton(
                onPressed: isBusy ? null : onReject,
                child: isRejecting
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      )
                    : Text(l10n.workOrderReject),
              )
            : null;
        final partialBtn = canApprove
            ? OutlinedButton(
                onPressed: isBusy ? null : onApprovePartial,
                child: isApprovingPartial
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      )
                    : Text(l10n.overtimeApprovePartial),
              )
            : null;
        final approveBtn = canApprove
            ? ElevatedButton(
                onPressed: isBusy ? null : onApprove,
                child: isApproving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Text(l10n.approve),
              )
            : null;

        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              approveBtn ?? const SizedBox.shrink(),
              if (partialBtn != null) ...[
                const SizedBox(height: AppSpacing.sm),
                partialBtn,
              ],
              if (rejectBtn != null) ...[
                const SizedBox(height: AppSpacing.sm),
                rejectBtn,
              ],
            ],
          );
        }

        return Row(
          children: [
            if (rejectBtn != null) Expanded(child: rejectBtn),
            if (rejectBtn != null &&
                (partialBtn != null || approveBtn != null))
              const SizedBox(width: AppSpacing.sm),
            if (partialBtn != null) Expanded(child: partialBtn),
            if (partialBtn != null && approveBtn != null)
              const SizedBox(width: AppSpacing.sm),
            if (approveBtn != null) Expanded(child: approveBtn),
          ],
        );
      },
    );
  }
}

/// Partial Approve dialog with safe lifecycle.
///
/// Awaits [OvertimeDetailCubit.approvePartial] and only then pops — never from
/// a [BlocListener] during `emit`, which caused `_dependents.isEmpty`.
class _PartialApproveDialog extends StatefulWidget {
  const _PartialApproveDialog({
    required this.cubit,
    required this.session,
  });

  final OvertimeDetailCubit cubit;
  final OvertimeSession session;

  @override
  State<_PartialApproveDialog> createState() => _PartialApproveDialogState();
}

class _PartialApproveDialogState extends State<_PartialApproveDialog> {
  late final TextEditingController _hoursController;
  final _formKey = GlobalKey<FormState>();
  var _submitting = false;

  OvertimeSession get _session => widget.session;
  int get _workedMinutes => _session.eligibleOvertimeMinutes ?? 0;

  @override
  void initState() {
    super.initState();
    _hoursController = TextEditingController(
      text: ApprovedHoursHhMm.formatFromMinutes(_workedMinutes),
    );
  }

  @override
  void dispose() {
    _hoursController.dispose();
    super.dispose();
  }

  Future<void> _onConfirm() async {
    if (_submitting) return;
    if (_formKey.currentState?.validate() != true) return;

    final parsed = ApprovedHoursHhMm.parseAndValidateAgainstWorked(
      raw: _hoursController.text,
      workedMinutes: _workedMinutes,
    );
    final apiHours = parsed.apiHours;
    if (apiHours == null) return;

    setState(() => _submitting = true);

    await widget.cubit.approvePartial(approvedHours: apiHours);

    if (!mounted) return;

    if (widget.cubit.state.isError) {
      setState(() => _submitting = false);
      return;
    }

    // Pop only after the cubit emit + notifyListeners cycle has finished.
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final submitting = _submitting || widget.cubit.state.isApprovingPartial;

    return AlertDialog(
      title: Text(l10n.overtimeApprovePartialTitle),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${l10n.overtimeWorkedHours}: '
              '${OvertimeFormatters.hoursValue(_session.workedHours, l10n)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _hoursController,
              enabled: !submitting,
              keyboardType: TextInputType.datetime,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9:]')),
              ],
              decoration: InputDecoration(
                labelText: l10n.overtimeApprovedHours,
                hintText: l10n.overtimeApprovedHoursHint,
                helperText: l10n.overtimeApprovedHoursHelper,
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                final parsed =
                    ApprovedHoursHhMm.parseAndValidateAgainstWorked(
                  raw: value,
                  workedMinutes: _workedMinutes,
                );
                if (!parsed.isValid) {
                  return l10n.overtimeApprovedHoursInvalid;
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: submitting ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: submitting ? null : _onConfirm,
          child: submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.approve),
        ),
      ],
    );
  }
}

class _ManualReviewBanner extends StatelessWidget {
  const _ManualReviewBanner({
    required this.reason,
    required this.totalDurationMinutes,
    required this.l10n,
  });

  final String? reason;
  final int? totalDurationMinutes;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: colorScheme.onErrorContainer),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.overtimeRequiresManualReview,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (reason != null && reason!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    reason!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onErrorContainer,
                    ),
                  ),
                ],
                if (totalDurationMinutes != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    OvertimeFormatters.durationFromMinutes(
                      totalDurationMinutes,
                      l10n,
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onErrorContainer,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
    this.trailing,
    this.dense = false,
    this.fillHeight = false,
  });

  final String title;
  final List<Widget> children;
  final Widget? trailing;
  final bool dense;
  final bool fillHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = dense ? AppSpacing.sm + 4 : AppSpacing.md;
    final titleStyle = dense
        ? theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)
        : theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700);
    return Container(
      width: double.infinity,
      height: fillHeight ? double.infinity : null,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: titleStyle,
                ),
              ),
              trailing ?? const SizedBox.shrink(),
            ],
          ),
          SizedBox(height: dense ? AppSpacing.sm : AppSpacing.md),
          ...children,
        ],
      ),
    );
  }
}

/// Desktop session fields in a compact 2-column grid (uses the 65% width).
class _DesktopSessionFieldsGrid extends StatelessWidget {
  const _DesktopSessionFieldsGrid({required this.fields});

  final List<(String, String)> fields;

  @override
  Widget build(BuildContext context) {
    if (fields.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        for (var i = 0; i < fields.length; i += 2)
          Padding(
            padding: EdgeInsets.only(
              bottom: i + 2 < fields.length ? AppSpacing.sm : 0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _CompactSessionField(
                    label: fields[i].$1,
                    value: fields[i].$2,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: i + 1 < fields.length
                      ? _CompactSessionField(
                          label: fields[i + 1].$1,
                          value: fields[i + 1].$2,
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _CompactSessionField extends StatelessWidget {
  const _CompactSessionField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        if (label.isNotEmpty) const SizedBox(height: 2),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          softWrap: true,
          textDirection: value.contains('@') ? TextDirection.ltr : null,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.dense = false,
  });

  final String label;
  final String value;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: dense ? AppSpacing.xs : AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: dense ? 108 : 130,
            child: Text(
              label,
              style: (dense
                      ? theme.textTheme.bodySmall
                      : theme.textTheme.bodyMedium)
                  ?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: dense
                  ? theme.textTheme.bodyMedium
                  : theme.textTheme.bodyLarge,
              softWrap: true,
              textDirection: value.contains('@') ? TextDirection.ltr : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoGridItem {
  const _PhotoGridItem({required this.label, required this.imageUrl});

  final String label;
  final String? imageUrl;
}

class _ResponsivePhotoGrid extends StatelessWidget {
  const _ResponsivePhotoGrid({required this.items});

  final List<_PhotoGridItem> items;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width >= AppBreakpoints.tabletMax
        ? 2
        : width >= AppBreakpoints.phoneMax
            ? 2
            : 1;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 4 / 3,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return _PhotoTile(label: item.label, imageUrl: item.imageUrl);
      },
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.label, required this.imageUrl});

  final String label;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: !hasImage
              ? Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    l10n.overtimeNoPhotoAvailable,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : GestureDetector(
                  onTap: () => openOvertimeFullscreenImage(
                    context,
                    imageUrl: imageUrl!,
                    title: label,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: AppCachedNetworkImage(
                      imageUrl: imageUrl!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

/// Desktop Overtime Details composition:
/// 1) Top row: Technician (~35%) | Session (~65%)
/// 2) Full-width Journey Timeline
/// 3) Full-width Journey Overview / map
class _DesktopOvertimeDetailLayout extends StatelessWidget {
  const _DesktopOvertimeDetailLayout({
    required this.technicianCard,
    required this.sessionCard,
    required this.timelineSection,
    required this.overviewSection,
  });

  final Widget technicianCard;
  final Widget sessionCard;
  final Widget timelineSection;
  final Widget overviewSection;

  @override
  Widget build(BuildContext context) {
    final flex = overtimeDesktopDetailColumnFlex(
      MediaQuery.sizeOf(context).width,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        IntrinsicHeight(
          child: Row(
            key: overtimeAdminDesktopDetailLayoutKey,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: flex.startFlex,
                child: technicianCard,
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                flex: flex.endFlex,
                child: sessionCard,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        timelineSection,
        overviewSection,
      ],
    );
  }
}
