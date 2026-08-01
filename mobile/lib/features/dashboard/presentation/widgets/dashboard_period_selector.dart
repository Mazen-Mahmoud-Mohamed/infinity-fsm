import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/features/dashboard/domain/entities/role_dashboard_summary.dart';
import 'package:mobile/features/dashboard/presentation/utils/dashboard_period_range.dart';

class DashboardPeriodSelector extends StatelessWidget {
  const DashboardPeriodSelector({
    super.key,
    required this.period,
    required this.onPeriodSelected,
    required this.onCustomRangeSelected,
    this.customFrom,
    this.customTo,
    this.rangeFrom,
    this.rangeTo,
  });

  final DashboardPeriod period;
  final ValueChanged<DashboardPeriod> onPeriodSelected;
  final void Function(DateTime from, DateTime to) onCustomRangeSelected;
  final DateTime? customFrom;
  final DateTime? customTo;

  /// Server-resolved range when available; otherwise local calendar bounds.
  final DateTime? rangeFrom;
  final DateTime? rangeTo;

  Future<void> _pickCustomRange(BuildContext context) async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: DateTimeRange(
        start: customFrom ?? DateTime(now.year, now.month, 1),
        end: customTo ?? now,
      ),
    );
    if (range == null) return;
    onCustomRangeSelected(range.start, range.end);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final chips = <({DashboardPeriod? period, String label, bool custom})>[
      (period: DashboardPeriod.today, label: l10n.dashboardPeriodToday, custom: false),
      (period: DashboardPeriod.week, label: l10n.dashboardPeriodWeek, custom: false),
      (period: DashboardPeriod.month, label: l10n.dashboardPeriodMonth, custom: false),
      (period: DashboardPeriod.year, label: l10n.dashboardPeriodYear, custom: false),
      (period: null, label: l10n.dashboardPeriodCustom, custom: true),
    ];

    final local = DashboardPeriodRange.resolveLocal(
      period: period,
      customFrom: customFrom,
      customTo: customTo,
    );
    final from = rangeFrom ?? local.from;
    final to = rangeTo ?? local.to;
    final reportLine = DashboardPeriodRange.formatReportLine(
      context: context,
      period: period,
      from: from,
      to: to,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < chips.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.sm),
                ChoiceChip(
                  label: Text(chips[i].label),
                  selected: chips[i].custom
                      ? period == DashboardPeriod.custom
                      : period == chips[i].period,
                  onSelected: (_) {
                    if (chips[i].custom) {
                      _pickCustomRange(context);
                    } else {
                      onPeriodSelected(chips[i].period!);
                    }
                  },
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          reportLine,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
