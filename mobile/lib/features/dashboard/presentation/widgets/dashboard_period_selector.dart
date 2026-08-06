import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_breakpoints.dart';
import 'package:mobile/core/constants/app_radius.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/app_formatters.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/features/dashboard/domain/entities/role_dashboard_summary.dart';
import 'package:mobile/features/dashboard/presentation/utils/dashboard_period_range.dart';

/// Period chips + optional custom From / To / Apply panel (presentation only).
class DashboardPeriodSelector extends StatefulWidget {
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

  @override
  State<DashboardPeriodSelector> createState() =>
      _DashboardPeriodSelectorState();
}

class _DashboardPeriodSelectorState extends State<DashboardPeriodSelector> {
  bool _showCustomPanel = false;
  DateTime? _draftFrom;
  DateTime? _draftTo;

  @override
  void initState() {
    super.initState();
    _syncDraftFromWidget();
    _showCustomPanel = widget.period == DashboardPeriod.custom;
  }

  @override
  void didUpdateWidget(covariant DashboardPeriodSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.period != widget.period ||
        oldWidget.customFrom != widget.customFrom ||
        oldWidget.customTo != widget.customTo) {
      _syncDraftFromWidget();
      if (widget.period != DashboardPeriod.custom) {
        _showCustomPanel = false;
      } else {
        _showCustomPanel = true;
      }
    }
  }

  void _syncDraftFromWidget() {
    final now = DateTime.now();
    _draftFrom = widget.customFrom ??
        widget.rangeFrom ??
        DateTime(now.year, now.month, 1);
    _draftTo = widget.customTo ?? widget.rangeTo ?? now;
  }

  Future<void> _pickFrom(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _draftFrom ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: _draftTo ?? DateTime(now.year + 1, 12, 31),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _draftFrom = DateTime(picked.year, picked.month, picked.day);
      if (_draftTo != null && _draftTo!.isBefore(_draftFrom!)) {
        _draftTo = _draftFrom;
      }
    });
  }

  Future<void> _pickTo(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _draftTo ?? now,
      firstDate: _draftFrom ?? DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _draftTo = DateTime(picked.year, picked.month, picked.day);
    });
  }

  void _onPresetSelected(DashboardPeriod period) {
    setState(() => _showCustomPanel = false);
    widget.onPeriodSelected(period);
  }

  void _onCustomChipSelected() {
    setState(() {
      _showCustomPanel = true;
      _syncDraftFromWidget();
    });
  }

  void _applyCustom() {
    final from = _draftFrom;
    final to = _draftTo;
    if (from == null || to == null) return;
    if (to.isBefore(from)) return;
    widget.onCustomRangeSelected(from, to);
  }

  String _formatDate(BuildContext context, DateTime? value) {
    if (value == null) return '—';
    return AppFormatters.mediumDate(context).format(value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final chips = <({DashboardPeriod? period, String label, bool custom})>[
      (
        period: DashboardPeriod.today,
        label: l10n.dashboardPeriodToday,
        custom: false,
      ),
      (
        period: DashboardPeriod.week,
        label: l10n.dashboardPeriodWeek,
        custom: false,
      ),
      (
        period: DashboardPeriod.month,
        label: l10n.dashboardPeriodMonth,
        custom: false,
      ),
      (
        period: DashboardPeriod.year,
        label: l10n.dashboardPeriodYear,
        custom: false,
      ),
      (period: null, label: l10n.dashboardPeriodCustom, custom: true),
    ];

    final local = DashboardPeriodRange.resolveLocal(
      period: widget.period,
      customFrom: widget.customFrom,
      customTo: widget.customTo,
    );
    final from = widget.rangeFrom ?? local.from;
    final to = widget.rangeTo ?? local.to;
    final reportLine = DashboardPeriodRange.formatReportLine(
      context: context,
      period: widget.period,
      from: from,
      to: to,
    );

    final customSelected =
        _showCustomPanel || widget.period == DashboardPeriod.custom;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      ? customSelected
                      : !_showCustomPanel && widget.period == chips[i].period,
                  onSelected: (_) {
                    if (chips[i].custom) {
                      _onCustomChipSelected();
                    } else {
                      _onPresetSelected(chips[i].period!);
                    }
                  },
                ),
              ],
            ],
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: !_showCustomPanel
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: _CustomRangePanel(
                    fromLabel: l10n.dashboardPeriodFrom,
                    toLabel: l10n.dashboardPeriodTo,
                    applyLabel: l10n.dashboardPeriodApply,
                    fromValue: _formatDate(context, _draftFrom),
                    toValue: _formatDate(context, _draftTo),
                    onPickFrom: () => _pickFrom(context),
                    onPickTo: () => _pickTo(context),
                    onApply: _applyCustom,
                    canApply: _draftFrom != null &&
                        _draftTo != null &&
                        !_draftTo!.isBefore(_draftFrom!),
                  ),
                ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          reportLine,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _CustomRangePanel extends StatelessWidget {
  const _CustomRangePanel({
    required this.fromLabel,
    required this.toLabel,
    required this.applyLabel,
    required this.fromValue,
    required this.toValue,
    required this.onPickFrom,
    required this.onPickTo,
    required this.onApply,
    required this.canApply,
  });

  final String fromLabel;
  final String toLabel;
  final String applyLabel;
  final String fromValue;
  final String toValue;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;
  final VoidCallback onApply;
  final bool canApply;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= AppBreakpoints.phoneMax;
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: _DateFieldButton(
                      label: fromLabel,
                      value: fromValue,
                      onTap: onPickFrom,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _DateFieldButton(
                      label: toLabel,
                      value: toValue,
                      onTap: onPickTo,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  FilledButton(
                    onPressed: canApply ? onApply : null,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(120, 48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                    ),
                    child: Text(applyLabel),
                  ),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _DateFieldButton(
                        label: fromLabel,
                        value: fromValue,
                        onTap: onPickFrom,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _DateFieldButton(
                        label: toLabel,
                        value: toValue,
                        onTap: onPickTo,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: canApply ? onApply : null,
                    child: Text(applyLabel),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DateFieldButton extends StatelessWidget {
  const _DateFieldButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Material(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.7),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
