import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/core/widgets/app_loader.dart';
import 'package:mobile/core/widgets/app_refresh_bar.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/features/assets/domain/entities/asset.dart';
import 'package:mobile/features/assets/presentation/cubit/assets_dashboard_cubit.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/features/dashboard/presentation/widgets/dashboard_quick_card.dart';

/// Assets dashboard — replaces the previous coming-soon placeholder.
class AssetsPage extends StatefulWidget {
  const AssetsPage({super.key});

  @override
  State<AssetsPage> createState() => _AssetsPageState();
}

class _AssetsPageState extends State<AssetsPage> {
  late final AssetsDashboardCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<AssetsDashboardCubit>()..load();
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
      child: const _AssetsDashboardView(),
    );
  }
}

class _AssetsDashboardView extends StatelessWidget {
  const _AssetsDashboardView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isPhone = width < 600;
    final canCreate = context.select(
      (AuthCubit cubit) =>
          cubit.state.user?.permissionChecker.canCreateAssets() == true,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.assets)),
      body: BlocBuilder<AssetsDashboardCubit, AssetsDashboardState>(
        buildWhen: (previous, current) =>
            previous.status != current.status ||
            previous.dashboard != current.dashboard ||
            previous.isRefreshing != current.isRefreshing ||
            previous.message != current.message,
        builder: (context, state) {
          if ((state.status == AssetsDashboardStatus.loading ||
                  state.status == AssetsDashboardStatus.initial) &&
              state.dashboard == null) {
            return AppLoader(message: l10n.assetsLoading);
          }
          if (state.status == AssetsDashboardStatus.failure &&
              state.dashboard == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      state.message ?? l10n.assetsLoadFailed,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton(
                      onPressed: () =>
                          context.read<AssetsDashboardCubit>().load(),
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            );
          }

          final dashboard = state.dashboard;
          final cols = isPhone ? 2 : 3;

          return Column(
            children: [
              AppRefreshBar(visible: state.isRefreshing),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () =>
                      context.read<AssetsDashboardCubit>().load(),
                  child: ListView(
                    padding: AppScrollPadding.resolve(
                      context,
                      base: EdgeInsets.all(
                        isPhone ? AppSpacing.md : AppSpacing.lg,
                      ),
                      chrome: AppBottomChrome.system,
                    ),
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final itemWidth = (constraints.maxWidth -
                                  (AppSpacing.md * (cols - 1))) /
                              cols;
                          return Wrap(
                            spacing: AppSpacing.md,
                            runSpacing: AppSpacing.md,
                            children: [
                              _stat(
                                itemWidth,
                                isPhone,
                                l10n.assetsTotal,
                                '${dashboard?.totalAssets ?? 0}',
                                Icons.precision_manufacturing_outlined,
                                () => context.push(RoutePaths.assetsList),
                              ),
                              _stat(
                                itemWidth,
                                isPhone,
                                l10n.assetsStatusActive,
                                '${dashboard?.active ?? 0}',
                                Icons.check_circle_outline,
                                () => context.push(
                                  RoutePaths.assetsList,
                                  extra: AssetStatus.active.apiValue,
                                ),
                              ),
                              _stat(
                                itemWidth,
                                isPhone,
                                l10n.assetsStatusMaintenance,
                                '${dashboard?.underMaintenance ?? 0}',
                                Icons.build_outlined,
                                () => context.push(
                                  RoutePaths.assetsList,
                                  extra: AssetStatus.maintenance.apiValue,
                                ),
                              ),
                              _stat(
                                itemWidth,
                                isPhone,
                                l10n.assetsStatusRetired,
                                '${dashboard?.retired ?? 0}',
                                Icons.archive_outlined,
                                () => context.push(
                                  RoutePaths.assetsList,
                                  extra: AssetStatus.retired.apiValue,
                                ),
                              ),
                              _stat(
                                itemWidth,
                                isPhone,
                                l10n.assetsWarrantyExpiringSoon,
                                '${dashboard?.warrantyExpiringSoon ?? 0}',
                                Icons.event_busy_outlined,
                                () => context.push(RoutePaths.assetsList),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          FilledButton.tonalIcon(
                            onPressed: () =>
                                context.push(RoutePaths.assetsList),
                            icon: const Icon(Icons.list_alt),
                            label: Text(l10n.assetsList),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: () =>
                                context.push(RoutePaths.assetsCategories),
                            icon: const Icon(Icons.category_outlined),
                            label: Text(l10n.assetsCategories),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: () =>
                                context.push(RoutePaths.assetsHistory),
                            icon: const Icon(Icons.history),
                            label: Text(l10n.assetsHistory),
                          ),
                          if (canCreate)
                            FilledButton.icon(
                              onPressed: () =>
                                  context.push(RoutePaths.assetsForm),
                              icon: const Icon(Icons.add),
                              label: Text(l10n.assetsCreate),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _stat(
    double width,
    bool compact,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: width,
      child: DashboardQuickCard(
        title: title,
        subtitle: subtitle,
        icon: icon,
        compact: compact,
        onTap: onTap,
      ),
    );
  }
}
