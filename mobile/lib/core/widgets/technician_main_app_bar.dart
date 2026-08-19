import 'package:flutter/material.dart';
import 'package:mobile/features/settings/presentation/widgets/settings_app_bar_action.dart';

/// Shared app bar for technician main sections.
///
/// Places the Settings control on the [AppBar.leading] slot so it follows
/// reading direction (LTR: physical left, RTL: physical right).
class TechnicianMainAppBar extends StatelessWidget implements PreferredSizeWidget {
  const TechnicianMainAppBar({
    super.key,
    required this.title,
    this.actions = const [],
  });

  final Widget title;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      leading: const SettingsAppBarAction(),
      title: title,
      actions: actions,
    );
  }
}
