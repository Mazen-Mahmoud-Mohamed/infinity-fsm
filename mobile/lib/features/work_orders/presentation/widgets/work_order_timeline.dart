import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/localization/app_formatters.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order.dart';
import 'package:mobile/features/work_orders/presentation/utils/work_order_labels.dart';

class WorkOrderTimelineSection extends StatelessWidget {
  const WorkOrderTimelineSection({
    super.key,
    required this.events,
  });

  final List<WorkOrderTimelineEvent> events;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dateFormat = AppFormatters.mediumDate(context);
    final timeFormat = AppFormatters.hm(context);
    final sorted = [...events]..sort((a, b) => a.at.compareTo(b.at));

    final l10n = AppLocalizations.of(context);
    if (sorted.isEmpty) {
      return Text(
        l10n.workOrderTimelineEmpty,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < sorted.length; i++)
          _TimelineItem(
            event: sorted[i],
            isFirst: i == 0,
            isLast: i == sorted.length - 1,
            dateLabel: dateFormat.format(sorted[i].at.toLocal()),
            timeLabel: timeFormat.format(sorted[i].at.toLocal()),
          ),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.event,
    required this.isFirst,
    required this.isLast,
    required this.dateLabel,
    required this.timeLabel,
  });

  final WorkOrderTimelineEvent event;
  final bool isFirst;
  final bool isLast;
  final String dateLabel;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final accent = _accentFor(context, event.type);
    final icon = _iconFor(event.type);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Container(
                  width: 2,
                  height: isFirst ? 6 : 10,
                  color: isFirst ? Colors.transparent : scheme.outlineVariant,
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                    border: Border.all(color: accent.withValues(alpha: 0.4)),
                  ),
                  child: Icon(icon, size: 15, color: accent),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : scheme.outlineVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: isFirst ? 0 : 2,
                bottom: AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Chip(
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                        side: BorderSide(color: accent.withValues(alpha: 0.35)),
                        backgroundColor: accent.withValues(alpha: 0.12),
                        label: Text(
                          workOrderTimelineTypeLabel(l10n, event.type),
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: accent,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                      Text(
                        '$dateLabel · $timeLabel',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.userName?.trim().isNotEmpty == true
                        ? event.userName!
                        : l10n.workOrderSystem,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  if (event.note != null && event.note!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      event.note!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(WorkOrderTimelineType type) {
    switch (type) {
      case WorkOrderTimelineType.created:
        return Icons.note_add_outlined;
      case WorkOrderTimelineType.assigned:
        return Icons.person_add_alt_1_outlined;
      case WorkOrderTimelineType.accepted:
        return Icons.thumb_up_alt_outlined;
      case WorkOrderTimelineType.rejected:
        return Icons.thumb_down_alt_outlined;
      case WorkOrderTimelineType.started:
        return Icons.play_circle_outline;
      case WorkOrderTimelineType.completed:
        return Icons.check_circle_outline;
      case WorkOrderTimelineType.cancelled:
        return Icons.cancel_outlined;
    }
  }

  Color _accentFor(BuildContext context, WorkOrderTimelineType type) {
    final scheme = Theme.of(context).colorScheme;
    final semantic = AppThemeColors.of(context);
    switch (type) {
      case WorkOrderTimelineType.created:
        return scheme.onSurfaceVariant;
      case WorkOrderTimelineType.assigned:
        return semantic.info;
      case WorkOrderTimelineType.accepted:
        return semantic.success;
      case WorkOrderTimelineType.rejected:
        return scheme.error;
      case WorkOrderTimelineType.started:
        return semantic.warning;
      case WorkOrderTimelineType.completed:
        return semantic.success;
      case WorkOrderTimelineType.cancelled:
        return scheme.onSurfaceVariant;
    }
  }
}
