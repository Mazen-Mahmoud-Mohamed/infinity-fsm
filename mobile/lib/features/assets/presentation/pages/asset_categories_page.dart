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
import 'package:mobile/features/assets/domain/entities/asset_category.dart';
import 'package:mobile/features/assets/presentation/cubit/asset_categories_cubit.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';

class AssetCategoriesPage extends StatefulWidget {
  const AssetCategoriesPage({super.key});

  @override
  State<AssetCategoriesPage> createState() => _AssetCategoriesPageState();
}

class _AssetCategoriesPageState extends State<AssetCategoriesPage> {
  late final AssetCategoriesCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<AssetCategoriesCubit>()..loadFirstPage();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _openForm({AssetCategory? category}) async {
    final l10n = AppLocalizations.of(context);
    final nameController = TextEditingController(text: category?.name ?? '');
    final codeController = TextEditingController(text: category?.code ?? '');
    final descriptionController =
        TextEditingController(text: category?.description ?? '');
    final iconController = TextEditingController(text: category?.icon ?? '');
    var isActive = category?.isActive ?? true;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                category == null
                    ? l10n.assetsCreateCategory
                    : l10n.assetsEditCategory,
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: l10n.assetsName),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: codeController,
                      decoration: InputDecoration(labelText: l10n.assetsCode),
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: iconController,
                      decoration: InputDecoration(labelText: l10n.assetsIcon),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: descriptionController,
                      decoration:
                          InputDecoration(labelText: l10n.assetsDescription),
                      maxLines: 3,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.assetsActive),
                      value: isActive,
                      onChanged: (v) => setDialogState(() => isActive = v),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(l10n.assetsCancel),
                ),
                FilledButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty ||
                        codeController.text.trim().isEmpty) {
                      return;
                    }
                    final input = AssetCategoryUpsertInput(
                      name: nameController.text.trim(),
                      code: codeController.text.trim(),
                      description: descriptionController.text.trim().isEmpty
                          ? null
                          : descriptionController.text.trim(),
                      icon: iconController.text.trim().isEmpty
                          ? null
                          : iconController.text.trim(),
                      isActive: isActive,
                    );
                    final cubit = this.context.read<AssetCategoriesCubit>();
                    final result = category == null
                        ? await cubit.create(input)
                        : await cubit.update(category.id, input);
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
                  child: Text(l10n.assetsSave),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    codeController.dispose();
    descriptionController.dispose();
    iconController.dispose();
    if (saved == true && mounted) {
      await context.read<AssetCategoriesCubit>().loadFirstPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canCreate = context.select(
      (AuthCubit c) => c.state.user?.permissionChecker.canCreateAssets() == true,
    );
    final canUpdate = context.select(
      (AuthCubit c) => c.state.user?.permissionChecker.canUpdateAssets() == true,
    );
    final canDelete = context.select(
      (AuthCubit c) => c.state.user?.permissionChecker.canDeleteAssets() == true,
    );

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.assetsCategories)),
        floatingActionButton: canCreate
            ? FloatingActionButton.extended(
                onPressed: () => _openForm(),
                icon: const Icon(Icons.add),
                label: Text(l10n.assetsCreateCategory),
              )
            : null,
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: TextField(
                decoration: InputDecoration(
                  hintText: l10n.assetsSearchCategories,
                  prefixIcon: const Icon(Icons.search),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (v) =>
                    context.read<AssetCategoriesCubit>().search(v),
              ),
            ),
            Expanded(
              child: BlocBuilder<AssetCategoriesCubit, AssetCategoriesState>(
                buildWhen: (previous, current) =>
                    previous.status != current.status ||
                    previous.items != current.items ||
                    previous.hasMore != current.hasMore ||
                    previous.isRefreshing != current.isRefreshing ||
                    previous.message != current.message,
                builder: (context, state) {
                  if ((state.status == AssetCategoriesStatus.loading ||
                          state.status == AssetCategoriesStatus.initial) &&
                      state.items.isEmpty) {
                    return AppLoader(message: l10n.assetsLoading);
                  }
                  if (state.status == AssetCategoriesStatus.failure &&
                      state.items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                          state.message != null
                              ? localizeAppMessage(l10n, state.message)
                              : l10n.assetsLoadFailed,
                        ),
                          FilledButton(
                            onPressed: () => context
                                .read<AssetCategoriesCubit>()
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
                            child: Text(l10n.assetsCategoriesEmpty),
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
                              .read<AssetCategoriesCubit>()
                              .loadFirstPage(),
                          child: ListView.separated(
                            padding: AppScrollPadding.resolve(
                              context,
                              base: const EdgeInsets.all(AppSpacing.md),
                              chrome: AppBottomChrome.fab,
                            ),
                            itemCount: state.items.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: AppSpacing.sm),
                            itemBuilder: (context, index) {
                              final category = state.items[index];
                              return Card(
                                child: ListTile(
                                  leading: CircleAvatar(
                                    child: Text(
                                      (category.icon ?? category.code)
                                              .isNotEmpty
                                          ? (category.icon ??
                                              category.code)[0]
                                          : '?',
                                    ),
                                  ),
                                  title: Text(category.name),
                                  subtitle: Text(category.code),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (!category.isActive)
                                        Chip(
                                          label: Text(l10n.assetsInactive),
                                        ),
                                      if (canUpdate)
                                        IconButton(
                                          icon:
                                              const Icon(Icons.edit_outlined),
                                          onPressed: () =>
                                              _openForm(category: category),
                                        ),
                                      if (canDelete)
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                          ),
                                          onPressed: () async {
                                            final result = await context
                                                .read<AssetCategoriesCubit>()
                                                .delete(category.id);
                                            if (!context.mounted) return;
                                            switch (result) {
                                              case Success():
                                                await context
                                                    .read<
                                                        AssetCategoriesCubit>()
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
      ),
    );
  }
}
