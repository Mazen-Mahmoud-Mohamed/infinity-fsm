import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/constants/app_radius.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/core/widgets/app_loader.dart';
import 'package:mobile/core/widgets/app_refresh_bar.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/features/roles/domain/entities/role_entities.dart';
import 'package:mobile/features/roles/presentation/cubit/roles_cubits.dart';
import 'package:mobile/features/roles/presentation/widgets/role_status_chip.dart';

class RolesListPage extends StatefulWidget {
  const RolesListPage({
    super.key,
    this.initialActive,
    this.initialSystem,
  });

  final bool? initialActive;
  final bool? initialSystem;

  @override
  State<RolesListPage> createState() => _RolesListPageState();
}

class _RolesListPageState extends State<RolesListPage> {
  late final RolesListCubit _cubit;
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cubit = getIt<RolesListCubit>()
      ..loadFirstPage(
        isActive: widget.initialActive,
        isSystem: widget.initialSystem,
      );
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
      (AuthCubit c) => c.state.user?.permissionChecker.canCreateRoles() == true,
    );
    final theme = Theme.of(context);

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.rolesList)),
        floatingActionButton: canCreate
            ? FloatingActionButton.extended(
                onPressed: () async {
                  final changed =
                      await context.push<bool>(RoutePaths.rolesForm);
                  if (changed == true && mounted) {
                    await _cubit.loadFirstPage();
                  }
                },
                icon: const Icon(Icons.add),
                label: Text(l10n.rolesCreate),
              )
            : null,
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: l10n.rolesSearchHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _cubit.loadFirstPage(search: '');
                            setState(() {});
                          },
                        ),
                  border: const OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.search,
                onChanged: (_) => setState(() {}),
                onSubmitted: (value) => _cubit.loadFirstPage(search: value),
              ),
            ),
            BlocSelector<RolesListCubit, RolesListState, bool>(
              selector: (state) => state.isRefreshing,
              builder: (context, refreshing) =>
                  AppRefreshBar(visible: refreshing),
            ),
            Expanded(
              child: BlocBuilder<RolesListCubit, RolesListState>(
                builder: (context, state) {
                  if ((state.status == RolesListStatus.loading ||
                          state.status == RolesListStatus.initial) &&
                      state.items.isEmpty) {
                    return AppLoader(message: l10n.rolesLoading);
                  }
                  if (state.status == RolesListStatus.failure &&
                      state.items.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(state.message ?? l10n.rolesLoadFailed),
                            const SizedBox(height: AppSpacing.md),
                            FilledButton(
                              onPressed: () => _cubit.loadFirstPage(),
                              child: Text(l10n.retry),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  if (state.items.isEmpty) {
                    return Center(child: Text(l10n.rolesEmpty));
                  }

                  return RefreshIndicator(
                    onRefresh: () => _cubit.loadFirstPage(),
                    child: ListView.separated(
                      controller: _scrollController,
                      padding: AppScrollPadding.resolve(
                        context,
                        base: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          0,
                          AppSpacing.md,
                          0,
                        ),
                        chrome: AppBottomChrome.fab,
                      ),
                      itemCount: state.items.length +
                          (state.status == RolesListStatus.loadingMore ? 1 : 0),
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        if (index >= state.items.length) {
                          return const Padding(
                            padding: EdgeInsets.all(AppSpacing.md),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final role = state.items[index];
                        return _RoleListTile(role: role, theme: theme);
                      },
                    ),
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

class _RoleListTile extends StatelessWidget {
  const _RoleListTile({required this.role, required this.theme});

  final RoleEntity role;
  final ThemeData theme;

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return theme.colorScheme.primary;
    var value = hex.replaceFirst('#', '');
    if (value.length == 6) value = 'FF$value';
    final parsed = int.tryParse(value, radix: 16);
    return parsed == null
        ? theme.colorScheme.primary
        : Color(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = _parseColor(role.color);

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () => context.push(RoutePaths.roleDetail(role.id)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      role.slug,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: 4,
                      children: [
                        RoleStatusChip(isActive: role.isActive),
                        if (role.isSystem)
                          Chip(
                            label: Text(l10n.rolesSystemBadge),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        Text(
                          l10n.rolesAssignedUsers(role.assignedUsersCount),
                          style: theme.textTheme.labelMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
