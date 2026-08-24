import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/localization/app_formatters.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/features/overtime/presentation/utils/overtime_maps_launcher.dart';
import 'package:mobile/features/overtime/presentation/widgets/overtime_voice_note_section.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order.dart';
import 'package:mobile/features/work_orders/domain/entities/work_order_status.dart';
import 'package:mobile/features/work_orders/presentation/cubit/work_order_detail_cubit.dart';
import 'package:mobile/features/work_orders/presentation/utils/work_order_location_launcher.dart';
import 'package:mobile/features/work_orders/presentation/utils/work_order_phone_launcher.dart';
import 'package:mobile/features/work_orders/presentation/widgets/work_order_photo_gallery.dart';
import 'package:mobile/features/work_orders/presentation/widgets/work_order_section_card.dart';
import 'package:mobile/features/work_orders/presentation/widgets/work_order_text_prompt.dart';

/// Which portion of the execution panel to render (desktop split layouts).
enum WorkOrderExecutionColumn {
  /// Full single-column layout (phone / default).
  all,

  /// Desktop main column: overview + stage sections (each once, with photos).
  main,

  /// Desktop sidebar: attachments + captured locations only.
  sidebar,
}

class WorkOrderExecutionPanel extends StatelessWidget {
  const WorkOrderExecutionPanel({
    super.key,
    required this.workOrder,
    required this.state,
    required this.canExecute,
    this.completionNotesDraft = '',
    this.onCompletionNotesChanged,
    this.column = WorkOrderExecutionColumn.all,
  });

  final WorkOrder workOrder;
  final WorkOrderDetailState state;
  final bool canExecute;
  final String completionNotesDraft;
  final ValueChanged<String>? onCompletionNotesChanged;
  final WorkOrderExecutionColumn column;

  bool get _isAccepted => workOrder.status == WorkOrderStatus.accepted;
  bool get _isInProgress => workOrder.status == WorkOrderStatus.inProgress;
  bool get _isCompleted => workOrder.status == WorkOrderStatus.completed;
  bool get _isEditable =>
      canExecute && (_isAccepted || _isInProgress) && !state.isBusy;

  @override
  Widget build(BuildContext context) {
    if (column == WorkOrderExecutionColumn.sidebar) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AttachmentsSection(workOrder: workOrder),
          if (workOrder.startedLocation != null ||
              workOrder.completedLocation != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _CapturedLocationsSection(workOrder: workOrder),
          ],
        ],
      );
    }

    final showBefore = _isAccepted || _isInProgress || _isCompleted;
    final showDuringOrComplete = _isInProgress || _isCompleted;
    final includeOverviewAttachments = column == WorkOrderExecutionColumn.all;
    final includeLocations = column == WorkOrderExecutionColumn.all;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _OverviewSection(
          workOrder: workOrder,
          includeAttachments: includeOverviewAttachments,
        ),
        if (showBefore) ...[
          const SizedBox(height: AppSpacing.sm),
          _BeforeWorkSection(
            workOrder: workOrder,
            state: state,
            canEdit: _isEditable && (_isAccepted || _isInProgress),
          ),
        ],
        if (showDuringOrComplete) ...[
          const SizedBox(height: AppSpacing.sm),
          _InProgressSection(
            workOrder: workOrder,
            state: state,
            canEdit: _isEditable && _isInProgress,
          ),
          const SizedBox(height: AppSpacing.sm),
          _CompleteWorkSection(
            workOrder: workOrder,
            state: state,
            canEdit: _isEditable && _isInProgress,
            completionNotesDraft: completionNotesDraft,
            onCompletionNotesChanged: onCompletionNotesChanged,
          ),
        ],
        if (includeLocations &&
            (workOrder.startedLocation != null ||
                workOrder.completedLocation != null)) ...[
          const SizedBox(height: AppSpacing.sm),
          _CapturedLocationsSection(workOrder: workOrder),
        ],
      ],
    );
  }
}

