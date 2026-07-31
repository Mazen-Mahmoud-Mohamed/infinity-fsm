import 'package:flutter/material.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';
import 'package:mobile/core/widgets/feature_shell_page.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return FeatureShellPage(
      title: l10n.notifications,
      description: l10n.comingSoon,
    );
  }
}
