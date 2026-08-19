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

          final leftSections = <Widget>[
            if (session.requiresManualReview) ...[
              _ManualReviewBanner(
                reason: session.reviewReason,
                totalDurationMinutes: session.totalDurationMinutes,
                l10n: l10n,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            _SectionCard(
              title: l10n.overtimeTechnicianInfo,
              children: [
                _DetailRow(
                  label: l10n.labelName,
                  value: session.technician?.displayName ?? '-',
                ),
                _DetailRow(
                  label: l10n.email,
                  value: session.technician?.email ?? '-',
                ),
                _DetailRow(
                  label: l10n.roleLabel,
                  value: localizeRoleLabel(
                    l10n,
                    session.technician?.primaryRole,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _SectionCard(
              title: l10n.overtimeSessionInfo,
              trailing: OvertimeStatusBadge(status: session.status),
              children: [
                _DetailRow(
                  label: l10n.labelType,
                  value: overtimeTypeLabel(l10n, session.type),
                ),
                if (session.type == OvertimeType.travel && session.isOvernight)
                  _DetailRow(
                    // Show only the overnight word with no "yes/no" label.
                    label: '',
                    value: l10n.overtimeOvernightShort,
                  ),
                _DetailRow(
                  label: l10n.overtimeStartTime,
                  value: dateFormat.format(session.startAt.toLocal()),
                ),
                _DetailRow(
                  label: l10n.overtimeEndTime,
                  value: session.endAt == null
                      ? '-'
                      : dateFormat.format(session.endAt!.toLocal()),
                ),
                _DetailRow(
                  label: l10n.overtimeTotalDuration,
                  value: OvertimeFormatters.durationFromMinutes(
                    session.totalDurationMinutes,
                    l10n,
                  ),
                ),
                _DetailRow(
                  label: l10n.overtimeWorkingDuration,
                  value: OvertimeFormatters.durationFromMinutes(
                    session.workingDurationMinutes,
                    l10n,
                  ),
                ),
                _DetailRow(
                  label: l10n.overtimeEligible,
                  value: OvertimeFormatters.durationFromMinutes(
                    session.eligibleOvertimeMinutes,
                    l10n,
                  ),
                ),
                if (session.status == OvertimeStatus.approved)
                  _DetailRow(
                    label: l10n.overtimeApprovedHours,
                    value: OvertimeFormatters.hoursValue(
                      session.effectiveApprovedHours,
                      l10n,
                    ),
                  ),
                if (session.rejectionReason != null &&
                    session.rejectionReason!.isNotEmpty)
                  _DetailRow(
                    label: l10n.overtimeRejectionReason,
                    value: session.rejectionReason!,
                  ),
                if (session.reviewNotes != null &&
                    session.reviewNotes!.isNotEmpty)
                  _DetailRow(
                    label: l10n.overtimeReviewNotes,
                    value: session.reviewNotes!,
                  ),
                if (session.approvedBy != null)
                  _DetailRow(
                    label: l10n.overtimeApprovedBy,
                    value: session.approvedBy!.displayName,
                  ),
                if (session.approvedAt != null)
                  _DetailRow(
                    label: l10n.overtimeApprovedAt,
                    value: dateFormat.format(session.approvedAt!.toLocal()),
                  ),
                if (session.rejectedBy != null)
                  _DetailRow(
                    label: l10n.overtimeRejectedBy,
                    value: session.rejectedBy!.displayName,
                  ),
                if (session.rejectedAt != null)
                  _DetailRow(
                    label: l10n.overtimeRejectedAt,
                    value: dateFormat.format(session.rejectedAt!.toLocal()),
                  ),
              ],
            ),
          ];

          final rightSections = <Widget>[
            _SectionCard(
              title: l10n.overtimeJourneyTimeline,
              children: [
                OvertimeJourneyProgressStrip(session: session),
                const SizedBox(height: AppSpacing.md),
                OvertimeJourneyTimeline(
                  session: session,
                  // Desktop places Journey Overview full-width below the split.
                  includeJourneyOverview: !isDesktop,
                  focus: isDesktop ? _journeyFocus : null,
                  desktopCompactPhotos: isDesktop,
                ),
              ],
            ),
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
                    if (isDesktop)
                      _DesktopOvertimeDetailLayout(
                        start: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: leftSections,
                        ),
                        end: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: rightSections,
                        ),
                        footer: OvertimeJourneyOverview(
                          session: session,
                          mapHeight: OvertimeJourneyOverview.desktopMapHeight,
                          topSpacing: 14,
                          focus: _journeyFocus,
                        ),
                      )
                    else ...[
                      ...leftSections,
                      const SizedBox(height: AppSpacing.lg),
                      ...rightSections,
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
  });

  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
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
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              trailing ?? const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

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
            width: 130,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyLarge,
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

/// Desktop-only shell: shrink-wraps the two-column row to the left column
/// height (timeline scrolls internally), then places [footer] immediately
/// below with no empty Expanded whitespace.
class _DesktopOvertimeDetailLayout extends StatefulWidget {
  const _DesktopOvertimeDetailLayout({
    required this.start,
    required this.end,
    required this.footer,
  });

  final Widget start;
  final Widget end;
  final Widget footer;

  @override
  State<_DesktopOvertimeDetailLayout> createState() =>
      _DesktopOvertimeDetailLayoutState();
}

class _DesktopOvertimeDetailLayoutState
    extends State<_DesktopOvertimeDetailLayout> {
  final GlobalKey _startKey = GlobalKey();
  double? _startHeight;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureStart());
  }

  @override
  void didUpdateWidget(covariant _DesktopOvertimeDetailLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureStart());
  }

  void _measureStart() {
    final box = _startKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      return;
    }
    final height = box.size.height;
    if (_startHeight != null && (height - _startHeight!).abs() < 0.5) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() => _startHeight = height);
  }

  @override
  Widget build(BuildContext context) {
    final timelineMaxHeight = _startHeight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: KeyedSubtree(
                key: _startKey,
                child: widget.start,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              flex: 2,
              child: timelineMaxHeight == null
                  ? widget.end
                  : SizedBox(
                      height: timelineMaxHeight,
                      child: SingleChildScrollView(
                        primary: false,
                        child: widget.end,
                      ),
                    ),
            ),
          ],
        ),
        widget.footer,
      ],
    );
  }
}
