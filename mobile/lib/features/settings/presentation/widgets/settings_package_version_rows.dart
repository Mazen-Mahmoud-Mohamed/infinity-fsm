import 'package:flutter/material.dart';
import 'package:mobile/core/config/app_config.dart';
import 'package:mobile/core/services/app_package_info.dart';
import 'package:mobile/features/settings/presentation/widgets/settings_layout.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Settings info rows that always show the installed package version/build.
class SettingsPackageVersionRows extends StatelessWidget {
  const SettingsPackageVersionRows({
    super.key,
    required this.versionLabel,
    required this.buildLabel,
    this.combined = false,
    this.combinedLabel,
  });

  final String versionLabel;
  final String buildLabel;
  final bool combined;
  final String? combinedLabel;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: AppPackageInfo.load(),
      builder: (context, snapshot) {
        final info = snapshot.data;
        final version = info?.version ?? AppConfig.appVersionFallback;
        final build = info?.buildNumber ?? AppConfig.buildNumberFallback;
        if (combined) {
          return SettingsInfoRow(
            label: combinedLabel ?? versionLabel,
            value: '$version+$build',
          );
        }
        return Column(
          children: [
            SettingsInfoRow(label: versionLabel, value: version),
            SettingsInfoRow(label: buildLabel, value: build),
          ],
        );
      },
    );
  }
}
