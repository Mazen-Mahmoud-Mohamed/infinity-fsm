import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/features/organization/presentation/cubit/organization_cubit.dart';
import 'package:mobile/features/organization/presentation/widgets/organization_list_scaffold.dart';
import 'package:mobile/features/organization/presentation/widgets/organization_list_tile_card.dart';

class CompanyListPage extends StatelessWidget {
  const CompanyListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<OrganizationCubit>()..loadCompanies(),
      child: const _CompanyListView(),
    );
  }
}

class _CompanyListView extends StatefulWidget {
  const _CompanyListView();

  @override
  State<_CompanyListView> createState() => _CompanyListViewState();
}

class _CompanyListViewState extends State<_CompanyListView> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrganizationCubit, OrganizationState>(
      builder: (context, state) {
        final l10n = AppLocalizations.of(context);
        final items = state.companies.where((item) {
          if (_query.isEmpty) {
            return true;
          }
          return item.name.toLowerCase().contains(_query) ||
              item.code.toLowerCase().contains(_query);
        }).toList();

        return OrganizationListScaffold(
          title: l10n.orgCompanies,
          searchHint: l10n.orgSearchCompanies,
          isLoading: state.status == OrganizationStatus.loading,
          isRefreshing: state.isRefreshing,
          isOffline: state.isOffline,
          hasError: state.status == OrganizationStatus.failure,
          isEmpty: items.isEmpty,
          errorMessage: state.message,
          itemCount: items.length,
          onRefresh: () => context
              .read<OrganizationCubit>()
              .loadCompanies(forceRefresh: true),
          onSearch: (value) => setState(() => _query = value.trim().toLowerCase()),
          itemBuilder: (context, index) {
            final item = items[index];
            return OrganizationListTileCard(
              title: item.name,
              subtitle: item.code,
              trailing: item.status,
              icon: Icons.apartment_outlined,
            );
          },
        );
      },
    );
  }
}

class BranchListPage extends StatelessWidget {
  const BranchListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<OrganizationCubit>()..loadBranches(),
      child: _SearchableOrgListPage(
        titleBuilder: (l10n) => l10n.orgBranches,
        searchHintBuilder: (l10n) => l10n.orgSearchBranches,
        icon: Icons.store_mall_directory_outlined,
        loader: _BranchLoader(),
      ),
    );
  }
}

class DepartmentListPage extends StatelessWidget {
  const DepartmentListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<OrganizationCubit>()..loadDepartments(),
      child: _SearchableOrgListPage(
        titleBuilder: (l10n) => l10n.orgDepartments,
        searchHintBuilder: (l10n) => l10n.orgSearchDepartments,
        icon: Icons.account_tree_outlined,
        loader: _DepartmentLoader(),
      ),
    );
  }
}

class TeamListPage extends StatelessWidget {
  const TeamListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<OrganizationCubit>()..loadTeams(),
      child: _SearchableOrgListPage(
        titleBuilder: (l10n) => l10n.orgTeams,
        searchHintBuilder: (l10n) => l10n.orgSearchTeams,
        icon: Icons.groups_outlined,
        loader: _TeamLoader(),
      ),
    );
  }
}

class PositionListPage extends StatelessWidget {
  const PositionListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<OrganizationCubit>()..loadPositions(),
      child: _SearchableOrgListPage(
        titleBuilder: (l10n) => l10n.orgPositions,
        searchHintBuilder: (l10n) => l10n.orgSearchPositions,
        icon: Icons.badge_outlined,
        loader: _PositionLoader(),
      ),
    );
  }
}

class UserDirectoryPage extends StatelessWidget {
  const UserDirectoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<OrganizationCubit>()..loadUsers(),
      child: _SearchableOrgListPage(
        titleBuilder: (l10n) => l10n.orgUserDirectory,
        searchHintBuilder: (l10n) => l10n.orgSearchUsers,
        icon: Icons.people_outline,
        loader: _UserLoader(),
      ),
    );
  }
}

abstract class _OrgListLoader {
  const _OrgListLoader();

  Future<void> load(
    OrganizationCubit cubit, {
    String? search,
    bool forceRefresh = false,
  });

  List<({String title, String subtitle, String status})> items(
    OrganizationState state,
  );
}

class _BranchLoader extends _OrgListLoader {
  const _BranchLoader();

  @override
  Future<void> load(
    OrganizationCubit cubit, {
    String? search,
    bool forceRefresh = false,
  }) {
    return cubit.loadBranches(search: search, forceRefresh: forceRefresh);
  }

