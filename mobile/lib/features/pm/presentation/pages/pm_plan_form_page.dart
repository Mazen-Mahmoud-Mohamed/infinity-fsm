import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_app_message.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/core/widgets/app_loader.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/features/pm/domain/entities/pm_entities.dart';
import 'package:mobile/features/pm/presentation/cubit/pm_plan_detail_form_checklist_cubits.dart';
import 'package:mobile/features/pm/presentation/widgets/pm_status_badges.dart';

class PmPlanFormPage extends StatefulWidget {
  const PmPlanFormPage({super.key, this.planId});

  final String? planId;

  @override
  State<PmPlanFormPage> createState() => _PmPlanFormPageState();
}

class _PmPlanFormPageState extends State<PmPlanFormPage> {
  late final PmPlanFormCubit _cubit;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController(text: '60');
  final _meterThresholdController = TextEditingController();
  final _meterReadingController = TextEditingController();

  PmFrequency _frequency = PmFrequency.monthly;
  PmTrigger _trigger = PmTrigger.timeBased;
  PmPriority _priority = PmPriority.medium;
  PmPlanStatus _status = PmPlanStatus.active;
  DateTime? _nextDueDate;
  String? _teamId;
  String? _technicianId;
  String? _assetId;
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<PmPlanFormCubit>(param1: widget.planId ?? '')..load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _meterThresholdController.dispose();
    _meterReadingController.dispose();
    _cubit.close();
    super.dispose();
  }

  void _seedFromPlan(MaintenancePlan plan) {
    if (_seeded) return;
    _seeded = true;
    _nameController.text = plan.name;
    _codeController.text = plan.code;
    _descriptionController.text = plan.description ?? '';
    _durationController.text = '${plan.estimatedDurationMinutes}';
    _frequency = plan.frequency;
    _trigger = plan.trigger;
    _priority = plan.priority;
    _status = plan.status;
    _nextDueDate = plan.nextDueDate;
    _teamId = plan.assignedTeam?.id;
    _technicianId = plan.assignedTechnician?.id;
    _assetId = plan.asset?.id;
    if (plan.meterThreshold != null) {
      _meterThresholdController.text = '${plan.meterThreshold}';
    }
    if (plan.currentMeterReading != null) {
      _meterReadingController.text = '${plan.currentMeterReading}';
    }
    setState(() {});
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextDueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) {
      setState(() => _nextDueDate = picked);
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;

    final input = MaintenancePlanUpsertInput(
      name: _nameController.text.trim(),
      code: _codeController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      frequency: _frequency,
      trigger: _trigger,
      nextDueDate: _nextDueDate,
      priority: _priority,
      estimatedDurationMinutes:
          int.tryParse(_durationController.text.trim()) ?? 60,
      assignedTeamId: _teamId,
      assignedTechnicianId: _technicianId,
      assetId: _assetId,
      meterThreshold: double.tryParse(_meterThresholdController.text.trim()),
      currentMeterReading:
          double.tryParse(_meterReadingController.text.trim()),
      status: _status,
      checklistItems: _cubit.state.plan?.checklistItems ?? const [],
    );

    final result = await _cubit.save(input);
    if (!mounted) return;
    switch (result) {
      case Success():
        Navigator.of(context).pop(true);
      case Failure(message: final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message.isEmpty ? l10n.pmLoadFailed : localizeAppMessage(l10n, message))),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEditing = widget.planId != null && widget.planId!.isNotEmpty;

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? l10n.pmEditPlan : l10n.pmCreatePlan),
        ),
        body: BlocConsumer<PmPlanFormCubit, PmPlanFormState>(
          listener: (context, state) {
            if (state.plan != null) _seedFromPlan(state.plan!);
          },
          builder: (context, state) {
            if (state.status == PmPlanFormStatus.loading ||
                state.status == PmPlanFormStatus.initial) {
              return AppLoader(message: l10n.pmLoading);
            }
            if (state.status == PmPlanFormStatus.failure &&
                state.plan == null &&
                isEditing) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                          state.message != null
                              ? localizeAppMessage(l10n, state.message)
                              : l10n.pmLoadFailed,
                        ),
                    FilledButton(
                      onPressed: _cubit.load,
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              );
            }

            final saving = state.status == PmPlanFormStatus.saving;

            return Form(
              key: _formKey,
              child: AppBottomSafeListView(
                basePadding: const EdgeInsets.all(AppSpacing.md),
                chrome: AppBottomChrome.system,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: l10n.pmName),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? l10n.pmRequired : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _codeController,
                    decoration: InputDecoration(labelText: l10n.pmCode),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? l10n.pmRequired : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(labelText: l10n.pmDescription),
                    maxLines: 3,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<PmFrequency>(
                    initialValue: _frequency,
                    decoration: InputDecoration(labelText: l10n.pmFrequency),
                    items: PmFrequency.values
                        .map(
                          (f) => DropdownMenuItem(
                            value: f,
                            child: Text(pmFrequencyLabel(l10n, f)),
                          ),
                        )
                        .toList(),
                    onChanged: saving
                        ? null
                        : (v) {
                            if (v != null) setState(() => _frequency = v);
                          },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<PmTrigger>(
                    initialValue: _trigger,
                    decoration: InputDecoration(labelText: l10n.pmTrigger),
                    items: PmTrigger.values
                        .map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(pmTriggerLabel(l10n, t)),
                          ),
                        )
                        .toList(),
                    onChanged: saving
                        ? null
                        : (v) {
                            if (v != null) setState(() => _trigger = v);
                          },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<PmPriority>(
                    initialValue: _priority,
                    decoration: InputDecoration(labelText: l10n.pmPriority),
                    items: [
                      DropdownMenuItem(
                        value: PmPriority.low,
                        child: Text(l10n.pmPriorityLow),
                      ),
                      DropdownMenuItem(
                        value: PmPriority.medium,
                        child: Text(l10n.pmPriorityMedium),
                      ),
                      DropdownMenuItem(
                        value: PmPriority.high,
                        child: Text(l10n.pmPriorityHigh),
                      ),
                      DropdownMenuItem(
                        value: PmPriority.critical,
                        child: Text(l10n.pmPriorityCritical),
                      ),
                    ],
                    onChanged: saving
                        ? null
                        : (v) {
                            if (v != null) setState(() => _priority = v);
                          },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<PmPlanStatus>(
                    initialValue: _status,
                    decoration: InputDecoration(labelText: l10n.pmStatus),
                    items: [
                      DropdownMenuItem(
                        value: PmPlanStatus.active,
                        child: Text(l10n.pmStatusActive),
                      ),
                      DropdownMenuItem(
                        value: PmPlanStatus.inactive,
                        child: Text(l10n.pmStatusInactive),
                      ),
                    ],
                    onChanged: saving
                        ? null
                        : (v) {
                            if (v != null) setState(() => _status = v);
                          },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.pmNextDueDate),
                    subtitle: Text(
                      _nextDueDate == null
                          ? l10n.valueNotSet
                          : '${_nextDueDate!.day}/${_nextDueDate!.month}/${_nextDueDate!.year}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: saving ? null : _pickDueDate,
                    ),
                  ),
                  TextFormField(
                    controller: _durationController,
                    decoration:
                        InputDecoration(labelText: l10n.pmEstimatedDuration),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String?>(
                    initialValue: _technicianId,
                    decoration:
                        InputDecoration(labelText: l10n.pmAssignedTechnician),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(l10n.pmNone),
                      ),
                      ...state.users.map(
                        (u) => DropdownMenuItem(
                          value: u.id,
                          child: Text(u.fullName.isEmpty ? u.name : u.fullName),
                        ),
                      ),
                    ],
                    onChanged: saving
                        ? null
                        : (v) => setState(() => _technicianId = v),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String?>(
                    initialValue: _assetId,
                    decoration: InputDecoration(labelText: l10n.pmLinkedAsset),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(l10n.pmNone),
                      ),
                      ...state.assets.map(
                        (a) => DropdownMenuItem(
                          value: a.id,
                          child: Text(
                            [
                              if (a.assetNumber.isNotEmpty) a.assetNumber,
                              a.name,
                            ].where((e) => e.isNotEmpty).join(' · '),
                          ),
                        ),
                      ),
                    ],
                    onChanged: saving
                        ? null
                        : (v) => setState(() => _assetId = v),
                  ),
                  if (_trigger == PmTrigger.meterBased) ...[
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _meterThresholdController,
                      decoration:
                          InputDecoration(labelText: l10n.pmMeterThreshold),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _meterReadingController,
                      decoration: InputDecoration(
                        labelText: l10n.pmCurrentMeterReading,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(
                    onPressed: saving ? null : _submit,
                    child: saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.pmSave),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
