import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/constants/app_breakpoints.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_app_message.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/core/widgets/app_loader.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/features/overtime/domain/constants/overtime_media_config.dart';
import 'package:mobile/features/settings/domain/entities/settings_entities.dart';
import 'package:mobile/features/overtime/domain/constants/overtime_configuration_presets.dart';
import 'package:mobile/features/overtime/domain/constants/overtime_media_estimates.dart';
import 'package:mobile/features/settings/presentation/widgets/overtime_settings_config_lab.dart';
import 'package:mobile/features/settings/presentation/widgets/overtime_settings_helpers.dart';
import 'package:mobile/features/settings/presentation/cubit/settings_cubits.dart';
import 'package:mobile/features/settings/presentation/widgets/settings_layout.dart';

class OvertimeSettingsPage extends StatefulWidget {
  const OvertimeSettingsPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<OvertimeSettingsPage> createState() => _OvertimeSettingsPageState();
}

class _OvertimeSettingsPageState extends State<OvertimeSettingsPage> {
  late final OvertimeSettingsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<OvertimeSettingsCubit>()..load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canManage = context.select(
      (AuthCubit c) =>
          c.state.user?.permissionChecker.canManageSettings() == true,
    );

    return BlocProvider.value(
      value: _cubit,
      child: widget.embedded
          ? _buildBody(l10n, canManage)
          : Scaffold(
              appBar: AppBar(title: Text(l10n.settingsOvertimeTitle)),
              body: _buildBody(l10n, canManage),
            ),
    );
  }

  Widget _buildBody(AppLocalizations l10n, bool canManage) {
    return BlocBuilder<OvertimeSettingsCubit, OvertimeSettingsState>(
      builder: (context, state) {
        if (state.status == OvertimeSettingsStatus.loading &&
            state.settings == null) {
          return AppLoader(message: l10n.settingsLoading);
        }
        if (state.status == OvertimeSettingsStatus.failure &&
            state.settings == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  state.message != null
                      ? localizeAppMessage(l10n, state.message)
                      : l10n.settingsLoadFailed,
                ),
                FilledButton(onPressed: _cubit.load, child: Text(l10n.retry)),
              ],
            ),
          );
        }

        final settings = state.settings;
        final isDesktop = AppBreakpoints.isDesktopOf(context);
        final isSaving = state.status == OvertimeSettingsStatus.saving;

        final durationMinutes = OvertimeMediaConfig.minutesFromSeconds(
          settings?.voiceMaxDurationSeconds ??
              OvertimeMediaConfig.defaultMaxDurationSeconds,
        );
        final durationOptions =
            (settings?.voiceDurationOptionsSeconds ??
                    OvertimeMediaConfig.durationOptionsSeconds)
                .map(OvertimeMediaConfig.minutesFromSeconds)
                .toList();
        final quality =
            settings?.voiceRecordingQuality ??
            OvertimeMediaConfig.defaultVoiceQuality;
        final qualityOptions =
            settings?.voiceQualityOptions ??
            OvertimeMediaConfig.voiceQualityOptions;
        final maxPhotoSize =
            settings?.maxPhotoSize ?? OvertimeMediaConfig.defaultMaxPhotoSizeMb;
        final photoOptions =
            settings?.maxPhotoSizeOptions ??
            <Object>[
              ...OvertimeMediaConfig.maxPhotoSizeOptionsMb,
              OvertimeMediaConfig.maxPhotoSizeOriginal,
            ];
        final uploadPolicy =
            settings?.uploadPolicy ?? OvertimeMediaConfig.defaultUploadPolicy;
        final policyOptions =
            settings?.uploadPolicyOptions ??
            OvertimeMediaConfig.uploadPolicyOptions;

        final activePreset = state.activePresetId;

        return RefreshIndicator(
          onRefresh: _cubit.load,
          child: SettingsPageBody(
            embedded: widget.embedded,
            children: [
              if (state.isRefreshing)
                const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.sm),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              if (OvertimeMediaEstimates.shouldWarnLargeRecording(
                durationMinutes: durationMinutes,
                quality: quality,
              ))
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: MaterialBanner(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.tertiaryContainer.withValues(alpha: 0.45),
                    leading: Icon(
                      Icons.warning_amber_rounded,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                    content: Text(l10n.settingsOvertimeLargeRecordingWarning),
                    actions: const [SizedBox.shrink()],
                  ),
                ),
              SettingsCard(
                title: l10n.settingsOvertimeVoiceNotesTitle,
                subtitle: l10n.settingsOvertimeVoiceNotesSubtitle,
                leading: const Icon(Icons.mic_none_outlined),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _PresetSection(
                      l10n: l10n,
                      isDesktop: isDesktop,
                      canManage: canManage,
                      isSaving: isSaving,
                      activePreset: activePreset,
                      onPresetSelected: (preset) {
                        if (preset.id == OvertimeConfigurationPreset.customId) {
                          return;
                        }
                        _cubit.applyPreset(preset);
                      },
                    ),
                    const Divider(height: AppSpacing.xl),
                    _DurationSetting(
                      l10n: l10n,
                      isDesktop: isDesktop,
                      canManage: canManage,
                      isSaving: isSaving,
                      selectedMinutes: durationMinutes,
                      optionsMinutes: durationOptions,
                      quality: quality,
                      onSelected: _cubit.saveVoiceMaxDuration,
                    ),
                    const Divider(height: AppSpacing.xl),
                    _QualitySetting(
                      l10n: l10n,
                      isDesktop: isDesktop,
                      canManage: canManage,
                      isSaving: isSaving,
                      selected: quality,
                      options: qualityOptions,
                      durationMinutes: durationMinutes,
                      onSelected: _cubit.saveVoiceQuality,
                    ),
                    const Divider(height: AppSpacing.xl),
                    _PhotoSizeSetting(
                      l10n: l10n,
                      isDesktop: isDesktop,
                      canManage: canManage,
                      isSaving: isSaving,
                      selected: maxPhotoSize,
                      options: photoOptions,
                      onSelected: _cubit.saveMaxPhotoSize,
                    ),
                    const Divider(height: AppSpacing.xl),
                    _UploadPolicySetting(
                      l10n: l10n,
                      isDesktop: isDesktop,
                      canManage: canManage,
                      isSaving: isSaving,
                      selected: uploadPolicy,
                      options: policyOptions,
                      onSelected: _cubit.saveUploadPolicy,
                    ),
                    if (canManage) ...[
                      const Divider(height: AppSpacing.xl),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: isSaving
                              ? null
                              : () => _confirmRestoreDefaults(context, l10n),
                          icon: const Icon(Icons.restore_rounded),
                          label: Text(l10n.settingsOvertimeRestoreDefaults),
                        ),
                      ),
                    ],
                    if (!canManage) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        l10n.settingsReadOnly,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (isSaving) ...[
                      const SizedBox(height: AppSpacing.md),
                      const LinearProgressIndicator(minHeight: 2),
                    ],
                  ],
                ),
              ),
              if (canManage) ...[
                const SizedBox(height: AppSpacing.lg),
                SettingsCard(
                  title: l10n.settingsOvertimeConfigTestingTitle,
                  subtitle: l10n.settingsOvertimeConfigTestingSubtitle,
                  leading: const Icon(Icons.science_outlined),
                  child: OvertimeSettingsConfigLab(
                    durationMinutes: durationMinutes,
                    quality: quality,
                    maxPhotoSize: maxPhotoSize,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmRestoreDefaults(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsOvertimeRestoreDialogTitle),
        content: Text(l10n.settingsOvertimeRestoreDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.settingsOvertimeRestoreConfirm),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _cubit.restoreDefaults();
    }
  }
}