class _OverviewSection extends StatelessWidget {
  const _OverviewSection({
    required this.workOrder,
    this.includeAttachments = true,
  });

  final WorkOrder workOrder;
  final bool includeAttachments;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final address = workOrder.customerAddress;
    final hasCoords = address?.hasCoordinates == true;
    final imageAttachments =
        workOrder.attachments.where((a) => a.isImage).toList();
    final fileAttachments =
        workOrder.attachments.where((a) => !a.isImage).toList();

    return WorkOrderSectionCard(
      icon: Icons.info_outline,
      title: l10n.workOrderOverview,
      subtitle: l10n.workOrderOverviewSubtitle,
      initiallyExpanded: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MetaGrid(
            items: [
              _MetaItem(
                label: l10n.workOrderCustomer,
                value: workOrder.customerName ??
                    AppLocalizations.of(context).valueNotSet,
                icon: Icons.business_outlined,
              ),
              _MetaItem(
                label: l10n.workOrderLocation,
                value: workOrder.locationDisplay,
                icon: Icons.place_outlined,
              ),
            ],
          ),
          if (workOrder.customerPhoneNumbers.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _CustomerPhonesSection(phones: workOrder.customerPhoneNumbers),
          ],
          if (workOrder.hasOpenableLocationUrl) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final opened = await WorkOrderLocationLauncher.openUrl(
                    workOrder.effectiveLocationUrl,
                  );
                  if (!opened && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.workOrderCouldNotOpenMaps)),
                    );
                  }
                },
                icon: const Icon(Icons.open_in_new, size: 18),
                label: Text(l10n.workOrderOpenLocation),
              ),
            ),
          ],
          if (hasCoords) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final opened = await OvertimeMapsLauncher.openCoordinates(
                    latitude: address!.lat!,
                    longitude: address.lng!,
                    label: workOrder.customerName ?? workOrder.locationDisplay,
                  );
                  if (!opened && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.workOrderCouldNotOpenMaps)),
                    );
                  }
                },
                icon: const Icon(Icons.map_outlined, size: 18),
                label: Text(l10n.workOrderViewOnMap),
              ),
            ),
          ],
          if (workOrder.description != null &&
              workOrder.description!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _LabeledBody(
              label: l10n.workOrderWorkDescription,
              value: workOrder.description!,
            ),
          ],
          if (workOrder.notes != null &&
              workOrder.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _LabeledBody(
              label: l10n.workOrderInternalNotes,
              value: workOrder.notes!,
            ),
          ],
          if (workOrder.voiceNote?.url != null &&
              workOrder.voiceNote!.url.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.workOrderVoiceNote,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            OvertimeVoiceNoteSection(
              remoteUrl: workOrder.voiceNote!.url,
              durationSeconds: workOrder.voiceNote!.duration,
              readOnly: true,
              enabled: true,
            ),
          ],
          if (includeAttachments && imageAttachments.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            WorkOrderPhotoGallery(
              title: l10n.workOrderAttachments,
              heroPrefix: 'wo-attach',
              photos: imageAttachments,
            ),
          ],
          if (includeAttachments && fileAttachments.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            ...fileAttachments.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const Icon(Icons.attach_file),
                title: Text(
                  item.fileName ?? l10n.workOrderDocument,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CustomerPhonesSection extends StatelessWidget {
  const _CustomerPhonesSection({required this.phones});

  final List<String> phones;

  Future<void> _call(BuildContext context, String phone) async {
    final l10n = AppLocalizations.of(context);
    final opened = await WorkOrderPhoneLauncher.openDialer(phone);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.workOrderCouldNotOpenDialer)),
      );
    }
  }

  Future<void> _onCallPressed(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    if (phones.length == 1) {
      await _call(context, phones.first);
      return;
    }

    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  l10n.workOrderChooseCustomerNumber,
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
              ),
              ...phones.map(
                (phone) => ListTile(
                  leading: const Icon(Icons.phone_outlined),
                  title: Text(phone),
                  onTap: () => Navigator.of(sheetContext).pop(phone),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selected != null && context.mounted) {
      await _call(context, selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.workOrderCustomerPhoneNumbers,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        ...phones.map(
          (phone) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text(
              phone,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FilledButton.tonalIcon(
            onPressed: () => _onCallPressed(context),
            icon: const Icon(Icons.call_outlined, size: 18),
            label: Text(l10n.workOrderCall),
          ),
        ),
      ],
    );
  }
}

