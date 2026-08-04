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
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/features/inventory/domain/entities/warehouse.dart';
import 'package:mobile/features/inventory/presentation/cubit/warehouses_list_cubit.dart';

class WarehousesPage extends StatefulWidget {
  const WarehousesPage({super.key});

  @override
  State<WarehousesPage> createState() => _WarehousesPageState();
}

class _WarehousesPageState extends State<WarehousesPage> {
  late final WarehousesListCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<WarehousesListCubit>()..loadFirstPage();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: const _WarehousesView(),
    );
  }
}

class _WarehousesView extends StatefulWidget {
  const _WarehousesView();

  @override
  State<_WarehousesView> createState() => _WarehousesViewState();
}

class _WarehousesViewState extends State<_WarehousesView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<WarehousesListCubit>().loadMore();
    }
  }

  Future<void> _openForm({Warehouse? warehouse}) async {
    final l10n = AppLocalizations.of(context);
    final nameController = TextEditingController(text: warehouse?.name ?? '');
    final codeController = TextEditingController(text: warehouse?.code ?? '');
    final addressController =
        TextEditingController(text: warehouse?.address ?? '');
    final descriptionController =
        TextEditingController(text: warehouse?.description ?? '');
    var isActive = warehouse?.isActive ?? true;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                warehouse == null
                    ? l10n.inventoryCreateWarehouse
                    : l10n.inventoryEditWarehouse,
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: l10n.inventoryName),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: codeController,
                      decoration: InputDecoration(labelText: l10n.inventoryCode),
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: addressController,
                      decoration:
                          InputDecoration(labelText: l10n.inventoryAddress),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: descriptionController,
                      decoration:
                          InputDecoration(labelText: l10n.inventoryDescription),
                      maxLines: 3,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.inventoryActive),
                      value: isActive,
                      onChanged: (value) =>
                          setDialogState(() => isActive = value),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(l10n.inventoryCancel),
                ),
                FilledButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty ||
                        codeController.text.trim().isEmpty) {
                      return;
                    }
                    final input = WarehouseUpsertInput(
                      name: nameController.text.trim(),
                      code: codeController.text.trim(),
                      address: addressController.text.trim().isEmpty
                          ? null
                          : addressController.text.trim(),
                      description: descriptionController.text.trim().isEmpty
                          ? null
                          : descriptionController.text.trim(),
                      isActive: isActive,
                    );
                    final cubit = this.context.read<WarehousesListCubit>();
                    final result = warehouse == null
                        ? await cubit.create(input)
                        : await cubit.update(warehouse.id, input);
                    if (!dialogContext.mounted) return;
                    switch (result) {
                      case Success():
                        Navigator.of(dialogContext).pop(true);
                      case Failure(message: final message):
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(content: Text(localizeAppMessage(l10n, message))),
                        );
                    }
                  },
                  child: Text(l10n.inventorySave),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    codeController.dispose();
    addressController.dispose();
    descriptionController.dispose();

    if (saved == true && mounted) {
      await context.read<WarehousesListCubit>().loadFirstPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canCreate = context.select(
      (AuthCubit cubit) =>
          cubit.state.user?.permissionChecker.canCreateInventory() == true,
    );
    final canUpdate = context.select(
      (AuthCubit cubit) =>
          cubit.state.user?.permissionChecker.canUpdateInventory() == true,
    );
    final canDelete = context.select(
      (AuthCubit cubit) =>
          cubit.state.user?.permissionChecker.canDeleteInventory() == true,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.inventoryWarehouses)),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add),
              label: Text(l10n.inventoryCreateWarehouse),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.inventorySearchWarehouses,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: () {
                    _searchController.clear();
                    context.read<WarehousesListCubit>().search('');
                  },
                  icon: const Icon(Icons.clear),
                ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (value) =>
                  context.read<WarehousesListCubit>().search(value),
            ),
          ),
          Expanded(
            child: BlocBuilder<WarehousesListCubit, WarehousesListState>(
              buildWhen: (previous, current) =>
                  previous.status != current.status ||
                  previous.items != current.items ||
                  previous.hasMore != current.hasMore ||
                  previous.isRefreshing != current.isRefreshing ||
                  previous.message != current.message,
              builder: (context, state) {
                if ((state.status == WarehousesListStatus.loading ||
                        state.status == WarehousesListStatus.initial) &&
                    state.items.isEmpty) {
                  return AppLoader(message: l10n.inventoryLoading);
                }
                if (state.status == WarehousesListStatus.failure &&
                    state.items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          state.message != null
                              ? localizeAppMessage(l10n, state.message)
                              : l10n.inventoryLoadFailed,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        FilledButton(
                          onPressed: () => context
                              .read<WarehousesListCubit>()
                              .loadFirstPage(),
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
                      Expanded(
                        child: Center(
                          child: Text(l10n.inventoryWarehousesEmpty),
                        ),
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    AppRefreshBar(visible: state.isRefreshing),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => context
                            .read<WarehousesListCubit>()
                            .loadFirstPage(),
                        child: ListView.separated(
                          controller: _scrollController,
                          padding: AppScrollPadding.resolve(
                            context,
                            base: const EdgeInsets.all(AppSpacing.md),
                            chrome: AppBottomChrome.fab,
                          ),
                          itemCount:
                              state.items.length + (state.hasMore ? 1 : 0),
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            if (index >= state.items.length) {
                              return const Padding(
                                padding: EdgeInsets.all(AppSpacing.md),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            final warehouse = state.items[index];
                            return Card(
                              child: ListTile(
                                title: Text(warehouse.name),
                                subtitle: Text(
                                  [
                                    warehouse.code,
                                    if (warehouse.address != null)
                                      warehouse.address!,
                                  ].join(' · '),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (!warehouse.isActive)
                                      Chip(
                                        label: Text(l10n.inventoryInactive),
                                      ),
                                    if (canUpdate)
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined),
                                        onPressed: () =>
                                            _openForm(warehouse: warehouse),
                                      ),
                                    if (canDelete)
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        onPressed: () async {
                                          final result = await context
                                              .read<WarehousesListCubit>()
                                              .delete(warehouse.id);
                                          if (!context.mounted) return;
                                          switch (result) {
                                            case Success():
                                              await context
                                                  .read<WarehousesListCubit>()
                                                  .loadFirstPage();
                                            case Failure(
                                                message: final message
                                              ):
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(localizeAppMessage(l10n, message)),
                                                ),
                                              );
                                          }
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
