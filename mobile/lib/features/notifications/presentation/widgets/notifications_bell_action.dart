import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/features/notifications/presentation/cubit/notifications_unread_cubit.dart';

/// Dashboard app-bar bell with unread badge.
///
/// Unread comes only from [NotificationsUnreadCubit] (dedicated unread API).
/// Login / logout / app-restart / returning from the center refresh the cubit.
class NotificationsBellAction extends StatelessWidget {
  const NotificationsBellAction({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<NotificationsUnreadCubit, NotificationsUnreadState>(
      builder: (context, state) {
        final icon = IconButton(
          tooltip: l10n.notifications,
          onPressed: () async {
            await context.push(RoutePaths.notifications);
            if (context.mounted) {
              await context.read<NotificationsUnreadCubit>().refresh();
            }
          },
          icon: const Icon(Icons.notifications_outlined),
        );

        if (state.count <= 0) return icon;

        return Badge(
          label: Text(state.count > 99 ? '99+' : '${state.count}'),
          child: icon,
        );
      },
    );
  }
}
