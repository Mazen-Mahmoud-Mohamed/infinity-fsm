import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/app_formatters.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_app_message.dart';
import 'package:mobile/core/widgets/app_loader.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order_priority.dart';
import 'package:mobile/features/work_orders/presentation/cubit/work_order_form_cubit.dart';
import 'package:mobile/features/work_orders/presentation/utils/work_order_labels.dart';

class WorkOrderFormPage extends StatelessWidget {
  const WorkOrderFormPage({super.key, this.workOrderId});

  final String? workOrderId;

  @override
  Widget build(BuildContext context) {
    final permissions =
        context.read<AuthCubit>().state.user?.permissionChecker;
    final isEditing = workOrderId != null;
    final allowed = isEditing
        ? permissions?.canUpdateWorkOrder() == true
        : permissions?.canCreateWorkOrder() == true;

    if (!allowed) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            isEditing
                ? AppLocalizations.of(context).workOrderEdit
                : AppLocalizations.of(context).workOrderCreate,
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              AppLocalizations.of(context).workOrderNoPermission,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return BlocProvider(
      create: (_) =>
          getIt<WorkOrderFormCubit>(param1: workOrderId ?? '')..load(),
      child: _WorkOrderFormView(isEditing: isEditing),
    );
  }
}

class _WorkOrderFormView extends StatefulWidget {
  const _WorkOrderFormView({required this.isEditing});

  final bool isEditing;

  @override
  State<_WorkOrderFormView> createState() => _WorkOrderFormViewState();
}

class _WorkOrderFormViewState extends State<_WorkOrderFormView> {
  final _titleController = TextEditingController();
  final _customerController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  
  bool _controllersSynced = false;

  @override
  void dispose() {
    _titleController.dispose();
    _customerController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _syncControllers(WorkOrderFormState state) {
    if (_controllersSynced || state.status != WorkOrderFormStatus.ready) {
      return;
    }
    _titleController.text = state.jobTitle;
    _customerController.text = state.customerName;
    _locationController.text = state.locationLabel;
    _descriptionController.text = state.description;
    _notesController.text = state.notes;
    _controllersSynced = true;
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) {
      return;
    }
    final bytes = await file.readAsBytes();
    if (!mounted) {
      return;
    }
    final name = file.name.toLowerCase();
    final mime = name.endsWith('.png')
        ? 'image/png'
        : name.endsWith('.webp')
            ? 'image/webp'
            : 'image/jpeg';
    context.read<WorkOrderFormCubit>().addAttachment(
          WorkOrderAttachmentInput(
            bytes: bytes,
            fileName: file.name,
            mimeType: mime,
          ),
        );
  }

