import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/app_formatters.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/core/widgets/app_cached_network_image.dart';
import 'package:mobile/core/widgets/app_loader.dart';
import 'package:mobile/core/widgets/app_refresh_bar.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/features/inventory/domain/entities/spare_part.dart';
import 'package:mobile/features/inventory/presentation/cubit/spare_parts_list_cubit.dart';
import 'package:mobile/features/inventory/presentation/widgets/stock_status_badge.dart';

class SparePartsPage extends StatefulWidget {
  const SparePartsPage({super.key, this.initialStockStatus});

  final StockStatus? initialStockStatus;

  @override
  State<SparePartsPage> createState() => _SparePartsPageState();
}

class _SparePartsPageState extends State<SparePartsPage> {
  late final SparePartsListCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<SparePartsListCubit>()
      ..loadFirstPage(stockStatus: widget.initialStockStatus);
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
      child: const _SparePartsView(),
    );
  }
}

class _SparePartsView extends StatefulWidget {
  const _SparePartsView();

  @override
  State<_SparePartsView> createState() => _SparePartsViewState();
}

class _SparePartsViewState extends State<_SparePartsView> {
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
      context.read<SparePartsListCubit>().loadMore();
    }
  }

  String _formatQty(double value) {
    return AppFormatters.formatDecimalOrInt(context, value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canCreate = context.select(
      (AuthCubit cubit) =>
          cubit.state.user?.permissionChecker.canCreateInventory() == true,
    );
    return Scaffold(
      appBar: AppBar(title: Text(l10n.inventorySpareParts)),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () async {
                final changed =
                    await context.push<bool>(RoutePaths.inventoryPartForm);
                if (changed == true && context.mounted) {
                  await context.read<SparePartsListCubit>().loadFirstPage();
                }
              },
              icon: const Icon(Icons.add),
              label: Text(l10n.inventoryCreatePart),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.inventorySearchParts,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: () {
                    _searchController.clear();
                    context.read<SparePartsListCubit>().search('');
                  },
                  icon: const Icon(Icons.clear),
                ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (value) =>
                  context.read<SparePartsListCubit>().search(value),
            ),
          ),
          BlocBuilder<SparePartsListCubit, SparePartsListState>(
            buildWhen: (previous, current) =>
                previous.stockStatus != current.stockStatus,
            builder: (context, state) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  children: [
                    FilterChip(
                      label: Text(l10n.inventoryFilterAll),
                      selected: state.stockStatus == null,
                      onSelected: (_) =>
                          context.read<SparePartsListCubit>().setFilter(null),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    FilterChip(
                      label: Text(l10n.inventoryInStock),
                      selected: state.stockStatus == StockStatus.inStock,
                      onSelected: (_) => context
                          .read<SparePartsListCubit>()
                          .setFilter(StockStatus.inStock),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    FilterChip(
                      label: Text(l10n.inventoryLowStock),
                      selected: state.stockStatus == StockStatus.lowStock,
                      onSelected: (_) => context
                          .read<SparePartsListCubit>()
                          .setFilter(StockStatus.lowStock),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    FilterChip(
                      label: Text(l10n.inventoryOutOfStock),
                      selected: state.stockStatus == StockStatus.outOfStock,
                      onSelected: (_) => context
                          .read<SparePartsListCubit>()
                          .setFilter(StockStatus.outOfStock),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: BlocBuilder<SparePartsListCubit, SparePartsListState>(
              buildWhen: (previous, current) =>
                  previous.status != current.status ||
                  previous.items != current.items ||
                  previous.hasMore != current.hasMore ||
                  previous.isRefreshing != current.isRefreshing ||
                  previous.message != current.message,
              builder: (context, state) {
                if ((state.status == SparePartsListStatus.loading ||
                        state.status == SparePartsListStatus.initial) &&
                    state.items.isEmpty) {
                  return const AppLoader();
                }
                if (state.status == SparePartsListStatus.failure &&
                    state.items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(state.message ?? l10n.inventoryLoadFailed),
                        const SizedBox(height: AppSpacing.md),
                        FilledButton(
                          onPressed: () => context
                              .read<SparePartsListCubit>()
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
                        child: Center(child: Text(l10n.inventoryPartsEmpty)),
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
                            .read<SparePartsListCubit>()
                            .loadFirstPage(),
                        child: ListView.separated(
                          controller: _scrollController,
                          padding: AppScrollPadding.resolve(
                            context,
                            base: const EdgeInsets.fromLTRB(
                              AppSpacing.md,
                              AppSpacing.sm,
                              AppSpacing.md,
                              0,
                            ),
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
                            final part = state.items[index];
                            return Card(
                              child: ListTile(
                                leading: part.image?.url != null
                                    ? AppCachedNetworkImage(
                                        imageUrl: part.image!.url,
                                        width: 48,
                                        height: 48,
                                        borderRadius: BorderRadius.circular(8),
                                        memCacheWidth: 96,
                                        memCacheHeight: 96,
                                      )
                                    : CircleAvatar(
                                        child: Text(
                                          part.partNumber.isNotEmpty
                                              ? part.partNumber[0]
                                              : '?',
                                        ),
                                      ),
                                title: Text(
                                  part.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  '${part.partNumber} · ${_formatQty(part.currentQuantity)} ${part.unit}',
                                ),
                                trailing: StockStatusBadge(
                                  status: part.stockStatus,
                                ),
                                onTap: () async {
                                  final changed = await context.push<bool>(
                                    RoutePaths.inventoryPartDetail(part.id),
                                  );
                                  if (changed == true && context.mounted) {
                                    await context
                                        .read<SparePartsListCubit>()
                                        .loadFirstPage();
                                  }
                                },
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
