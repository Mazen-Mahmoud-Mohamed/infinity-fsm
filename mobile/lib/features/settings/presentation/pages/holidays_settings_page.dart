import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_app_message.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/features/settings/presentation/cubit/settings_cubits.dart';
import 'package:mobile/features/settings/presentation/widgets/settings_form_skeleton.dart';
import 'package:mobile/features/settings/presentation/widgets/settings_layout.dart';

class HolidaysSettingsPage extends StatefulWidget {
  const HolidaysSettingsPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<HolidaysSettingsPage> createState() => _HolidaysSettingsPageState();
}

class _HolidaysSettingsPageState extends State<HolidaysSettingsPage> {
  late final HolidaysSettingsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<HolidaysSettingsCubit>()..load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<void> _save(AppLocalizations l10n) async {
    final result = await _cubit.save();
    if (!mounted) return;
    switch (result) {
      case Success():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsSaved)),
        );
      case Failure(message: final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizeAppMessage(l10n, message)),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canManage = context.select(
      (AuthCubit c) =>
          c.state.user?.permissionChecker.canManageHolidays() == true,
    );

    return BlocProvider.value(
      value: _cubit,
      child: widget.embedded
          ? _buildBody(l10n, canManage)
          : Scaffold(
              appBar: AppBar(title: Text(l10n.settingsHolidaysTitle)),
              body: _buildBody(l10n, canManage),
            ),
    );
  }

  Widget _buildBody(AppLocalizations l10n, bool canManage) {
    return BlocBuilder<HolidaysSettingsCubit, HolidaysSettingsState>(
      builder: (context, state) {
        if ((state.status == HolidaysSettingsStatus.loading ||
                state.status == HolidaysSettingsStatus.initial) &&
            state.persistedDates.isEmpty &&
            state.selectedDates.isEmpty) {
          return SettingsFormSkeleton(
            showAvatar: false,
            fieldCount: 4,
            semanticsLabel: l10n.settingsLoading,
          );
        }
        if (state.status == HolidaysSettingsStatus.failure &&
            state.persistedDates.isEmpty &&
            state.selectedDates.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  state.message != null
                      ? localizeAppMessage(l10n, state.message)
                      : l10n.settingsLoadFailed,
                ),
                FilledButton(
                  onPressed: _cubit.load,
                  child: Text(l10n.retry),
                ),
              ],
            ),
          );
        }

        final month = state.visibleMonth ?? DateTime(DateTime.now().year, DateTime.now().month);
        final locale = Localizations.localeOf(context).toString();
        final monthLabel = DateFormat.yMMMM(locale).format(month);
        final isSaving = state.status == HolidaysSettingsStatus.saving;

        return SettingsPageBody(
          embedded: widget.embedded,
          children: [
            if (state.isRefreshing)
              const LinearProgressIndicator(minHeight: 2),
            Text(
              l10n.settingsHolidaysSubtitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          tooltip: l10n.settingsHolidaysPreviousMonth,
                          onPressed: isSaving ? null : _cubit.showPreviousMonth,
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Expanded(
                          child: Text(
                            monthLabel,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        IconButton(
                          tooltip: l10n.settingsHolidaysNextMonth,
                          onPressed: isSaving ? null : _cubit.showNextMonth,
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _GregorianMonthGrid(
                      month: month,
                      selectedDates: state.selectedDates,
                      persistedDates: state.persistedDates,
                      enabled: canManage && !isSaving,
                      onToggle: (day) => _cubit.toggleDate(day),
                      ymd: _ymd,
                      weekdayLabels: [
                        l10n.settingsHolidaysWeekdaySat,
                        l10n.settingsHolidaysWeekdaySun,
                        l10n.settingsHolidaysWeekdayMon,
                        l10n.settingsHolidaysWeekdayTue,
                        l10n.settingsHolidaysWeekdayWed,
                        l10n.settingsHolidaysWeekdayThu,
                        l10n.settingsHolidaysWeekdayFri,
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.settingsHolidaysSelectedCount(state.selectedDates.length),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (canManage) ...[
              const SizedBox(height: AppSpacing.lg),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FilledButton.icon(
                  onPressed: !state.isDirty || isSaving
                      ? null
                      : () => _save(l10n),
                  icon: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(l10n.settingsSave),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _GregorianMonthGrid extends StatelessWidget {
  const _GregorianMonthGrid({
    required this.month,
    required this.selectedDates,
    required this.persistedDates,
    required this.enabled,
    required this.onToggle,
    required this.ymd,
    required this.weekdayLabels,
  });

  final DateTime month;
  final Set<String> selectedDates;
  final Set<String> persistedDates;
  final bool enabled;
  final ValueChanged<DateTime> onToggle;
  final String Function(DateTime) ymd;
  final List<String> weekdayLabels;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final first = DateTime(month.year, month.month, 1);
    // DateTime: Mon=1 ... Sun=7. Saturday-first: (weekday + 1) % 7 → Sat=0.
    final lead = (first.weekday + 1) % 7;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final totalCells = ((lead + daysInMonth + 6) ~/ 7) * 7;

    Widget cellAt(int index) {
      if (index < 7) {
        return Center(
          child: Text(
            weekdayLabels[index],
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        );
      }
      final dayIndex = index - 7;
      if (dayIndex < lead || dayIndex >= lead + daysInMonth) {
        return const SizedBox.shrink();
      }
      final day = dayIndex - lead + 1;
      return _dayCell(
        context,
        DateTime(month.year, month.month, day),
        scheme,
      );
    }

    final rowCount = 1 + (totalCells ~/ 7);
    return Column(
      children: [
        for (var row = 0; row < rowCount; row++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                for (var col = 0; col < 7; col++)
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: cellAt(row * 7 + col),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _dayCell(BuildContext context, DateTime day, ColorScheme scheme) {
    final key = ymd(day);
    final selected = selectedDates.contains(key);
    final persisted = persistedDates.contains(key);
    final isFriday = day.weekday == DateTime.friday;

    final bg = selected
        ? scheme.primary
        : persisted
            ? scheme.primaryContainer
            : null;
    final fg = selected
        ? scheme.onPrimary
        : persisted
            ? scheme.onPrimaryContainer
            : isFriday
                ? scheme.onSurfaceVariant
                : scheme.onSurface;

    return Material(
      color: bg ?? Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? () => onToggle(day) : null,
        child: Center(
          child: Text(
            '${day.day}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: fg,
                  fontWeight: selected || persisted ? FontWeight.w600 : null,
                ),
          ),
        ),
      ),
    );
  }
}
