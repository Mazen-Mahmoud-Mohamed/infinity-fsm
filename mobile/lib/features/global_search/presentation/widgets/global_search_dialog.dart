import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/constants/app_breakpoints.dart';
import 'package:mobile/core/constants/app_spacing.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/localization/localize_app_message.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/features/global_search/domain/entities/global_search_hit.dart';
import 'package:mobile/features/global_search/presentation/cubit/global_search_cubit.dart';

class OpenGlobalSearchIntent extends Intent {
  const OpenGlobalSearchIntent();
}

/// Opens the global search palette. Safe to call from shortcuts or icon buttons.
Future<void> openGlobalSearch(BuildContext context) async {
  final auth = context.read<AuthCubit>().state;
  if (auth.status != AuthStatus.authenticated || auth.user == null) {
    return;
  }

  await showDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    builder: (dialogContext) {
      return BlocProvider(
        create: (_) => getIt<GlobalSearchCubit>(),
        child: const GlobalSearchDialog(),
      );
    },
  );
}

class GlobalSearchDialog extends StatefulWidget {
  const GlobalSearchDialog({super.key});

  @override
  State<GlobalSearchDialog> createState() => _GlobalSearchDialogState();
}

class _GlobalSearchDialogState extends State<GlobalSearchDialog> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _openHit(GlobalSearchHit hit) {
    Navigator.of(context).pop();
    context.go(hit.route);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isPhone = AppBreakpoints.isPhone(width);
    final maxWidth = isPhone ? width : 560.0;
    final maxHeight = MediaQuery.sizeOf(context).height * (isPhone ? 0.9 : 0.75);

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isPhone ? AppSpacing.md : AppSpacing.xl,
        vertical: isPhone ? AppSpacing.lg : AppSpacing.xl,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          minWidth: isPhone ? 0 : 420,
        ),
        child: Material(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: l10n.globalSearchHint,
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onChanged: context.read<GlobalSearchCubit>().onQueryChanged,
                      ),
                    ),
                    if (!isPhone)
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.xs),
                        child: Text(
                          l10n.globalSearchShortcutHint,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    IconButton(
                      tooltip: l10n.cancel,
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: theme.colorScheme.outlineVariant),
              Expanded(
                child: BlocBuilder<GlobalSearchCubit, GlobalSearchState>(
                  builder: (context, state) {
                    if (state.isEmptyQuery) {
                      return _MessagePane(
                        icon: Icons.travel_explore_outlined,
                        message: l10n.globalSearchPrompt,
                      );
                    }
                    if (state.status == GlobalSearchStatus.loading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state.status == GlobalSearchStatus.failure) {
                      return _MessagePane(
                        icon: Icons.error_outline,
                        message: state.message == null || state.message!.isEmpty
                            ? l10n.globalSearchFailed
                            : localizeAppMessage(l10n, state.message),
                      );
                    }
                    if (state.hits.isEmpty) {
                      return _MessagePane(
                        icon: Icons.search_off_outlined,
                        message: l10n.globalSearchEmpty,
                      );
                    }

                    final grouped = state.groupedHits;
                    final modules = GlobalSearchModule.values
                        .where((m) => grouped.containsKey(m))
                        .toList(growable: false);

                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      itemCount: modules.length,
                      itemBuilder: (context, index) {
                        final module = modules[index];
                        final hits = grouped[module]!;
                        return _ModuleSection(
                          module: module,
                          hits: hits,
                          onTap: _openHit,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleSection extends StatelessWidget {
  const _ModuleSection({
    required this.module,
    required this.hits,
    required this.onTap,
  });

  final GlobalSearchModule module;
  final List<GlobalSearchHit> hits;
  final ValueChanged<GlobalSearchHit> onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.xs,
          ),
          child: Text(
            _moduleLabel(l10n, module),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        for (final hit in hits)
          ListTile(
            leading: Icon(_moduleIcon(module)),
            title: Text(hit.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: hit.subtitle == null || hit.subtitle!.isEmpty
                ? null
                : Text(
                    hit.subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
            onTap: () => onTap(hit),
          ),
      ],
    );
  }
}

class _MessagePane extends StatelessWidget {
  const _MessagePane({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _moduleLabel(AppLocalizations l10n, GlobalSearchModule module) {
  switch (module) {
    case GlobalSearchModule.users:
      return l10n.usersTitle;
    case GlobalSearchModule.workOrders:
      return l10n.workOrders;
    case GlobalSearchModule.assets:
      return l10n.assets;
    case GlobalSearchModule.inventory:
      return l10n.inventory;
    case GlobalSearchModule.overtime:
      return l10n.overtime;
    case GlobalSearchModule.pm:
      return l10n.pmTitle;
    case GlobalSearchModule.reports:
      return l10n.reportsTitle;
  }
}

IconData _moduleIcon(GlobalSearchModule module) {
  switch (module) {
    case GlobalSearchModule.users:
      return Icons.people_outline;
    case GlobalSearchModule.workOrders:
      return Icons.assignment_outlined;
    case GlobalSearchModule.assets:
      return Icons.precision_manufacturing_outlined;
    case GlobalSearchModule.inventory:
      return Icons.inventory_2_outlined;
    case GlobalSearchModule.overtime:
      return Icons.more_time_outlined;
    case GlobalSearchModule.pm:
      return Icons.build_circle_outlined;
    case GlobalSearchModule.reports:
      return Icons.description_outlined;
  }
}

/// Toolbar action that opens global search (phones / tablets).
class GlobalSearchAction extends StatelessWidget {
  const GlobalSearchAction({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return IconButton(
      tooltip: l10n.globalSearch,
      onPressed: () => openGlobalSearch(context),
      icon: const Icon(Icons.search),
    );
  }
}