class _PresetSection extends StatelessWidget {
  const _PresetSection({
    required this.l10n,
    required this.isDesktop,
    required this.canManage,
    required this.isSaving,
    required this.activePreset,
    required this.onPresetSelected,
  });

  final AppLocalizations l10n;
  final bool isDesktop;
  final bool canManage;
  final bool isSaving;
  final String activePreset;
  final ValueChanged<OvertimeConfigurationPreset> onPresetSelected;

  @override
  Widget build(BuildContext context) {
    final presets = [
      OvertimeConfigurationPreset.office,
      OvertimeConfigurationPreset.fieldService,
      OvertimeConfigurationPreset.heavyMaintenance,
    ];
    final allOptions = [
      ...presets,
      const OvertimeConfigurationPreset(
        id: OvertimeConfigurationPreset.customId,
        durationMinutes: 0,
        quality: 'medium',
        maxPhotoSize: 2,
        uploadPolicy: 'immediately',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.settingsOvertimePresetTitle,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.settingsOvertimePresetSubtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (isDesktop)
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: allOptions.map((preset) {
              return _PresetOptionCard(
                l10n: l10n,
                preset: preset,
                selected: activePreset == preset.id,
                canManage: canManage,
                isSaving: isSaving,
                onSelected: onPresetSelected,
                iconForPreset: _presetIcon,
              );
            }).toList(),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < allOptions.length; i++) ...[
                _PresetOptionCard(
                  l10n: l10n,
                  preset: allOptions[i],
                  selected: activePreset == allOptions[i].id,
                  canManage: canManage,
                  isSaving: isSaving,
                  onSelected: onPresetSelected,
                  iconForPreset: _presetIcon,
                ),
                if (i != allOptions.length - 1)
                  const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
      ],
    );
  }

