import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_app_message.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/core/widgets/app_cached_network_image.dart';
import 'package:mobile/core/widgets/app_loader.dart';
import 'package:mobile/core/widgets/app_refresh_bar.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/features/assets/domain/entities/asset.dart';
import 'package:mobile/features/assets/presentation/cubit/assets_list_cubit.dart';
import 'package:mobile/features/assets/presentation/widgets/asset_status_badge.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';

class AssetsListPage extends StatefulWidget {
  const AssetsListPage({super.key, this.initialStatus});

  final AssetStatus? initialStatus;

  @override
  State<AssetsListPage> createState() => _AssetsListPageState();
}

class _AssetsListPageState extends State<AssetsListPage> {
  late final AssetsListCubit _cubit;
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cubit = getIt<AssetsListCubit>()
      ..loadFirstPage(status: widget.initialStatus);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    _cubit.close();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _cubit.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canCreate = context.select(
      (AuthCubit c) => c.state.user?.permissionChecker.canCreateAssets() == true,
    );

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.assetsList)),
        floatingActionButton: canCreate
            ? FloatingActionButton.extended(
                onPressed: () async {
                  final changed =
                      await context.push<bool>(RoutePaths.assetsForm);
                  if (changed == true && mounted) {
                    await _cubit.loadFirstPage();
                  }
                },
                icon: const Icon(Icons.add),
                label: Text(l10n.assetsCreate),
              )
            : null,
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: l10n.assetsSearchHint,
                  prefixIcon: const Icon(Icons.search),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: _cubit.search,
              ),
            ),
            BlocBuilder<AssetsListCubit, AssetsListState>(
              buildWhen: (p, c) => p.filterStatus != c.filterStatus,
              builder: (context, state) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Row(
                    children: [
                      FilterChip(
                        label: Text(l10n.assetsFilterAll),
                        selected: state.filterStatus == null,
                        onSelected: (_) => _cubit.setFilter(null),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      ...AssetStatus.values.map(
                        (status) => Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: FilterChip(
                            label: Text(switch (status) {
                              AssetStatus.active => l10n.assetsStatusActive,
                              AssetStatus.maintenance =>
                                l10n.assetsStatusMaintenance,
                              AssetStatus.offline => l10n.assetsStatusOffline,
                              AssetStatus.retired => l10n.assetsStatusRetired,
                            }),
                            selected: state.filterStatus == status,
                            onSelected: (_) => _cubit.setFilter(status),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: BlocBuilder<AssetsListCubit, AssetsListState>(
                buildWhen: (previous, current) =>
                    previous.status != current.status ||
                    previous.items != current.items ||
                    previous.hasMore != current.hasMore ||
                    previous.isRefreshing != current.isRefreshing ||
                    previous.message != current.message,
                builder: (context, state) {
                  if ((state.status == AssetsListStatus.loading ||
                          state.status == AssetsListStatus.initial) &&
                      state.items.isEmpty) {
                    return AppLoader(message: l10n.assetsLoading);
                  }
                  if (state.status == AssetsListStatus.failure &&
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
                            onPressed: () => _cubit.loadFirstPage(),
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
                          child: Center(child: Text(l10n.assetsEmpty)),
                        ),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      AppRefreshBar(visible: state.isRefreshing),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () => _cubit.loadFirstPage(),
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
                              final asset = state.items[index];
                              return Card(
                                child: ListTile(
                                  leading: asset.image?.url != null
                                      ? AppCachedNetworkImage(
                                          imageUrl: asset.image!.url,
                                          width: 48,
                                          height: 48,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          memCacheWidth: 96,
                                          memCacheHeight: 96,
                                        )
                                      : CircleAvatar(
                                          child: Text(
                                            asset.assetNumber.isNotEmpty
                                                ? asset.assetNumber[0]
                                                : '?',
                                          ),
                                        ),
                                  title: Text(asset.name),
                                  subtitle: Text(
                                    [
                                      asset.assetNumber,
                                      if (asset.category?.name != null)
                                        asset.category!.name!,
                                    ].join(' · '),
                                  ),
                                  trailing: AssetStatusBadge(
                                    status: asset.status,
                                  ),
                                  onTap: () async {
                                    final changed = await context.push<bool>(
                                      RoutePaths.assetDetail(asset.id),
                                    );
                                    if (changed == true && mounted) {
                                      await _cubit.loadFirstPage();
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
      ),
    );
  }
}
