import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/constants/app_breakpoints.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_app_message.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/core/widgets/app_loader.dart';
import 'package:mobile/core/widgets/app_page_frame.dart';
import 'package:mobile/core/widgets/app_refresh_bar.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_empty_state.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_nav_tile.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_page_header.dart';
import 'package:mobile/core/widgets/desktop/app_desktop_stat_grid.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/features/dashboard/presentation/widgets/dashboard_quick_card.dart';
import 'package:mobile/features/inventory/presentation/cubit/inventory_dashboard_cubit.dart';
import 'package:mobile/features/inventory/presentation/widgets/stock_movement_tile.dart';

class InventoryDashboardPage extends StatefulWidget {
  const InventoryDashboardPage({super.key});

  @override
  State<InventoryDashboardPage> createState() => _InventoryDashboardPageState();
}

class _InventoryDashboardPageState extends State<InventoryDashboardPage> {
  late final InventoryDashboardCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<InventoryDashboardCubit>()..load();
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
      child: const _InventoryDashboardView(),
    );
  }
}

class _InventoryDashboardView extends StatelessWidget {
  const _InventoryDashboardView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isPhone = AppBreakpoints.isPhone(width);
    final isDesktop = AppBreakpoints.isDesktop(width);
    final compactStats = isPhone || isDesktop;
    final canCreate = context.select(
      (AuthCubit cubit) =>
          cubit.state.user?.permissionChecker.canCreateInventory() == true,
    );

    return Scaffold(
      appBar: isDesktop ? null : AppBar(title: Text(l10n.inventory)),
      body: BlocBuilder<InventoryDashboardCubit, InventoryDashboardState>(
        buildWhen: (previous, current) =>
            previous.status != current.status ||
            previous.dashboard != current.dashboard ||
            previous.isRefreshing != current.isRefreshing ||
            previous.message != current.message,
        builder: (context, state) {
          if ((state.status == InventoryDashboardStatus.loading ||
                  state.status == InventoryDashboardStatus.initial) &&
              state.dashboard == null) {
            return AppLoader(message: l10n.inventoryLoading);
          }

          if (state.status == InventoryDashboardStatus.failure &&
              state.dashboard == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      state.message != null
                          ? localizeAppMessage(l10n, state.message)
                          : l10n.inventoryLoadFailed,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton(
                      onPressed: () =>
                          context.read<InventoryDashboardCubit>().load(),
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            );
          }

          final dashboard = state.dashboard;

          return Column(
            children: [
              AppRefreshBar(visible: state.isRefreshing),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () =>
                      context.read<InventoryDashboardCubit>().load(),
                  child: AppPageFrame(
                    maxWidth: AppBreakpoints.contentWideMax,
                    child: ListView(
                      padding: AppScrollPadding.resolve(
                        context,
                        base: EdgeInsets.all(
                          isPhone ? AppSpacing.md : AppSpacing.lg,
                        ),
                        chrome: AppBottomChrome.system,
                      ),
                      children: [
                        if (isDesktop) ...[
                          AppDesktopPageHeader(
                            title: l10n.inventory,
                            trailing: canCreate
                                ? FilledButton.icon(
                                    onPressed: () => context.push(
                                      RoutePaths.inventoryPartForm,
                                    ),
                                    icon: const Icon(Icons.add),
                                    label: Text(l10n.inventoryCreatePart),
                                  )
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                        AppDesktopStatGrid(
                          phoneColumns: 2,
                          tabletColumns: 4,
                          desktopColumns: 4,
                          children: [
                            DashboardQuickCard(
                              title: l10n.inventoryTotalParts,
                              subtitle: '${dashboard?.totalParts ?? 0}',
                              icon: Icons.category_outlined,
                              compact: compactStats,
                              onTap: () =>
                                  context.push(RoutePaths.inventoryParts),
                            ),
                            DashboardQuickCard(
                              title: l10n.inventoryLowStock,
                              subtitle: '${dashboard?.lowStock ?? 0}',
                              icon: Icons.warning_amber_outlined,
                              compact: compactStats,
                              onTap: () => context.push(
                                RoutePaths.inventoryParts,
                                extra: 'LOW_STOCK',
                              ),
                            ),
                            DashboardQuickCard(
                              title: l10n.inventoryOutOfStock,
                              subtitle: '${dashboard?.outOfStock ?? 0}',
                              icon: Icons.remove_shopping_cart_outlined,
                              compact: compactStats,
                              onTap: () => context.push(
                                RoutePaths.inventoryParts,
                                extra: 'OUT_OF_STOCK',
                              ),
                            ),
                            DashboardQuickCard(
                              title: l10n.inventoryWarehouses,
                              subtitle: l10n.inventoryManage,
                              icon: Icons.warehouse_outlined,
                              compact: compactStats,
                              onTap: () =>
                                  context.push(RoutePaths.inventoryWarehouses),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        if (isDesktop)
                          GridView.count(
                            crossAxisCount: 3,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: AppSpacing.md,
                            crossAxisSpacing: AppSpacing.md,
                            childAspectRatio: 2.8,
                            children: [
                              AppDesktopNavTile(
                                title: l10n.inventorySpareParts,
                                subtitle: l10n.inventoryTotalParts,
                                icon: Icons.inventory_2_outlined,
                                onTap: () =>
                                    context.push(RoutePaths.inventoryParts),
                              ),
                              AppDesktopNavTile(
                                title: l10n.inventoryStockHistory,
                                subtitle: l10n.inventoryRecentMovements,
                                icon: Icons.history,
                                onTap: () => context
                                    .push(RoutePaths.inventoryStockHistory),
                              ),
                              AppDesktopNavTile(
                                title: l10n.inventoryWarehouses,
                                subtitle: l10n.inventoryManage,
                                icon: Icons.warehouse_outlined,
                                onTap: () => context
                                    .push(RoutePaths.inventoryWarehouses),
                              ),
                            ],
                          )
                        else
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              FilledButton.tonalIcon(
                                onPressed: () =>
                                    context.push(RoutePaths.inventoryParts),
                                icon: const Icon(Icons.inventory_2_outlined),
                                label: Text(l10n.inventorySpareParts),
                              ),
                              FilledButton.tonalIcon(
                                onPressed: () => context.push(
                                  RoutePaths.inventoryStockHistory,
                                ),
                                icon: const Icon(Icons.history),
                                label: Text(l10n.inventoryStockHistory),
                              ),
                              if (canCreate)
                                FilledButton.icon(
                                  onPressed: () => context
                                      .push(RoutePaths.inventoryPartForm),
                                  icon: const Icon(Icons.add),
                                  label: Text(l10n.inventoryCreatePart),
                                ),
                            ],
                          ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          l10n.inventoryRecentMovements,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        if ((dashboard?.recentMovements ?? const []).isEmpty)
                          isDesktop
                              ? AppDesktopEmptyState(
                                  icon: Icons.swap_horiz_outlined,
                                  title: l10n.inventoryMovementsEmpty,
                                  actionLabel: l10n.inventorySpareParts,
                                  onAction: () => context.push(
                                    RoutePaths.inventoryParts,
                                  ),
                                )
                              : Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.xl,
                                  ),
                                  child: Center(
                                    child: Text(l10n.inventoryMovementsEmpty),
                                  ),
                                )
                        else
                          ...dashboard!.recentMovements.map(
                            (movement) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.sm,
                              ),
                              child: StockMovementTile(movement: movement),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