class _AttachmentsSection extends StatelessWidget {
  const _AttachmentsSection({required this.workOrder});

  final WorkOrder workOrder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final imageAttachments =
        workOrder.attachments.where((a) => a.isImage).toList();
    final fileAttachments =
        workOrder.attachments.where((a) => !a.isImage).toList();

    if (imageAttachments.isEmpty && fileAttachments.isEmpty) {
      return WorkOrderSectionCard(
        icon: Icons.attach_file_outlined,
        title: l10n.workOrderAttachments,
        initiallyExpanded: true,
        child: Text(
          l10n.valueNotSet,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
    }

    return WorkOrderSectionCard(
      icon: Icons.attach_file_outlined,
      title: l10n.workOrderAttachments,
      initiallyExpanded: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (imageAttachments.isNotEmpty)
            WorkOrderPhotoGallery(
              title: l10n.workOrderAttachments,
              heroPrefix: 'wo-attach-side',
              photos: imageAttachments,
            ),
          if (fileAttachments.isNotEmpty) ...[
            if (imageAttachments.isNotEmpty)
              const SizedBox(height: AppSpacing.sm),
            ...fileAttachments.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const Icon(Icons.attach_file),
                title: Text(
                  item.fileName ?? l10n.workOrderDocument,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BeforeWorkSection extends StatelessWidget {
  const _BeforeWorkSection({
    required this.workOrder,
    required this.state,
    required this.canEdit,
  });

  final WorkOrder workOrder;
  final WorkOrderDetailState state;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasNotes = workOrder.beforeNotes != null &&
        workOrder.beforeNotes!.trim().isNotEmpty;

    return WorkOrderSectionCard(
      icon: Icons.photo_camera_front_outlined,
      title: l10n.workOrderBeforeWork,
      subtitle: canEdit
          ? l10n.workOrderBeforeWorkSubtitleEdit
          : l10n.workOrderBeforeWorkSubtitleView,
      initiallyExpanded: canEdit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WorkOrderPhotoGallery(
            title: l10n.workOrderBeforePhotos,
            heroPrefix: 'wo-before',
            photos: workOrder.beforePhotos,
            isBusy: state.isBusy,
            canRemove: canEdit,
            onAdd: canEdit
                ? () => pickAndUploadPhotos(
                      context,
                      category: WorkOrderPhotoCategory.before,
                    )
                : null,
            onRemove: canEdit
                ? (photo) => context.read<WorkOrderDetailCubit>().removePhoto(
                      category: WorkOrderPhotoCategory.before,
                      url: photo.url,
                    )
                : null,
          ),
          if (hasNotes) ...[
            const SizedBox(height: AppSpacing.md),
            _SavedNoteBlock(
              label: l10n.workOrderSavedBeforeNotes,
              text: workOrder.beforeNotes!,
            ),
          ],
          if (canEdit) ...[
            const SizedBox(height: AppSpacing.sm),
            _ExpandableNoteField(
              key: ValueKey('before-notes-${workOrder.beforeNotes}'),
              title: l10n.workOrderBeforeNotes,
              hint: l10n.workOrderBeforeNotesHint,
              initialText: workOrder.beforeNotes ?? '',
              isSaving: state.action == WorkOrderAction.beforeWork,
              enabled: !state.isBusy,
              onSave: (text) =>
                  context.read<WorkOrderDetailCubit>().saveBeforeWork(
                        beforeNotes: text.isEmpty ? null : text,
                      ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InProgressSection extends StatelessWidget {
  const _InProgressSection({
    required this.workOrder,
    required this.state,
    required this.canEdit,
  });

  final WorkOrder workOrder;
  final WorkOrderDetailState state;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dateFormat = AppFormatters.mediumDateTime(context);

    return WorkOrderSectionCard(
      icon: Icons.engineering_outlined,
      title: l10n.workOrderInProgress,
      subtitle: l10n.workOrderInProgressSubtitle,
      initiallyExpanded: canEdit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WorkOrderPhotoGallery(
            title: l10n.workOrderProgressPhotos,
            heroPrefix: 'wo-progress',
            photos: workOrder.progressPhotos,
            isBusy: state.isBusy,
            canRemove: canEdit,
            onAdd: canEdit
                ? () => pickAndUploadPhotos(
                      context,
                      category: WorkOrderPhotoCategory.progress,
                    )
                : null,
            onRemove: canEdit
                ? (photo) => context.read<WorkOrderDetailCubit>().removePhoto(
                      category: WorkOrderPhotoCategory.progress,
                      url: photo.url,
                    )
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.workOrderProgressNotes,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (workOrder.progressNotes.isEmpty)
            Text(
              l10n.workOrderNoProgressNotes,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            )
          else
            ...workOrder.progressNotes.map(
              (note) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _SavedNoteBlock(
                  label: [
                    if (note.createdByName != null) note.createdByName!,
                    if (note.createdAt != null)
                      dateFormat.format(note.createdAt!.toLocal()),
                  ].join(' · '),
                  text: note.text,
                ),
              ),
            ),
          if (canEdit) ...[
            const SizedBox(height: AppSpacing.xs),
            _ExpandableNoteField(
              key: ValueKey(
                'progress-notes-${workOrder.progressNotes.length}',
              ),
              title: l10n.workOrderAddProgressNote,
              hint: l10n.workOrderProgressNoteHint,
              initialText: '',
              clearOnSave: true,
              isSaving: state.action == WorkOrderAction.progressNote,
              enabled: !state.isBusy,
              onSave: (text) async {
                if (text.isEmpty) {
                  return;
                }
                await context.read<WorkOrderDetailCubit>().addProgressNote(text);
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _CompleteWorkSection extends StatelessWidget {
  const _CompleteWorkSection({
    required this.workOrder,
    required this.state,
    required this.canEdit,
    this.completionNotesDraft = '',
    this.onCompletionNotesChanged,
  });

  final WorkOrder workOrder;
  final WorkOrderDetailState state;
  final bool canEdit;
  final String completionNotesDraft;
  final ValueChanged<String>? onCompletionNotesChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return WorkOrderSectionCard(
      icon: Icons.task_alt_outlined,
      title: l10n.workOrderCompleteWork,
      subtitle: canEdit
          ? l10n.workOrderCompleteWorkSubtitleEdit
          : l10n.workOrderCompleteWorkSubtitleView,
      initiallyExpanded: canEdit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (workOrder.completionNotes != null &&
              workOrder.completionNotes!.trim().isNotEmpty) ...[
            _SavedNoteBlock(
              label: l10n.workOrderCompletionNotes,
              text: workOrder.completionNotes!,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          WorkOrderPhotoGallery(
            title: l10n.workOrderAfterPhotos,
            heroPrefix: 'wo-after',
            photos: workOrder.afterPhotos,
            isBusy: state.isBusy,
            canRemove: canEdit,
            onAdd: canEdit
                ? () => pickAndUploadPhotos(
                      context,
                      category: WorkOrderPhotoCategory.after,
                    )
                : null,
            onRemove: canEdit
                ? (photo) => context.read<WorkOrderDetailCubit>().removePhoto(
                      category: WorkOrderPhotoCategory.after,
                      url: photo.url,
                    )
                : null,
          ),
          if (canEdit && workOrder.afterPhotos.isEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.workOrderAfterPhotoRequired,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ],
          if (canEdit && onCompletionNotesChanged != null) ...[
            const SizedBox(height: AppSpacing.md),
            _ExpandableNoteField(
              key: const ValueKey('completion-notes-field'),
              title: l10n.workOrderCompletionNotes,
              hint: l10n.workOrderCompletionNotesHint,
              initialText: completionNotesDraft,
              isSaving: false,
              enabled: !state.isBusy,
              showSaveButton: false,
              onSave: (text) async {
                onCompletionNotesChanged!(text);
              },
              onChanged: onCompletionNotesChanged,
            ),
          ],
        ],
      ),
    );
  }
}

class _CapturedLocationsSection extends StatelessWidget {
  const _CapturedLocationsSection({required this.workOrder});

  final WorkOrder workOrder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dateFormat = AppFormatters.mediumDateTime(context);

    return WorkOrderSectionCard(
      icon: Icons.my_location_outlined,
      title: l10n.workOrderCapturedLocations,
      subtitle: l10n.workOrderCapturedLocationsSubtitle,
      initiallyExpanded: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (workOrder.startedLocation != null)
            _LocationBlock(
              title: l10n.workOrderLocationStarted,
              location: workOrder.startedLocation!,
              dateFormat: dateFormat,
              openMapLabel: l10n.workOrderOpenMap,
            ),
          if (workOrder.completedLocation != null) ...[
            if (workOrder.startedLocation != null)
              const SizedBox(height: AppSpacing.md),
            _LocationBlock(
              title: l10n.workOrderLocationCompleted,
              location: workOrder.completedLocation!,
              dateFormat: dateFormat,
              openMapLabel: l10n.workOrderOpenMap,
            ),
          ],
        ],
      ),
    );
  }
}

class _LocationBlock extends StatelessWidget {
  const _LocationBlock({
    required this.title,
    required this.location,
    required this.dateFormat,
    required this.openMapLabel,
  });

  final String title;
  final WorkOrderFieldLocation location;
  final DateFormat dateFormat;
  final String openMapLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            location.address?.trim().isNotEmpty == true
                ? location.address!
                : '${location.latitude.toStringAsFixed(5)}, '
                    '${location.longitude.toStringAsFixed(5)}',
          ),
          if (location.recordedAt != null)
            Text(
              dateFormat.format(location.recordedAt!.toLocal()),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () => OvertimeMapsLauncher.openCoordinates(
                latitude: location.latitude,
                longitude: location.longitude,
                label: title,
              ),
              icon: const Icon(Icons.map_outlined, size: 18),
              label: Text(openMapLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaGrid extends StatelessWidget {
  const _MetaGrid({required this.items});

  final List<_MetaItem> items;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 700;
    if (!isWide) {
      return Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            _MetaTile(item: items[i]),
          ],
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(child: _MetaTile(item: items[i])),
        ],
      ],
    );
  }
}

class _MetaItem {
  const _MetaItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

class _MetaTile extends StatelessWidget {
  const _MetaTile({required this.item});

  final _MetaItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, size: 20, color: scheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledBody extends StatelessWidget {
  const _LabeledBody({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _SavedNoteBlock extends StatelessWidget {
  const _SavedNoteBlock({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 4),
          Text(text),
        ],
      ),
    );
  }
}

/// Expandable inline note editor. Owns its [TextEditingController] for life.
class _ExpandableNoteField extends StatefulWidget {
  const _ExpandableNoteField({
    super.key,
    required this.title,
    required this.hint,
    required this.initialText,
    required this.onSave,
    required this.isSaving,
    required this.enabled,
    this.clearOnSave = false,
    this.showSaveButton = true,
    this.onChanged,
  });

  final String title;
  final String hint;
  final String initialText;
  final Future<void> Function(String text) onSave;
  final bool isSaving;
  final bool enabled;
  final bool clearOnSave;
  final bool showSaveButton;
  final ValueChanged<String>? onChanged;

  @override
  State<_ExpandableNoteField> createState() => _ExpandableNoteFieldState();
}

class _ExpandableNoteFieldState extends State<_ExpandableNoteField>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _controller;
  late final AnimationController _anim;
  late final Animation<double> _expand;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _controller.addListener(_emitChanged);
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _expand = CurvedAnimation(parent: _anim, curve: Curves.easeInOutCubic);
  }

  void _emitChanged() {
    widget.onChanged?.call(_controller.text);
  }

  @override
  void dispose() {
    _controller.removeListener(_emitChanged);
    _anim.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _open = !_open);
    if (_open) {
      _anim.forward();
    } else {
      _anim.reverse();
    }
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    await widget.onSave(text);
    if (!mounted) {
      return;
    }
    if (widget.clearOnSave) {
      _controller.clear();
    }
    if (_open) {
      _toggle();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: widget.enabled ? _toggle : null,
            icon: AnimatedRotation(
              turns: _open ? 0.5 : 0,
              duration: const Duration(milliseconds: 220),
              child: const Icon(Icons.expand_more),
            ),
            label: Text(
              _open
                  ? l10n.workOrderHideNote(widget.title)
                  : widget.title,
            ),
          ),
        ),
        SizeTransition(
          sizeFactor: _expand,
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _controller,
                  enabled: widget.enabled && !widget.isSaving,
                  minLines: 2,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                if (widget.showSaveButton) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: FilledButton.tonalIcon(
                      onPressed:
                          !widget.enabled || widget.isSaving ? null : _save,
                      icon: widget.isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined, size: 18),
                      label: Text(l10n.workOrderSaveNotes),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> pickAndUploadPhotos(
  BuildContext context, {
  required WorkOrderPhotoCategory category,
}) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      final l10n = AppLocalizations.of(sheetContext);
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.workOrderTakePhoto),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.workOrderChooseFromGallery),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
          ],
        ),
      );
    },
  );
  if (source == null || !context.mounted) {
    return;
  }

  final picker = ImagePicker();
  final file = await picker.pickImage(source: source, imageQuality: 85);
  if (file == null || !context.mounted) {
    return;
  }
  final bytes = await file.readAsBytes();
  if (!context.mounted) {
    return;
  }

  final name = file.name.toLowerCase();
  final mime = name.endsWith('.png')
      ? 'image/png'
      : name.endsWith('.webp')
          ? 'image/webp'
          : 'image/jpeg';
  final input = WorkOrderAttachmentInput(
    bytes: bytes,
    fileName: file.name,
    mimeType: mime,
  );
  final cubit = context.read<WorkOrderDetailCubit>();

  switch (category) {
    case WorkOrderPhotoCategory.before:
      await cubit.saveBeforeWork(photos: [input]);
    case WorkOrderPhotoCategory.progress:
      await cubit.addProgressPhotos([input]);
    case WorkOrderPhotoCategory.after:
      await cubit.addAfterPhotos([input]);
  }
}

Future<void> completeWork(
  BuildContext context, {
  String? completionNotes,
}) async {
  final l10n = AppLocalizations.of(context);
  final notes = completionNotes ??
      await promptWorkOrderText(
        context,
        title: l10n.workOrderCompleteWork,
        hint: l10n.workOrderCompletionNotesOptional,
        confirmLabel: l10n.confirm,
        cancelLabel: l10n.close,
      );
  // Dialog cancel returns null only when we prompted; an explicit empty draft is ''.
  if (completionNotes == null && notes == null) {
    return;
  }
  if (!context.mounted) {
    return;
  }
  final trimmed = (notes ?? '').trim();
  await context.read<WorkOrderDetailCubit>().complete(
        completionNotes: trimmed.isEmpty ? null : trimmed,
      );
}
