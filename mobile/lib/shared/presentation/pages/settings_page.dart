import 'package:flutter/material.dart';
import 'package:mobile/features/settings/presentation/pages/settings_hub_page.dart';

/// Backward-compatible entry for `/settings` route.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) => const SettingsHubPage();
}
