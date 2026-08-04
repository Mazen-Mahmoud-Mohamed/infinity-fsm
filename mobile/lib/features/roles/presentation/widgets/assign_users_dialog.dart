import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_app_message.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/core/widgets/app_loader.dart';
import 'package:mobile/core/widgets/app_refresh_bar.dart';
import 'package:mobile/features/roles/presentation/cubit/roles_cubits.dart';

Future<bool?> showAssignUsersDialog(
  BuildContext context, {
  required String roleId,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AssignUsersDialog(roleId: roleId),
  );
}

class AssignUsersDialog extends StatefulWidget {
  const AssignUsersDialog({super.key, required this.roleId});

  final String roleId;

  @override
  State<AssignUsersDialog> createState() => _AssignUsersDialogState();
}

class _AssignUsersDialogState extends State<AssignUsersDialog> {
  late final AssignUsersCubit _cubit;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cubit = getIt<AssignUsersCubit>()..load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;

    return BlocProvider.value(
      value: _cubit,
      child: AlertDialog(
        title: Text(l10n.rolesAssignUsers),
        content: SizedBox(
          width: width < 600 ? width * 0.9 : 480,
          height: 420,
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: l10n.rolesSearchUsersHint,
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (value) => _cubit.load(search: value),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: BlocBuilder<AssignUsersCubit, AssignUsersState>(
                  builder: (context, state) {
                    if ((state.status == AssignUsersStatus.loading ||
                            state.status == AssignUsersStatus.initial) &&
                        state.candidates.isEmpty) {
                      return AppLoader(message: l10n.rolesLoading);
                    }
                    if (state.status == AssignUsersStatus.failure &&
                        state.candidates.isEmpty) {
                      return Center(
                        child: Text(
                          state.message != null
                              ? localizeAppMessage(l10n, state.message)
                              : l10n.rolesLoadFailed,
                        ),
                      );
                    }
                    return Column(
                      children: [
                        AppRefreshBar(visible: state.isRefreshing),
                        Expanded(
                          child: state.candidates.isEmpty
                              ? Center(child: Text(l10n.rolesNoUsersFound))
                              : ListView.builder(
                                  itemCount: state.candidates.length,
                                  itemBuilder: (context, index) {
                                    final user = state.candidates[index];
                                    final selected =
                                        state.selectedIds.contains(user.id);
                                    return CheckboxListTile(
                                      value: selected,
                                      onChanged: state.status ==
                                              AssignUsersStatus.saving
                                          ? null
                                          : (_) => _cubit.toggle(user.id),
                                      title: Text(user.fullName),
                                      subtitle: Text(user.email),
                                      dense: true,
                                    );
                                  },
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.rolesCancel),
          ),
          BlocBuilder<AssignUsersCubit, AssignUsersState>(
            builder: (context, state) {
              final saving = state.status == AssignUsersStatus.saving;
              return FilledButton(
                onPressed: saving || state.selectedIds.isEmpty
                    ? null
                    : () async {
                        final result = await _cubit.submit(widget.roleId);
                        if (!context.mounted) return;
                        switch (result) {
                          case Success():
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.rolesAssigned)),
                            );
                            Navigator.pop(context, true);
                          case Failure(:final message):
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(localizeAppMessage(l10n, message))),
                            );
                        }
                      },
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.rolesAssign),
              );
            },
          ),
        ],
      ),
    );
  }
}
