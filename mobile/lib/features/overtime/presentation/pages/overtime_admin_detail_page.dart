import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/localization/app_formatters.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/constants/app_breakpoints.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_app_message.dart';
import 'package:mobile/core/widgets/app_cached_network_image.dart';
import 'package:mobile/core/widgets/app_loader.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_split_view.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/features/overtime/presentation/cubit/overtime_detail_cubit.dart';
import 'package:mobile/features/overtime/presentation/utils/overtime_formatters.dart';
import 'package:mobile/features/overtime/presentation/utils/overtime_labels.dart';
import 'package:mobile/features/overtime/presentation/widgets/overtime_fullscreen_image.dart';
import 'package:mobile/features/overtime/presentation/widgets/overtime_location_map.dart';
import 'package:mobile/features/overtime/presentation/widgets/overtime_status_badge.dart';

class OvertimeAdminDetailPage extends StatelessWidget {
  const OvertimeAdminDetailPage({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<OvertimeDetailCubit>(param1: sessionId)..load(),
      child: const _OvertimeDetailView(),
    );
  }
}

class _OvertimeDetailView extends StatelessWidget {
  const _OvertimeDetailView();

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
                backgroundColor: state.isError
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.inverseSurface,
                behavior: SnackBarBehavior.floating,
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

          final showStickyActions = canApprove || canReject;
          final isDesktop = AppBreakpoints.isDesktopOf(context);

          final leftSections = <Widget>[
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
                  value: session.technician?.primaryRole ?? '-',
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
                  label: l10n.overtimeEligible,
                  value: OvertimeFormatters.durationFromMinutes(
                    session.eligibleOvertimeMinutes,
                    l10n,
                  ),
                ),
                if (session.rejectionReason != null &&
                    session.rejectionReason!.isNotEmpty)
                  _DetailRow(
                    label: l10n.overtimeRejectionReason,
                    value: session.rejectionReason!,
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
          ];

          return Column(
            children: [
              Expanded(
                child: AppBottomSafeListView(
                  basePadding: EdgeInsets.all(
                    isDesktop ? AppSpacing.xl : AppSpacing.lg,
                  ),
                  chrome: showStickyActions
                      ? AppBottomChrome.stickyActions
                      : AppBottomChrome.system,
                  children: [
                    if (isDesktop)
                      AppDesktopSplitView(
                        start: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: leftSections,
                        ),
                        end: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: rightSections,
                        ),
                      )
                    else
                      ...leftSections,
                    if (!isDesktop) ...[
                      const SizedBox(height: AppSpacing.lg),
                      ...rightSections,
                    ],
                  ],
                ),
              ),
              if (showStickyActions)
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    child: Row(
                      children: [
                        if (canReject)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: state.isBusy
                                  ? null
                                  : () => _showRejectDialog(context),
                              child: state.isRejecting
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                    )
                                  : Text(l10n.workOrderReject),
                            ),
                          ),
                        if (canReject && canApprove)
                          const SizedBox(width: AppSpacing.md),
                        if (canApprove)
                          Expanded(
                            child: ElevatedButton(
                              onPressed: state.isBusy
                                  ? null
                                  : () => context
                                      .read<OvertimeDetailCubit>()
                                      .approve(),
                              child: state.isApproving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(l10n.approve),
                            ),
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

  Future<void> _showRejectDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    final reason = await showDialog<String?>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.overtimeRejectDialogTitle),
          content: TextField(
            controller: controller,
            maxLines: 3,
            maxLength: 1000,
            decoration: InputDecoration(
              hintText: l10n.overtimeRejectReasonHint,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.usersCancel),
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

    await context.read<OvertimeDetailCubit>().reject(
          rejectionReason: reason.isEmpty ? null : reason,
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
              if (trailing != null) trailing!,
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
            child: Text(value, style: theme.textTheme.bodyLarge),
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