  IconData _presetIcon(String id) {
    switch (id) {
      case 'office':
        return Icons.apartment_outlined;
      case 'field_service':
        return Icons.engineering_outlined;
      case 'heavy_maintenance':
        return Icons.build_circle_outlined;
      default:
        return Icons.tune_outlined;
    }
  }
}

class _PresetOptionCard extends StatelessWidget {
  const _PresetOptionCard({
    required this.l10n,
    required this.preset,
    required this.selected,
    required this.canManage,
    required this.isSaving,
    required this.onSelected,
    required this.iconForPreset,
  });

  final AppLocalizations l10n;
  final OvertimeConfigurationPreset preset;
  final bool selected;
  final bool canManage;
  final bool isSaving;
  final ValueChanged<OvertimeConfigurationPreset> onSelected;
  final IconData Function(String id) iconForPreset;

  String _uploadPolicyHint(String policy) {
    switch (OvertimeMediaConfig.normalizeUploadPolicy(policy)) {
      case 'wifi_preferred':
        return l10n.settingsOvertimeUploadPolicyWifiPreferredHint;
      case 'wifi_only':
        return l10n.settingsOvertimeUploadPolicyWifiOnlyHint;
      case 'manual':
        return l10n.settingsOvertimeUploadPolicyManualHint;
      case 'ask_every_time':
        return l10n.settingsOvertimeUploadPolicyAskEveryTimeHint;
      default:
        return l10n.settingsOvertimeUploadPolicyImmediatelyHint;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCustom = preset.id == OvertimeConfigurationPreset.customId;

    final estimatedTotalMb = OvertimeMediaEstimates.estimatedTotalUploadMb(
      durationMinutes: preset.durationMinutes,
      quality: preset.quality,
      maxPhotoSize: preset.maxPhotoSize,
    );

    final storageEstimate = l10n.settingsOvertimeEstimateTotalMb(
      estimatedTotalMb.toStringAsFixed(0),
    );
    final uploadLabel = uploadPolicyLabel(l10n, preset.uploadPolicy);

    final enabled = canManage && !isSaving && !selected && !isCustom;

    final borderColor = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.outlineVariant.withValues(alpha: 0.75);
    final background = selected
        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.32)
        : theme.colorScheme.surfaceContainerLow;

    return Semantics(
      button: true,
      selected: selected,
      label: presetLabel(l10n, preset.id),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: enabled ? () => onSelected(preset) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    iconForPreset(preset.id),
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      presetLabel(l10n, preset.id),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.settingsOvertimePresetSubtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                storageEstimate,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: Tooltip(
                      message: _uploadPolicyHint(preset.uploadPolicy),
                      child: Text(
                        uploadLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  if (selected)
                    Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DurationSetting extends StatelessWidget {
  const _DurationSetting({
    required this.l10n,
    required this.isDesktop,
    required this.canManage,
    required this.isSaving,
    required this.selectedMinutes,
    required this.optionsMinutes,
    required this.quality,
    required this.onSelected,
  });

  final AppLocalizations l10n;
  final bool isDesktop;
  final bool canManage;
  final bool isSaving;
  final int selectedMinutes;
  final List<int> optionsMinutes;
  final String quality;
  final Future<Result<OvertimeSettings>> Function(int) onSelected;

  @override
  Widget build(BuildContext context) {
    final estKb = OvertimeMediaEstimates.estimatedMaxVoiceKb(
      selectedMinutes,
      quality,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _OvertimeSettingBlock<int>(
          l10n: l10n,
          isDesktop: isDesktop,
          canManage: canManage,
          isSaving: isSaving,
          title: l10n.settingsOvertimeVoiceMaxDurationTitle,
          subtitle: l10n.settingsOvertimeVoiceMaxDurationSubtitle,
          currentValue: l10n.settingsOvertimeVoiceDurationMinutes(
            selectedMinutes,
          ),
          sheetTitle: l10n.settingsOvertimeVoiceMaxDurationTitle,
          options: optionsMinutes
              .map(
                (m) => _SettingOption<int>(
                  value: m,
                  label: l10n.settingsOvertimeVoiceDurationMinutes(m),
                ),
              )
              .toList(),
          selected: selectedMinutes,
          onSelected: onSelected,
          desktopBuilder: (context) => Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: optionsMinutes.map((minutes) {
              return ChoiceChip(
                label: Text(l10n.settingsOvertimeVoiceDurationMinutes(minutes)),
                selected: selectedMinutes == minutes,
                onSelected: !canManage || isSaving
                    ? null
                    : (_) => onSelected(minutes),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.settingsOvertimeEstimatedMaxFileSize(
            formatEstimatedSize(l10n, estKb),
          ),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _QualitySetting extends StatelessWidget {
  const _QualitySetting({
    required this.l10n,
    required this.isDesktop,
    required this.canManage,
    required this.isSaving,
    required this.selected,
    required this.options,
    required this.durationMinutes,
    required this.onSelected,
  });

  final AppLocalizations l10n;
  final bool isDesktop;
  final bool canManage;
  final bool isSaving;
  final String selected;
  final List<String> options;
  final int durationMinutes;
  final Future<Result<OvertimeSettings>> Function(String) onSelected;

  String _label(String quality) => voiceQualityLabel(l10n, quality);

  @override
  Widget build(BuildContext context) {
    final kbPerMin = OvertimeMediaEstimates.kbPerMinute(selected);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _OvertimeSettingBlock<String>(
          l10n: l10n,
          isDesktop: isDesktop,
          canManage: canManage,
          isSaving: isSaving,
          title: l10n.settingsOvertimeVoiceQualityTitle,
          subtitle: l10n.settingsOvertimeVoiceQualitySubtitle,
          currentValue: _label(selected),
          sheetTitle: l10n.settingsOvertimeVoiceQualityTitle,
          options: options
              .map((q) => _SettingOption(value: q, label: _label(q)))
              .toList(),
          selected: selected,
          onSelected: onSelected,
          desktopBuilder: (context) => Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: options.map((quality) {
              return ChoiceChip(
                label: Text(_label(quality)),
                selected: selected == quality,
                onSelected: !canManage || isSaving
                    ? null
                    : (_) => onSelected(quality),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.settingsOvertimeQualityEstimatePerMinute(
            formatEstimatedSize(l10n, kbPerMin),
          ),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.settingsOvertimeEstimatedMaxFileSize(
            formatEstimatedSize(
              l10n,
              OvertimeMediaEstimates.estimatedMaxVoiceKb(
                durationMinutes,
                selected,
              ),
            ),
          ),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _PhotoSizeSetting extends StatelessWidget {
  const _PhotoSizeSetting({
    required this.l10n,
    required this.isDesktop,
    required this.canManage,
    required this.isSaving,
    required this.selected,
    required this.options,
    required this.onSelected,
  });

  final AppLocalizations l10n;
  final bool isDesktop;
  final bool canManage;
  final bool isSaving;
  final Object selected;
  final List<Object> options;
  final Future<Result<OvertimeSettings>> Function(Object) onSelected;

  String _label(Object size) => photoSizeLabel(l10n, size);

  @override
  Widget build(BuildContext context) {
    return _OvertimeSettingBlock(
      l10n: l10n,
      isDesktop: isDesktop,
      canManage: canManage,
      isSaving: isSaving,
      title: l10n.settingsOvertimeMaxPhotoSizeTitle,
      subtitle: l10n.settingsOvertimeMaxPhotoSizeSubtitle,
      currentValue: _label(selected),
      sheetTitle: l10n.settingsOvertimeMaxPhotoSizeTitle,
      options: options
          .map((s) => _SettingOption(value: s, label: _label(s)))
          .toList(),
      selected: selected,
      onSelected: onSelected,
      desktopBuilder: (context) => Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: options.map((size) {
          return ChoiceChip(
            label: Text(_label(size)),
            selected: selected == size,
            onSelected: !canManage || isSaving ? null : (_) => onSelected(size),
          );
        }).toList(),
      ),
    );
  }
}

class _UploadPolicySetting extends StatelessWidget {
  const _UploadPolicySetting({
    required this.l10n,
    required this.isDesktop,
    required this.canManage,
    required this.isSaving,
    required this.selected,
    required this.options,
    required this.onSelected,
  });

  final AppLocalizations l10n;
  final bool isDesktop;
  final bool canManage;
  final bool isSaving;
  final String selected;
  final List<String> options;
  final Future<Result<OvertimeSettings>> Function(String) onSelected;

  String _label(String policy) => uploadPolicyLabel(l10n, policy);

  String _subtitle(String policy) {
    switch (policy) {
      case 'wifi_preferred':
        return l10n.settingsOvertimeUploadPolicyWifiPreferredHint;
      case 'wifi_only':
        return l10n.settingsOvertimeUploadPolicyWifiOnlyHint;
      case 'manual':
        return l10n.settingsOvertimeUploadPolicyManualHint;
      case 'ask_every_time':
        return l10n.settingsOvertimeUploadPolicyAskEveryTimeHint;
      default:
        return l10n.settingsOvertimeUploadPolicyImmediatelyHint;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _OvertimeSettingBlock(
      l10n: l10n,
      isDesktop: isDesktop,
      canManage: canManage,
      isSaving: isSaving,
      title: l10n.settingsOvertimeUploadPolicyTitle,
      subtitle: _subtitle(selected),
      currentValue: _label(selected),
      sheetTitle: l10n.settingsOvertimeUploadPolicyTitle,
      options: options
          .map((p) => _SettingOption(value: p, label: _label(p)))
          .toList(),
      selected: selected,
      onSelected: onSelected,
      desktopBuilder: (context) => Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: options.map((policy) {
          return ChoiceChip(
            label: Text(_label(policy)),
            selected: selected == policy,
            onSelected: !canManage || isSaving
                ? null
                : (_) => onSelected(policy),
          );
        }).toList(),
      ),
    );
  }
}

class _SettingOption<T> {
  const _SettingOption({required this.value, required this.label});
  final T value;
  final String label;
}

class _OvertimeSettingBlock<T> extends StatelessWidget {
  const _OvertimeSettingBlock({
    required this.l10n,
    required this.isDesktop,
    required this.canManage,
    required this.isSaving,
    required this.title,
    required this.subtitle,
    required this.currentValue,
    required this.sheetTitle,
    required this.options,
    required this.selected,
    required this.onSelected,
    required this.desktopBuilder,
  });

  final AppLocalizations l10n;
  final bool isDesktop;
  final bool canManage;
  final bool isSaving;
  final String title;
  final String subtitle;
  final String currentValue;
  final String sheetTitle;
  final List<_SettingOption<T>> options;
  final T selected;
  final Future<Result<OvertimeSettings>> Function(T) onSelected;
  final Widget Function(BuildContext context) desktopBuilder;

  Future<void> _openSheet(BuildContext context) async {
    if (!canManage || isSaving) {
      return;
    }
    final sortedOptions = [
      ...options.where((o) => o.value == selected),
      ...options.where((o) => o.value != selected),
    ];
    final picked = await showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.28,
          maxChildSize: 0.92,
          builder: (sheetCtx, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              children: [
                Text(
                  sheetTitle,
                  style: Theme.of(sheetCtx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ...sortedOptions.map(
                  (option) => ListTile(
                    title: Text(option.label),
                    trailing: AnimatedScale(
                      duration: const Duration(milliseconds: 180),
                      scale: option.value == selected ? 1 : 0,
                      child: Icon(
                        Icons.check_rounded,
                        color: Theme.of(sheetCtx).colorScheme.primary,
                      ),
                    ),
                    onTap: () => Navigator.pop(sheetCtx, option.value),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
    if (picked != null && picked != selected) {
      await onSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (isDesktop)
          desktopBuilder(context)
        else
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.settingsOvertimeVoiceCurrentValue(currentValue)),
            trailing: const Icon(Icons.chevron_right_rounded),
            enabled: canManage && !isSaving,
            onTap: () => _openSheet(context),
          ),
        if (isDesktop) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.settingsOvertimeVoiceCurrentValue(currentValue),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
