import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/constants/app_breakpoints.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/app_formatters.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_app_message.dart';
import 'package:mobile/core/widgets/app_loader.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_page_header.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_split_view.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/features/overtime/presentation/widgets/overtime_voice_note_section.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order_priority.dart';
import 'package:mobile/features/organization/domain/entities/user_summary.dart';
import 'package:mobile/features/work_orders/presentation/cubit/work_order_form_cubit.dart';
import 'package:mobile/features/work_orders/presentation/utils/work_order_labels.dart';
import 'package:mobile/features/work_orders/presentation/utils/work_order_location_launcher.dart';
import 'package:mobile/features/work_orders/presentation/utils/work_order_phone_numbers.dart';

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
  final _locationAddressController = TextEditingController();
  final _locationUrlController = TextEditingController();
  final _notesController = TextEditingController();
  final _technicianSearchController = TextEditingController();

  bool _controllersSynced = false;
  String _technicianQuery = '';

  @override
  void dispose() {
    _titleController.dispose();
    _customerController.dispose();
    _locationAddressController.dispose();
    _locationUrlController.dispose();
    _notesController.dispose();
    _technicianSearchController.dispose();
    super.dispose();
  }

  void _syncControllers(WorkOrderFormState state) {
    if (_controllersSynced || state.status != WorkOrderFormStatus.ready) {
      return;
    }
    _titleController.text = state.jobTitle;
    _customerController.text = state.customerName;
    _locationAddressController.text = state.locationLabel;
    _locationUrlController.text = state.locationUrl;
    _notesController.text = state.notes;
    _controllersSynced = true;
  }

  String _mimeForFileName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }

  Future<void> _addPickedFiles(List<XFile> files) async {
    if (files.isEmpty) {
      return;
    }
    final cubit = context.read<WorkOrderFormCubit>();
    for (final file in files) {
      if (!cubit.state.canAddMoreAttachments) {
        break;
      }
      final bytes = await file.readAsBytes();
      if (!mounted) {
        return;
      }
      cubit.addAttachment(
        WorkOrderAttachmentInput(
          bytes: bytes,
          fileName: file.name,
          mimeType: _mimeForFileName(file.name),
        ),
      );
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(imageQuality: 85);
    await _addPickedFiles(files);
  }

  Future<void> _pickFromCamera() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (file == null) {
      return;
    }
    await _addPickedFiles([file]);
  }

  Future<void> _pickDateTime() async {
    final cubit = context.read<WorkOrderFormCubit>();
    final now = DateTime.now();
    final initial = cubit.state.scheduledAt?.toLocal() ?? now;
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (selectedDate == null || !mounted) {
      return;
    }
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (selectedTime == null || !mounted) {
      return;
    }
    cubit.updateField(
      scheduledAt: DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      ),
    );
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
            body: AppLoader(message: l10n.workOrderLoading),
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
        final isDesktop = AppBreakpoints.isDesktopOf(context);
        final maxWidth = isDesktop
            ? double.infinity
            : (MediaQuery.sizeOf(context).width >= 900
                ? 720.0
                : double.infinity);
        final dateTimeFormat = AppFormatters.mediumDateTime(context);
        final filteredTechnicians = state.technicians.where((user) {
          if (_technicianQuery.trim().isEmpty) {
            return true;
          }
          return user.fullName
              .toLowerCase()
              .contains(_technicianQuery.trim().toLowerCase());
        }).toList();
        final selectedTechnicians = state.technicians
            .where((user) => state.assignedTechnicianIds.contains(user.id))
            .toList();

        final formTitle =
            widget.isEditing ? l10n.workOrderEdit : l10n.workOrderCreate;
        final desktopFormFields = AppDesktopSplitView(
          startFlex: 11,
          endFlex: 9,
          gap: AppSpacing.lg,
          start: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.workOrderDetails,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.md),
              ..._buildPrimaryFormFields(
                context: context,
                state: state,
                l10n: l10n,
                saving: saving,
                splitAtVoice: true,
                part: _WorkOrderFormPart.primary,
                showSaveButton: false,
              ),
            ],
          ),
          end: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ..._buildPrimaryFormFields(
                context: context,
                state: state,
                l10n: l10n,
                saving: saving,
                splitAtVoice: true,
                part: _WorkOrderFormPart.secondary,
                showSaveButton: false,
                dateTimeFormat: dateTimeFormat,
                filteredTechnicians: filteredTechnicians,
                selectedTechnicians: selectedTechnicians,
                pickDateTime: _pickDateTime,
                pickFromCamera: _pickFromCamera,
                pickFromGallery: _pickFromGallery,
              ),
            ],
          ),
        );

        if (isDesktop) {
          return Scaffold(
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: saving ? null : () => context.pop(),
                      ),
                      Expanded(
                        child: AppDesktopPageHeader(title: formTitle),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.md,
                    ),
                    child: desktopFormFields,
                  ),
                ),
                SafeArea(
                  top: false,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border(
                        top: BorderSide(
                          color: Theme.of(context)
                              .colorScheme
                              .outlineVariant
                              .withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.lg,
                        AppSpacing.md,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SizedBox(
                            width: 130,
                            height: 48,
                            child: OutlinedButton(
                              key: const Key('work-order-form-close'),
                              onPressed: saving ? null : () => context.pop(),
                              child: Text(
                                l10n.close,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          SizedBox(
                            width: 130,
                            height: 48,
                            child: FilledButton(
                              key: const Key('work-order-form-save'),
                              onPressed: saving
                                  ? null
                                  : () => context
                                      .read<WorkOrderFormCubit>()
                                      .submit(),
                              child: saving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      l10n.workOrderSave,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: Text(formTitle)),
          body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: AppBottomSafeListView(
                basePadding: EdgeInsets.fromLTRB(
                  isDesktop ? AppSpacing.lg : AppSpacing.lg,
                  isDesktop ? AppSpacing.md : AppSpacing.lg,
                  isDesktop ? AppSpacing.lg : AppSpacing.lg,
                  isDesktop ? AppSpacing.lg : AppSpacing.lg,
                ),
                chrome: AppBottomChrome.system,
                children: _buildPrimaryFormFields(
                  context: context,
                  state: state,
                  l10n: l10n,
                  saving: saving,
                  splitAtVoice: false,
                  part: _WorkOrderFormPart.all,
                  dateTimeFormat: dateTimeFormat,
                  filteredTechnicians: filteredTechnicians,
                  selectedTechnicians: selectedTechnicians,
                  pickDateTime: _pickDateTime,
                  pickFromCamera: _pickFromCamera,
                  pickFromGallery: _pickFromGallery,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildPrimaryFormFields({
    required BuildContext context,
    required WorkOrderFormState state,
    required AppLocalizations l10n,
    required bool saving,
    required bool splitAtVoice,
    required _WorkOrderFormPart part,
    bool showSaveButton = true,
    DateFormat? dateTimeFormat,
    List<UserSummary>? filteredTechnicians,
    List<UserSummary>? selectedTechnicians,
    Future<void> Function()? pickDateTime,
    Future<void> Function()? pickFromCamera,
    Future<void> Function()? pickFromGallery,
  }) {
    final includePrimary =
        !splitAtVoice || part == _WorkOrderFormPart.primary || part == _WorkOrderFormPart.all;
    final includeSecondary =
        !splitAtVoice || part == _WorkOrderFormPart.secondary || part == _WorkOrderFormPart.all;

    final fields = <Widget>[];

    if (includePrimary) {
      fields.addAll([
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
        Text(
          l10n.workOrderCustomerPhoneNumbers,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        ...List.generate(state.customerPhoneNumbers.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: ValueKey(
                      'customer-phone-$index-${state.customerPhoneNumbers.length}',
                    ),
                    initialValue: state.customerPhoneNumbers[index],
                    decoration: InputDecoration(
                      labelText: l10n.workOrderCustomerPhoneNumbers,
                      errorText: state.isError &&
                              state.message == 'workOrderCustomerPhoneInvalid' &&
                              WorkOrderPhoneNumbers.firstInvalid(
                                    state.customerPhoneNumbers,
                                  ) ==
                                  state.customerPhoneNumbers[index].trim()
                          ? localizeAppMessage(l10n, state.message)
                          : null,
                    ),
                    keyboardType: TextInputType.phone,
                    enabled: !saving,
                    onChanged: (value) => context
                        .read<WorkOrderFormCubit>()
                        .updatePhoneNumberAt(index, value),
                  ),
                ),
                IconButton(
                  tooltip: l10n.workOrderDelete,
                  onPressed: saving
                      ? null
                      : () => context
                          .read<WorkOrderFormCubit>()
                          .removePhoneNumberAt(index),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          );
        }),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: saving
                ? null
                : () =>
                    context.read<WorkOrderFormCubit>().addPhoneNumberRow(),
            icon: const Icon(Icons.add),
            label: Text(l10n.workOrderAddPhoneNumber),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _locationAddressController,
          decoration: InputDecoration(
            labelText: l10n.workOrderLocation,
            hintText: l10n.workOrderLocationAddressHint,
          ),
          textInputAction: TextInputAction.next,
          maxLines: 2,
          minLines: 1,
          enabled: !saving,
          onChanged: (value) => context
              .read<WorkOrderFormCubit>()
              .updateField(locationLabel: value),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.workOrderLocationLink,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (state.locationLinkVisible)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _locationUrlController,
                    decoration: InputDecoration(
                      labelText: l10n.workOrderLocationLink,
                      hintText: l10n.workOrderLocationUrlHint,
                      errorText: state.isError &&
                              state.message == 'workOrderLocationUrlInvalid'
                          ? localizeAppMessage(l10n, state.message)
                          : null,
                      suffixIcon: WorkOrderLocationLauncher.isValidHttpUrl(
                              _locationUrlController.text)
                          ? IconButton(
                              tooltip: l10n.workOrderOpenLocation,
                              onPressed: saving
                                  ? null
                                  : () async {
                                      final opened =
                                          await WorkOrderLocationLauncher
                                              .openUrl(
                                        _locationUrlController.text,
                                      );
                                      if (!opened && context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              l10n.workOrderCouldNotOpenMaps,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                              icon: const Icon(Icons.open_in_new),
                            )
                          : null,
                    ),
                    keyboardType: TextInputType.url,
                    enabled: !saving,
                    onChanged: (value) {
                      context
                          .read<WorkOrderFormCubit>()
                          .updateField(locationUrl: value);
                      setState(() {});
                    },
                  ),
                ),
                IconButton(
                  tooltip: l10n.workOrderDelete,
                  onPressed: saving
                      ? null
                      : () {
                          _locationUrlController.clear();
                          context
                              .read<WorkOrderFormCubit>()
                              .removeLocationLink();
                        },
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          )
        else
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: saving
                  ? null
                  : () =>
                      context.read<WorkOrderFormCubit>().addLocationLinkRow(),
              icon: const Icon(Icons.add),
              label: Text(l10n.workOrderAddLocationLink),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _notesController,
          decoration: InputDecoration(labelText: l10n.workOrderNotes),
          maxLines: 3,
          onChanged: (value) =>
              context.read<WorkOrderFormCubit>().updateField(notes: value),
        ),
      ]);
    }

    if (includeSecondary) {
      if (includePrimary && splitAtVoice) {
        fields.add(const SizedBox(height: AppSpacing.sm));
      }
      fields.addAll([
        Text(
          l10n.workOrderVoiceNote,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        OvertimeVoiceNoteSection(
          remoteUrl:
              state.clearVoiceNote ? null : state.existingVoiceNote?.url,
          localBytes: state.voiceDraft?.bytes,
          durationSeconds: state.voiceDraft?.durationSeconds ??
              state.existingVoiceNote?.duration,
          readOnly: false,
          enabled: !saving,
          onDraftChanged: (draft) {
            final cubit = context.read<WorkOrderFormCubit>();
            if (draft == null) {
              if (state.existingVoiceNote != null && !state.clearVoiceNote) {
                cubit.clearExistingVoiceNote();
              } else {
                cubit.setVoiceDraft(null);
              }
            } else {
              cubit.setVoiceDraft(draft);
            }
          },
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
                ? l10n.valueNotSet
                : dateTimeFormat!.format(state.scheduledAt!.toLocal()),
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
                onPressed: saving ? null : pickDateTime,
                icon: const Icon(Icons.event_outlined),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.workOrderTechnicians,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (selectedTechnicians!.isNotEmpty)
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: selectedTechnicians
                .map(
                  (user) => InputChip(
                    label: Text(user.fullName),
                    onDeleted: saving
                        ? null
                        : () => context
                            .read<WorkOrderFormCubit>()
                            .removeTechnician(user.id),
                  ),
                )
                .toList(),
          ),
        if (selectedTechnicians.isEmpty)
          Text(
            l10n.workOrderUnassigned,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _technicianSearchController,
          decoration: InputDecoration(
            labelText: l10n.workOrderSelectTechnician,
            prefixIcon: const Icon(Icons.search),
          ),
          onChanged: (value) => setState(() => _technicianQuery = value),
        ),
        const SizedBox(height: AppSpacing.sm),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 220),
          child: filteredTechnicians!.isEmpty
              ? Text(l10n.workOrderNoTechnicians)
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: filteredTechnicians.length,
                  itemBuilder: (context, index) {
                    final user = filteredTechnicians[index];
                    final selected =
                        state.assignedTechnicianIds.contains(user.id);
                    return CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: selected,
                      title: Text(user.fullName),
                      onChanged: saving
                          ? null
                          : (_) => context
                              .read<WorkOrderFormCubit>()
                              .toggleTechnician(user.id),
                    );
                  },
                ),
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
                label: Text(
                  item.fileName ?? l10n.workOrderAttachmentFallback,
                ),
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
              avatar: const Icon(Icons.photo_camera_outlined, size: 18),
              label: Text(l10n.workOrderTakePhoto),
              onPressed: saving || !state.canAddMoreAttachments
                  ? null
                  : pickFromCamera,
            ),
            ActionChip(
              avatar: const Icon(Icons.photo_library_outlined, size: 18),
              label: Text(l10n.workOrderChooseFromGallery),
              onPressed: saving || !state.canAddMoreAttachments
                  ? null
                  : pickFromGallery,
            ),
          ],
        ),
        if (showSaveButton) ...[
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed:
                saving ? null : () => context.read<WorkOrderFormCubit>().submit(),
            child: saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.workOrderSave),
          ),
        ],
      ]);
    }

    return fields;
  }
}

enum _WorkOrderFormPart { all, primary, secondary }
