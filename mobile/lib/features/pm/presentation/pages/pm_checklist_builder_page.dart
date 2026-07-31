import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_app_message.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/core/widgets/app_loader.dart';
import 'package:mobile/core/widgets/app_refresh_bar.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/features/pm/domain/entities/pm_entities.dart';
import 'package:mobile/features/pm/presentation/cubit/pm_plan_detail_form_checklist_cubits.dart';

class PmChecklistBuilderPage extends StatefulWidget {
  const PmChecklistBuilderPage({super.key, required this.planId});

  final String planId;

  @override
  State<PmChecklistBuilderPage> createState() => _PmChecklistBuilderPageState();
}

class _PmChecklistBuilderPageState extends State<PmChecklistBuilderPage> {
  late final PmChecklistBuilderCubit _cubit;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<PmChecklistBuilderCubit>(param1: widget.planId)..load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _editItem({int? index, PmChecklistItem? existing}) async {
    final l10n = AppLocalizations.of(context);
    final titleController =
        TextEditingController(text: existing?.title ?? '');
    final descriptionController =
        TextEditingController(text: existing?.description ?? '');
    var requiresPassFail = existing?.requiresPassFail ?? true;
    var requiresNotes = existing?.requiresNotes ?? false;
    var photoRequired = existing?.photoRequired ?? false;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(index == null
                  ? l10n.pmAddChecklistItem
                  : l10n.pmEditChecklistItem),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration:
                          InputDecoration(labelText: l10n.pmChecklistItemTitle),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: l10n.pmChecklistItemDescription,
                      ),
                      maxLines: 2,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.pmRequiresPassFail),
                      value: requiresPassFail,
                      onChanged: (v) =>
                          setDialogState(() => requiresPassFail = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.pmRequiresNotes),
                      value: requiresNotes,
                      onChanged: (v) =>
                          setDialogState(() => requiresNotes = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.pmPhotoRequired),
                      value: photoRequired,
                      onChanged: (v) =>
                          setDialogState(() => photoRequired = v),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(l10n.pmCancel),
                ),
                FilledButton(
                  onPressed: () {
                    if (titleController.text.trim().isEmpty) return;
                    Navigator.pop(dialogContext, true);
                  },
                  child: Text(l10n.pmSave),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true) {
      final item = PmChecklistItem(
        id: existing?.id,
        title: titleController.text.trim(),
        description: descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
        requiresPassFail: requiresPassFail,
        requiresNotes: requiresNotes,
        photoRequired: photoRequired,
        sortOrder: index ?? _cubit.state.items.length,
      );
      if (index == null) {
        _cubit.addItem(item);
      } else {
        _cubit.updateItem(index, item);
      }
    }

    titleController.dispose();
    descriptionController.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final result = await _cubit.save();
    if (!mounted) return;
    switch (result) {
      case Success():
        _changed = true;
        Navigator.of(context).pop(true);
      case Failure(message: final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizeAppMessage(l10n, message))),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: BlocProvider.value(
        value: _cubit,
        child: Scaffold(
          appBar: AppBar(
            title: Text(l10n.pmChecklistBuilder),
            actions: [
              IconButton(
                icon: const Icon(Icons.save_outlined),
                onPressed: _save,
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _editItem(),
            icon: const Icon(Icons.add),
            label: Text(l10n.pmAddChecklistItem),
          ),
          body: BlocBuilder<PmChecklistBuilderCubit, PmChecklistBuilderState>(
            builder: (context, state) {
              if ((state.status == PmChecklistBuilderStatus.loading ||
                      state.status == PmChecklistBuilderStatus.initial) &&
                  state.plan == null &&
                  state.items.isEmpty) {
                return AppLoader(message: l10n.pmLoading);
              }
              if (state.status == PmChecklistBuilderStatus.failure &&
                  state.plan == null &&
                  state.items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(state.message ?? l10n.pmLoadFailed),
                      FilledButton(
                        onPressed: _cubit.load,
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                );
              }

              if (state.items.isEmpty) {
                return Column(
                  children: [
                    AppRefreshBar(visible: state.isRefreshing),
                    Expanded(child: Center(child: Text(l10n.pmChecklistEmpty))),
                  ],
                );
              }

              final saving = state.status == PmChecklistBuilderStatus.saving;

              return Column(
                children: [
                  AppRefreshBar(visible: state.isRefreshing),
                  Expanded(
                    child: Stack(
                      children: [
                        ReorderableListView.builder(
                    padding: AppScrollPadding.resolve(
                      context,
                      base: const EdgeInsets.all(AppSpacing.md),
                      chrome: AppBottomChrome.fab,
                    ),
                    itemCount: state.items.length,
                    onReorder: _cubit.reorder,
                    itemBuilder: (context, index) {
                      final item = state.items[index];
                      return Card(
                        key: ValueKey(item.id ?? 'item-$index'),
                        child: ListTile(
                          leading: const Icon(Icons.drag_handle),
                          title: Text(item.title),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (item.description != null &&
                                  item.description!.isNotEmpty)
                                Text(item.description!),
                              Wrap(
                                spacing: AppSpacing.sm,
                                children: [
                                  if (item.requiresPassFail)
                                    Chip(
                                      label: Text(l10n.pmRequiresPassFail),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  if (item.requiresNotes)
                                    Chip(
                                      label: Text(l10n.pmRequiresNotes),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  if (item.photoRequired)
                                    Chip(
                                      label: Text(l10n.pmPhotoRequired),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                ],
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () =>
                                    _editItem(index: index, existing: item),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _cubit.removeItem(index),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  if (saving)
                    const ColoredBox(
                      color: Color(0x33000000),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
