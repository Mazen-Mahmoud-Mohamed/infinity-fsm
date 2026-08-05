import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/features/dashboard/presentation/cubit/executive_dashboard_cubit.dart';
import 'package:mobile/features/notifications/presentation/cubit/notifications_unread_cubit.dart';

/// Dashboard app-bar bell with unread badge.
///
/// Refreshes on dashboard summary updates and when returning from the center.
/// Login / logout / app-restart refresh are handled at the app root.
class NotificationsBellAction extends StatelessWidget {
  const NotificationsBellAction({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasDashboard = _hasDashboardCubit(context);

    Widget bell = BlocBuilder<NotificationsUnreadCubit, NotificationsUnreadState>(
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

    if (!hasDashboard) return bell;

    return BlocListener<ExecutiveDashboardCubit, ExecutiveDashboardState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.summary != current.summary ||
          previous.isRefreshing != current.isRefreshing,
      listener: (context, state) {
        if (state.status == ExecutiveDashboardStatus.success &&
            !state.isRefreshing) {
          context.read<NotificationsUnreadCubit>().refresh();
        }
      },
      child: bell,
    );
  }

  bool _hasDashboardCubit(BuildContext context) {
    try {
      context.read<ExecutiveDashboardCubit>();
      return true;
    } on Object {
      return false;
    }
  }
}
