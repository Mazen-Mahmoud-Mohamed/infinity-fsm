import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_app_message.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/core/widgets/app_loader.dart';
import 'package:mobile/core/widgets/technician_main_app_bar.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/features/settings/domain/entities/settings_entities.dart';
import 'package:mobile/features/settings/presentation/cubit/technician_interface_cubits.dart';
import 'package:mobile/features/settings/presentation/widgets/settings_layout.dart';

class TechnicianInterfaceSettingsPage extends StatefulWidget {
  const TechnicianInterfaceSettingsPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<TechnicianInterfaceSettingsPage> createState() =>
      _TechnicianInterfaceSettingsPageState();
}

class _TechnicianInterfaceSettingsPageState
    extends State<TechnicianInterfaceSettingsPage> {
  late final TechnicianInterfaceSettingsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<TechnicianInterfaceSettingsCubit>()..load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _toggle({
    required String field,
    required bool value,
  }) async {
    final input = switch (field) {
      'overtime' => TechnicianInterfaceConfigUpdate(overtime: value),
      'workOrders' => TechnicianInterfaceConfigUpdate(workOrders: value),
      'attendance' => TechnicianInterfaceConfigUpdate(attendance: value),
      'profile' => TechnicianInterfaceConfigUpdate(profile: value),
      _ => const TechnicianInterfaceConfigUpdate(),
    };

    final result = await _cubit.save(input);
    if (!mounted) return;

    switch (result) {
      case Success():
        final companyId = context.read<AuthCubit>().state.user?.companyId;
        await getIt<TechnicianInterfaceCubit>().load(
          force: true,
          companyId: companyId,
        );
      case Failure(:final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizeAppMessage(AppLocalizations.of(context), message)),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canManage = context.select(
      (AuthCubit c) =>
          c.state.user?.permissionChecker.canManageSettings() == true,
    );

    return BlocProvider.value(
      value: _cubit,
      child: widget.embedded
          ? _buildBody(l10n, canManage)
          : Scaffold(
              appBar: AppBar(title: Text(l10n.settingsTechnicianInterfaceTitle)),
              body: _buildBody(l10n, canManage),
            ),
    );
  }

  Widget _buildBody(AppLocalizations l10n, bool canManage) {
    return BlocBuilder<TechnicianInterfaceSettingsCubit,
        TechnicianInterfaceSettingsState>(
      builder: (context, state) {
        if (state.status == TechnicianInterfaceSettingsStatus.loading &&
            state.config == null) {
          return AppLoader(message: l10n.settingsLoading);
        }
        if (state.status == TechnicianInterfaceSettingsStatus.failure &&
            state.config == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  state.message != null
                      ? localizeAppMessage(l10n, state.message)
                      : l10n.settingsLoadFailed,
                ),
                FilledButton(onPressed: _cubit.load, child: Text(l10n.retry)),
              ],
            ),
          );
        }

        final config = state.config ?? TechnicianInterfaceConfig.defaults;
        final isSaving =
            state.status == TechnicianInterfaceSettingsStatus.saving;

        return SettingsPageBody(
          embedded: widget.embedded,
          children: [
            if (state.isRefreshing)
              const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.sm),
                child: LinearProgressIndicator(minHeight: 2),
              ),
            SettingsCard(
              title: l10n.settingsTechnicianInterfaceTitle,
              subtitle: l10n.settingsTechnicianInterfaceDescription,
              leading: const Icon(Icons.engineering_outlined),
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.overtime),
                    value: config.overtime,
                    onChanged: canManage && !isSaving
                        ? (value) => _toggle(field: 'overtime', value: value)
                        : null,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.workOrders),
                    value: config.workOrders,
                    onChanged: canManage && !isSaving
                        ? (value) => _toggle(field: 'workOrders', value: value)
                        : null,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.attendance),
                    value: config.attendance,
                    onChanged: canManage && !isSaving
                        ? (value) => _toggle(field: 'attendance', value: value)
                        : null,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.profile),
                    value: config.profile,
                    onChanged: canManage && !isSaving
                        ? (value) => _toggle(field: 'profile', value: value)
                        : null,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class TechnicianNoSectionsPage extends StatelessWidget {
  const TechnicianNoSectionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: TechnicianMainAppBar(
        title: Text(l10n.settingsTechnicianNoSectionsTitle),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.block_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.settingsTechnicianNoSectionsTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.settingsTechnicianNoSectionsBody,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton.icon(
                  onPressed: () async {
                    final router = GoRouter.of(context);
                    await context.read<AuthCubit>().logout();
                    router.go(RoutePaths.login);
                  },
                  icon: const Icon(Icons.logout),
                  label: Text(l10n.logout),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
