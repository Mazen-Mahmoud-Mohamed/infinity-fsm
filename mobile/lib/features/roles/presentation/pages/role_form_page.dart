import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_app_message.dart';
import 'package:mobile/core/localization/localize_rbac.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/core/widgets/app_loader.dart';
import 'package:mobile/core/widgets/app_scroll_padding.dart';
import 'package:mobile/features/roles/domain/entities/role_entities.dart';
import 'package:mobile/features/roles/presentation/cubit/roles_cubits.dart';
import 'package:mobile/features/roles/presentation/widgets/role_permission_tiles.dart';

class RoleFormPage extends StatefulWidget {
  const RoleFormPage({super.key, this.roleId});

  final String? roleId;

  @override
  State<RoleFormPage> createState() => _RoleFormPageState();
}

class _RoleFormPageState extends State<RoleFormPage> {
  late final RoleFormCubit _cubit;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _colorController = TextEditingController(text: '#1565C0');
  final _permissionSearch = TextEditingController();
  final Set<String> _selectedPermissions = {};
  bool _hydrated = false;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<RoleFormCubit>()..load(roleId: widget.roleId);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _colorController.dispose();
    _permissionSearch.dispose();
    _cubit.close();
    super.dispose();
  }

  void _hydrate(RoleFormState state) {
    if (_hydrated || state.role == null) return;
    final role = state.role!;
    _nameController.text = role.name;
    _descriptionController.text = role.description ?? '';
    _colorController.text = role.color ?? '#1565C0';
    _selectedPermissions
      ..clear()
      ..addAll(role.permissions);
    _hydrated = true;
  }

  Future<void> _submit(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) return;
    final result = await _cubit.save(
      RoleUpsertInput(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        color: _colorController.text.trim().isEmpty
            ? null
            : _colorController.text.trim(),
        permissions: _selectedPermissions.toList()..sort(),
      ),
    );
    if (!mounted) return;
    switch (result) {
      case Success():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.roleId == null ? l10n.rolesCreated : l10n.rolesUpdated,
            ),
          ),
        );
        context.pop(true);
      case Failure(:final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizeAppMessage(l10n, message))),
        );
    }
  }

  bool _matchesPermissionSearch(
    AppLocalizations l10n,
    PermissionCatalogItem item,
    String query,
  ) {
    if (query.isEmpty) return true;
    final label = localizePermissionKey(l10n, item.key).toLowerCase();
    final description =
        localizePermissionDescription(l10n, item.key).toLowerCase();
    final groupLabel = localizePermissionGroup(l10n, item.module).toLowerCase();
    final groupDescription =
        localizePermissionGroupDescription(l10n, item.module).toLowerCase();
    return label.contains(query) ||
        description.contains(query) ||
        groupLabel.contains(query) ||
        groupDescription.contains(query);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEdit = widget.roleId != null;
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 900;

    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<RoleFormCubit, RoleFormState>(
        listener: (context, state) {
          if (state.status == RoleFormStatus.ready) {
            _hydrate(state);
            setState(() {});
          }
        },
        builder: (context, state) {
          final saving = state.status == RoleFormStatus.saving;
          final catalog = state.catalog;
          final query = _permissionSearch.text.trim().toLowerCase();
          final filtered = catalog
              .where((p) => _matchesPermissionSearch(l10n, p, query))
              .toList();

          final modules = <String, List<PermissionCatalogItem>>{};
          for (final item in filtered) {
            modules.putIfAbsent(item.module, () => []).add(item);
          }

          return Scaffold(
            appBar: AppBar(
              title: Text(isEdit ? l10n.rolesEdit : l10n.rolesCreate),
            ),
            body: state.status == RoleFormStatus.loading
                ? AppLoader(message: l10n.rolesLoading)
                : state.status == RoleFormStatus.failure &&
                        state.role == null &&
                        isEdit
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              state.message != null
                                  ? localizeAppMessage(l10n, state.message)
                                  : l10n.rolesLoadFailed,
                            ),
                            FilledButton(
                              onPressed: () =>
                                  _cubit.load(roleId: widget.roleId),
                              child: Text(l10n.retry),
                            ),
                          ],
                        ),
                      )
                    : Form(
                        key: _formKey,
                        child: AppBottomSafeListView(
                          basePadding: const EdgeInsets.all(AppSpacing.md),
                          chrome: AppBottomChrome.system,
                          children: [
                            if (saving) const LinearProgressIndicator(),
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: l10n.rolesName,
                                border: const OutlineInputBorder(),
                              ),
                              textCapitalization: TextCapitalization.words,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return l10n.rolesNameRequired;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextFormField(
                              controller: _descriptionController,
                              decoration: InputDecoration(
                                labelText: l10n.rolesDescription,
                                border: const OutlineInputBorder(),
                              ),
                              maxLines: 3,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextFormField(
                              controller: _colorController,
                              decoration: InputDecoration(
                                labelText: l10n.rolesColor,
                                border: const OutlineInputBorder(),
                                hintText: '#1565C0',
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              l10n.rolesPermissions,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            TextField(
                              controller: _permissionSearch,
                              decoration: InputDecoration(
                                hintText: l10n.rolesSearchPermissions,
                                prefixIcon: const Icon(Icons.search),
                                border: const OutlineInputBorder(),
                                suffixIcon: query.isEmpty
                                    ? null
                                    : IconButton(
                                        tooltip: MaterialLocalizations.of(
                                          context,
                                        ).deleteButtonTooltip,
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          _permissionSearch.clear();
                                          setState(() {});
                                        },
                                      ),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              l10n.rolesSelectedPermissions(
                                _selectedPermissions.length,
                              ),
                              style: theme.textTheme.labelLarge,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            if (modules.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.lg,
                                ),
                                child: Text(
                                  catalog.isEmpty
                                      ? l10n.rolesPermissionsCatalogEmpty
                                      : query.isNotEmpty
                                          ? l10n.rolesPermissionsSearchEmpty
                                          : l10n.rolesNoPermissions,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              )
                            else
                              ...modules.entries.map((entry) {
                                return RolePermissionGroupCard(
                                  module: entry.key,
                                  count: entry.value.length,
                                  initiallyExpanded: isWide,
                                  children: [
                                    for (final item in entry.value)
                                      RolePermissionTile(
                                        permissionKey: item.key,
                                        selected: _selectedPermissions
                                            .contains(item.key),
                                        enabled: !saving,
                                        onChanged: (checked) {
                                          setState(() {
                                            if (checked == true) {
                                              _selectedPermissions.add(item.key);
                                            } else {
                                              _selectedPermissions
                                                  .remove(item.key);
                                            }
                                          });
                                        },
                                      ),
                                  ],
                                );
                              }),
                            const SizedBox(height: AppSpacing.lg),
                            FilledButton(
                              onPressed: saving ? null : () => _submit(l10n),
                              child: Text(
                                isEdit ? l10n.rolesSave : l10n.rolesCreate,
                              ),
                            ),
                          ],
                        ),
                      ),
          );
        },
      ),
    );
  }
}
