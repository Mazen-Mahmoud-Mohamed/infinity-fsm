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
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/features/dashboard/presentation/widgets/dashboard_quick_card.dart';
import 'package:mobile/features/service_reports/presentation/cubit/service_reports_cubits.dart';

class ServiceReportsDashboardPage extends StatefulWidget {
  const ServiceReportsDashboardPage({super.key});

  @override
  State<ServiceReportsDashboardPage> createState() =>
      _ServiceReportsDashboardPageState();
}

class _ServiceReportsDashboardPageState
    extends State<ServiceReportsDashboardPage> {
  late final ServiceReportsDashboardCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<ServiceReportsDashboardCubit>()..load();
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
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isPhone = width < 600;
    final canGenerate = context.select(
      (AuthCubit c) =>
          c.state.user?.permissionChecker.canGenerateReports() == true,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reportsTitle)),
      body: BlocBuilder<ServiceReportsDashboardCubit,
          ServiceReportsDashboardState>(
        buildWhen: (p, c) =>
            p.status != c.status ||
            p.dashboard != c.dashboard ||
            p.message != c.message ||
            p.isRefreshing != c.isRefreshing,
        builder: (context, state) {
          if ((state.status == ServiceReportsDashboardStatus.loading ||
                  state.status == ServiceReportsDashboardStatus.initial) &&
              state.dashboard == null) {
            return AppLoader(message: l10n.reportsLoading);
          }
          if (state.status == ServiceReportsDashboardStatus.failure &&
              state.dashboard == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      state.message ?? l10n.reportsLoadFailed,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton(
                      onPressed: () => context
                          .read<ServiceReportsDashboardCubit>()
                          .load(),
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            );
          }

          final dashboard = state.dashboard;
          final cols = isPhone ? 2 : 4;

          return Column(
            children: [
              AppRefreshBar(visible: state.isRefreshing),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () =>
                      context.read<ServiceReportsDashboardCubit>().load(),
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
                    final itemWidth =
                        (constraints.maxWidth - (AppSpacing.md * (cols - 1))) /
                            cols;
                    return Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.md,
                      children: [
                        _stat(
                          itemWidth,
                          isPhone,
                          l10n.reportsTotal,
                          '${dashboard?.totalReports ?? 0}',
                          Icons.description_outlined,
                          () => context.push(RoutePaths.reportsList),
                        ),
                        _stat(
                          itemWidth,
                          isPhone,
                          l10n.reportsStatusGenerated,
                          '${dashboard?.generated ?? 0}',
                          Icons.auto_awesome_outlined,
                          () => context.push(RoutePaths.reportsList),
                        ),
                        _stat(
                          itemWidth,
                          isPhone,
                          l10n.reportsStatusDownloaded,
                          '${dashboard?.downloaded ?? 0}',
                          Icons.download_outlined,
                          () => context.push(RoutePaths.reportsList),
                        ),
                        _stat(
                          itemWidth,
                          isPhone,
                          l10n.reportsSignatures,
                          '${dashboard?.totalSignatures ?? 0}',
                          Icons.draw_outlined,
                          () => context.push(RoutePaths.reportsSignature),
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
                      onPressed: () => context.push(RoutePaths.reportsList),
                      icon: const Icon(Icons.list_alt),
                      label: Text(l10n.reportsList),
                    ),
                    if (canGenerate) ...[
                      FilledButton.icon(
                        onPressed: () =>
                            context.push(RoutePaths.reportsSignature),
                        icon: const Icon(Icons.draw),
                        label: Text(l10n.reportsCaptureSignature),
                      ),
                      FilledButton.icon(
                        onPressed: () =>
                            context.push(RoutePaths.reportsGenerate),
                        icon: const Icon(Icons.note_add_outlined),
                        label: Text(l10n.reportsGenerate),
                      ),
                    ],
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