  @override
  List<({String title, String subtitle, String status})> items(
    OrganizationState state,
  ) {
    return state.branches
        .map(
          (item) => (
            title: item.name,
            subtitle: [
              item.code,
              if (item.addressCity != null) item.addressCity!,
            ].join(' · '),
            status: item.status,
          ),
        )
        .toList();
  }
}

class _DepartmentLoader extends _OrgListLoader {
  const _DepartmentLoader();

  @override
  Future<void> load(
    OrganizationCubit cubit, {
    String? search,
    bool forceRefresh = false,
  }) {
    return cubit.loadDepartments(search: search, forceRefresh: forceRefresh);
  }

  @override
  List<({String title, String subtitle, String status})> items(
    OrganizationState state,
  ) {
    return state.departments
        .map(
          (item) => (
            title: item.name,
            subtitle: item.code,
            status: item.status,
          ),
        )
        .toList();
  }
}

class _TeamLoader extends _OrgListLoader {
  const _TeamLoader();

  @override
  Future<void> load(
    OrganizationCubit cubit, {
    String? search,
    bool forceRefresh = false,
  }) {
    return cubit.loadTeams(search: search, forceRefresh: forceRefresh);
  }

  @override
  List<({String title, String subtitle, String status})> items(
    OrganizationState state,
  ) {
    return state.teams
        .map(
          (item) => (
            title: item.name,
            subtitle: item.code,
            status: item.status,
          ),
        )
        .toList();
  }
}

class _PositionLoader extends _OrgListLoader {
  const _PositionLoader();

  @override
  Future<void> load(
    OrganizationCubit cubit, {
    String? search,
    bool forceRefresh = false,
  }) {
    return cubit.loadPositions(search: search, forceRefresh: forceRefresh);
  }

  @override
  List<({String title, String subtitle, String status})> items(
    OrganizationState state,
  ) {
    return state.positions
        .map(
          (item) => (
            title: item.name,
            subtitle: [
              item.code,
              if (item.description != null) item.description!,
            ].join(' · '),
            status: item.status,
          ),
        )
        .toList();
  }
}

class _UserLoader extends _OrgListLoader {
  const _UserLoader();

  @override
  Future<void> load(
    OrganizationCubit cubit, {
    String? search,
    bool forceRefresh = false,
  }) {
    return cubit.loadUsers(search: search, forceRefresh: forceRefresh);
  }

  @override
  List<({String title, String subtitle, String status})> items(
    OrganizationState state,
  ) {
    return state.users
        .map(
          (item) => (
            title: item.fullName,
            subtitle: '${item.email} · ${item.primaryRole}',
            status: item.status,
          ),
        )
        .toList();
  }
}

class _SearchableOrgListPage extends StatefulWidget {
  const _SearchableOrgListPage({
    required this.titleBuilder,
    required this.searchHintBuilder,
    required this.icon,
    required this.loader,
  });

  final String Function(AppLocalizations l10n) titleBuilder;
  final String Function(AppLocalizations l10n) searchHintBuilder;
  final IconData icon;
  final _OrgListLoader loader;

  @override
  State<_SearchableOrgListPage> createState() => _SearchableOrgListPageState();
}

class _SearchableOrgListPageState extends State<_SearchableOrgListPage> {
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrganizationCubit, OrganizationState>(
      builder: (context, state) {
        final l10n = AppLocalizations.of(context);
        final items = widget.loader.items(state);

        return OrganizationListScaffold(
          title: widget.titleBuilder(l10n),
          searchHint: widget.searchHintBuilder(l10n),
          isLoading: state.status == OrganizationStatus.loading,
          isRefreshing: state.isRefreshing,
          isOffline: state.isOffline,
          hasError: state.status == OrganizationStatus.failure,
          isEmpty: items.isEmpty,
          errorMessage: state.message,
          itemCount: items.length,
          onRefresh: () => widget.loader.load(
            context.read<OrganizationCubit>(),
            forceRefresh: true,
          ),
          onSearch: (value) {
            _debounce?.cancel();
            _debounce = Timer(const Duration(milliseconds: 350), () {
              widget.loader.load(
                context.read<OrganizationCubit>(),
                search: value,
              );
            });
          },
          itemBuilder: (context, index) {
            final item = items[index];
            return OrganizationListTileCard(
              title: item.title,
              subtitle: item.subtitle,
              trailing: item.status,
              icon: widget.icon,
            );
          },
        );
      },
    );
  }
}