  Future<void> _pickDate() async {
    final cubit = context.read<WorkOrderFormCubit>();
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: cubit.state.scheduledAt?.toLocal() ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (selected != null) {
      cubit.updateField(
        scheduledAt: DateTime(selected.year, selected.month, selected.day, 9),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocConsumer<WorkOrderFormCubit, WorkOrderFormState>(
      listener: (context, state) {
        _syncControllers(state);
        if (state.status == WorkOrderFormStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                localizeAppMessage(l10n, state.message ?? 'workOrderSaved'),
              ),
            ),
          );
          context.pop(true);
        } else if (state.message != null && state.isError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizeAppMessage(l10n, state.message)),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state.status == WorkOrderFormStatus.loading ||
            state.status == WorkOrderFormStatus.initial) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                widget.isEditing ? l10n.workOrderEdit : l10n.workOrderCreate,
              ),
            ),
            body: const AppLoader(),
          );
        }

        if (state.status == WorkOrderFormStatus.failure &&
            state.existing == null &&
            widget.isEditing) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.workOrderEdit)),
            body: Center(
              child: Text(
                state.message != null
                    ? localizeAppMessage(l10n, state.message)
                    : l10n.errorGeneric,
              ),
            ),
          );
        }

        final saving = state.status == WorkOrderFormStatus.saving;
        final maxWidth =
            MediaQuery.sizeOf(context).width >= 900 ? 720.0 : double.infinity;
        final dateFormat = AppFormatters.mediumDate(context);

        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.isEditing ? l10n.workOrderEdit : l10n.workOrderCreate,
            ),
          ),
          body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: AppBottomSafeListView(
                basePadding: const EdgeInsets.all(AppSpacing.lg),
                chrome: AppBottomChrome.system,
                children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: l10n.workOrderJobTitle,
                  errorText: state.isError &&
                          state.message == 'workOrderJobTitleRequired' &&
                          _titleController.text.trim().isEmpty
                      ? localizeAppMessage(l10n, state.message)
                      : null,
                ),
                textInputAction: TextInputAction.next,
                onChanged: (value) =>
                    context.read<WorkOrderFormCubit>().updateField(jobTitle: value),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _customerController,
                decoration: InputDecoration(labelText: l10n.workOrderCustomer),
                onChanged: (value) => context
                    .read<WorkOrderFormCubit>()
                    .updateField(customerName: value),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _locationController,
                decoration: InputDecoration(labelText: l10n.workOrderLocation),
                onChanged: (value) => context
                    .read<WorkOrderFormCubit>()
                    .updateField(locationLabel: value),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _descriptionController,
                decoration:
                    InputDecoration(labelText: l10n.workOrderDescription),
                maxLines: 4,
                onChanged: (value) => context
                    .read<WorkOrderFormCubit>()
                    .updateField(description: value),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _notesController,
                decoration: InputDecoration(labelText: l10n.workOrderNotes),
                maxLines: 2,
                onChanged: (value) =>
                    context.read<WorkOrderFormCubit>().updateField(notes: value),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<WorkOrderPriority>(
                key: ValueKey('priority-${state.priority.apiValue}'),
                initialValue: state.priority,
                decoration: InputDecoration(labelText: l10n.workOrderPriority),
                items: WorkOrderPriority.values
                    .map(
                      (priority) => DropdownMenuItem(
                        value: priority,
                        child: Text(workOrderPriorityLabel(l10n, priority)),
                      ),
                    )
                    .toList(),
                onChanged: saving
                    ? null
                    : (value) {
                        if (value != null) {
                          context
                              .read<WorkOrderFormCubit>()
                              .updateField(priority: value);
                        }
                      },
              ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.workOrderScheduledDate),
                subtitle: Text(
                  state.scheduledAt == null
                      ? '—'
                      : dateFormat.format(state.scheduledAt!.toLocal()),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (state.scheduledAt != null)
                      IconButton(
                        onPressed: saving
                            ? null
                            : () => context
                                .read<WorkOrderFormCubit>()
                                .updateField(clearScheduledAt: true),
                        icon: const Icon(Icons.clear),
                      ),
                    IconButton(
                      onPressed: saving ? null : _pickDate,
                      icon: const Icon(Icons.calendar_today_outlined),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String?>(
                key: ValueKey('tech-${state.assignedTechnicianId ?? 'none'}'),
                initialValue: state.assignedTechnicianId,
                decoration:
                    InputDecoration(labelText: l10n.workOrderTechnician),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(l10n.workOrderUnassigned),
                  ),
                  ...state.technicians.map(
                    (user) => DropdownMenuItem<String?>(
                      value: user.id,
                      child: Text(user.fullName),
                    ),
                  ),
                ],
                onChanged: saving
                    ? null
                    : (value) {
                        if (value == null) {
                          context.read<WorkOrderFormCubit>().updateField(
                                clearAssignedTechnicianId: true,
                              );
                        } else {
                          context.read<WorkOrderFormCubit>().updateField(
                                assignedTechnicianId: value,
                              );
                        }
                      },
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.workOrderAttachments,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  ...state.existingAttachments.map(
                    (item) => InputChip(
                      label: Text(item.fileName ?? 'Attachment'),
                      onDeleted: saving
                          ? null
                          : () => context
                              .read<WorkOrderFormCubit>()
                              .removeExistingAttachment(item.url),
                    ),
                  ),
                  ...List.generate(state.pendingAttachments.length, (index) {
                    final item = state.pendingAttachments[index];
                    return InputChip(
                      label: Text(item.fileName),
                      onDeleted: saving
                          ? null
                          : () => context
                              .read<WorkOrderFormCubit>()
                              .removePendingAttachment(index),
                    );
                  }),
                  ActionChip(
                    avatar: const Icon(Icons.add_a_photo_outlined, size: 18),
                    label: Text(l10n.workOrderAddPhoto),
                    onPressed: saving ? null : _pickPhoto,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: saving
                    ? null
                    : () => context.read<WorkOrderFormCubit>().submit(),
                child: saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.workOrderSave),
              ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
