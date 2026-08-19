import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/router/route_paths.dart';

/// Opens the existing settings hub from a main-section app bar.
class SettingsAppBarAction extends StatelessWidget {
  const SettingsAppBarAction({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return IconButton(
      tooltip: l10n.settings,
      onPressed: () => context.go(RoutePaths.settings),
      icon: const Icon(Icons.settings_outlined),
    );
  }
}
