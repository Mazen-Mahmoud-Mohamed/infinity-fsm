import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/config/app_config.dart';
import 'package:mobile/core/services/app_package_info.dart';
import 'package:mobile/features/settings/presentation/widgets/settings_layout.dart';
import 'package:mobile/features/settings/presentation/widgets/settings_package_version_rows.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  setUp(() {
    AppPackageInfo.debugResetCache();
    PackageInfo.setMockInitialValues(
      appName: 'INFINITY',
      packageName: 'com.totalcom.infinity',
      version: '1.0.4',
      buildNumber: '5',
      buildSignature: '',
    );
  });

  tearDown(AppPackageInfo.debugResetCache);

  testWidgets('SettingsPackageVersionRows shows package version and build',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SettingsPackageVersionRows(
            versionLabel: 'Version',
            buildLabel: 'Build',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(SettingsInfoRow), findsNWidgets(2));
    expect(find.text('1.0.4'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('SettingsPackageVersionRows falls back before package loads',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SettingsPackageVersionRows(
            versionLabel: 'Version',
            buildLabel: 'Build',
          ),
        ),
      ),
    );

    // First frame may still be waiting on PackageInfo.
    expect(
      find.text(AppConfig.appVersionFallback),
      findsWidgets,
    );
  });
}
