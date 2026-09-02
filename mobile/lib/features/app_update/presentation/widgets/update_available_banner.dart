import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/features/app_update/presentation/cubit/update_center_cubit.dart';
import 'package:mobile/features/app_update/presentation/cubit/update_center_state.dart';

class UpdateAvailableBanner extends StatelessWidget {
  const UpdateAvailableBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UpdateCenterCubit, UpdateCenterState>(
      buildWhen: (previous, current) =>
          previous.showUpdateBanner != current.showUpdateBanner ||
          previous.autoUpdateEnabled != current.autoUpdateEnabled ||
          previous.autoUpdateOwned != current.autoUpdateOwned ||
          previous.latestRelease?.version != current.latestRelease?.version ||
          previous.status != current.status,
      builder: (context, state) {
        if (!state.showUpdateBanner || state.latestRelease == null) {
          return const SizedBox.shrink();
        }

        final l10n = AppLocalizations.of(context);
        final theme = Theme.of(context);
        final primary = theme.colorScheme.primary;
        final version = state.latestRelease!.version;

        return Material(
          color: primary.withValues(alpha: 0.08),
          elevation: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  Icon(Icons.system_update_alt, size: 18, color: primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.appUpdateBannerMessage(version),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push(RoutePaths.settingsUpdates),
                    child: Text(l10n.appUpdateActionUpdate),
                  ),
                  IconButton(
                    tooltip: l10n.appUpdateActionDismiss,
                    onPressed: () =>
                        context.read<UpdateCenterCubit>().dismissUpdateBanner(),
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
