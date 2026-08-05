import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/constants/app_breakpoints.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_app_message.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/core/widgets/app_page_frame.dart';
import 'package:mobile/core/widgets/app_refresh_bar.dart';
import 'package:mobile/features/auth/domain/services/permission_checker.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/features/reports_center/domain/entities/reports_center_module.dart';
import 'package:mobile/features/reports_center/presentation/cubit/reports_center_cubit.dart';
import 'package:mobile/features/reports_center/presentation/utils/reports_center_labels.dart';
import 'package:mobile/features/reports_center/presentation/widgets/reports_center_widgets.dart';

class ReportsCenterPage extends StatefulWidget {
  const ReportsCenterPage({super.key});

  @override
  State<ReportsCenterPage> createState() => _ReportsCenterPageState();
}

class _ReportsCenterPageState extends State<ReportsCenterPage> {
  late final ReportsCenterCubit _cubit;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final permissions =
        getIt<AuthCubit>().state.user?.permissionChecker ??
            const PermissionChecker([]);
    _cubit = getIt<ReportsCenterCubit>(param1: permissions)..bootstrap();
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
        _scrollController.position.maxScrollExtent - 240) {
      _cubit.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isPhone = AppBreakpoints.isPhone(width);
    final canGenerate = context.select(
      (AuthCubit c) =>
          c.state.user?.permissionChecker.canGenerateReports() == true,
    );

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.reportsCenter),
          actions: [
            if (!isPhone)
              IconButton(
                tooltip: l10n.reportsCenterFilters,
                onPressed: () =>
                    showReportsCenterFilterSheet(context, cubit: _cubit),
                icon: const Icon(Icons.tune),
              ),
          ],
        ),
        body: BlocConsumer<ReportsCenterCubit, ReportsCenterState>(
          listenWhen: (p, c) => p.module != c.module,
          listener: (context, state) {
            _searchController.text = state.search;
          },
          builder: (context, state) {
            if (state.availableModules.isEmpty &&
                state.status == ReportsCenterStatus.failure) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    state.message == 'reportsCenterNoAccess'
                        ? l10n.reportsCenterNoAccess
                        : localizeAppMessage(l10n, state.message),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            return Column(
              children: [
                AppRefreshBar(visible: state.isRefreshing),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    0,
                  ),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final module in state.availableModules)
                            Padding(
                              padding: const EdgeInsetsDirectional.only(
                                end: AppSpacing.sm,
                              ),
                              child: ChoiceChip(
                                label: Text(reportsModuleLabel(l10n, module)),
                                selected: state.module == module,
                                onSelected: (_) =>
                                    context.read<ReportsCenterCubit>().selectModule(module),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (state.module == ReportsCenterModule.serviceReports)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      0,
                    ),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          FilledButton.tonalIcon(
                            onPressed: () =>
                                context.push(RoutePaths.reportsList),
                            icon: const Icon(Icons.list_alt),
                            label: Text(l10n.reportsList),
                          ),
                          if (canGenerate) ...[
                            FilledButton.tonalIcon(
                              onPressed: () =>
                                  context.push(RoutePaths.reportsSignature),
                              icon: const Icon(Icons.draw),
                              label: Text(l10n.reportsCaptureSignature),
                            ),
                            FilledButton.tonalIcon(
                              onPressed: () =>
                                  context.push(RoutePaths.reportsGenerate),
                              icon: const Icon(Icons.note_add_outlined),
                              label: Text(l10n.reportsGenerate),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ReportsCenterFilterBar(searchController: _searchController),
                const Divider(height: 1),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () =>
                        context.read<ReportsCenterCubit>().loadFirstPage(),
                    child: AppPageFrame(
                      maxWidth: AppBreakpoints.contentWideMax,
                      child: ReportsCenterResults(
                        scrollController: _scrollController,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
