import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mobile/features/app_update/data/services/android_apk_installer_channel.dart';
import 'package:path_provider/path_provider.dart';

class AppUpdateInstallService {
  AppUpdateInstallService({
    AndroidApkInstallerChannel? androidInstaller,
  }) : _androidInstaller = androidInstaller ?? AndroidApkInstallerChannel();

  final AndroidApkInstallerChannel _androidInstaller;

  /// In-memory throttle so Auto Update resume does not spam Settings.
  DateTime? _lastUnknownSourcesPromptAt;
  static const _unknownSourcesPromptCooldown = Duration(minutes: 2);

  Future<void> install({
    required String filePath,
    required String platformKey,
  }) async {
    if (kIsWeb) {
      throw const AppUpdateInstallException('unsupported_platform');
    }

    switch (platformKey) {
      case 'windows':
        await _installWindows(filePath);
      case 'android':
        await _installAndroid(filePath);
      default:
        throw const AppUpdateInstallException('unsupported_platform');
    }
  }

  Future<void> _installWindows(String installerPath) async {
    if (!Platform.isWindows) {
      throw const AppUpdateInstallException('unsupported_platform');
    }

    final file = File(installerPath);
    if (!await file.exists()) {
      throw const AppUpdateInstallException('missing_artifact');
    }

    final tempDir = await getTemporaryDirectory();
    final batchFile = File('${tempDir.path}/infinity_apply_update.bat');
    final escapedPath = installerPath.replaceAll('"', '""');
    await batchFile.writeAsString(
      '@echo off\r\n'
      'timeout /t 2 /nobreak > nul\r\n'
      'start "" "$escapedPath"\r\n',
    );

    await Process.start(
      'cmd.exe',
      ['/c', batchFile.path],
      mode: ProcessStartMode.detached,
    );

    await SystemNavigator.pop();
  }

  Future<void> _installAndroid(String apkPath) async {
    if (!Platform.isAndroid) {
      throw const AppUpdateInstallException('unsupported_platform');
    }

    final file = File(apkPath);
    if (!await file.exists()) {
      throw const AppUpdateInstallException('missing_artifact');
    }
    final length = await file.length();
    if (length <= 0) {
      throw const AppUpdateInstallException('invalid_apk');
    }

    final canInstall = await _androidInstaller.canRequestPackageInstalls();
    if (!canInstall) {
      await _maybeOpenUnknownSourcesSettings();
      throw const AppUpdateInstallException(
        'install_permission_required',
        retryable: true,
      );
    }

    final result = await _androidInstaller.installApk(apkPath);

    if (result.isPermissionRequired) {
      await _maybeOpenUnknownSourcesSettings();
      throw const AppUpdateInstallException(
        'install_permission_required',
        retryable: true,
      );
    }

    if (result.isSessionCommitted) {
      // Session committed. OS may install without UI or show confirmation.
      // Never claim silent success beyond "installer handoff accepted".
      return;
    }

    throw AppUpdateInstallException(
      result.code.isEmpty ? 'install_failed' : result.code,
    );
  }

  Future<void> _maybeOpenUnknownSourcesSettings() async {
    final now = DateTime.now().toUtc();
    final last = _lastUnknownSourcesPromptAt;
    if (last != null && now.difference(last) < _unknownSourcesPromptCooldown) {
      return;
    }
    _lastUnknownSourcesPromptAt = now;
    await _androidInstaller.openUnknownSourcesSettings();
  }
}

class AppUpdateInstallException implements Exception {
  const AppUpdateInstallException(this.code, {this.retryable = false});

  final String code;

  /// When true, Auto Update must not treat this as a permanent install attempt
  /// (e.g. user still needs to grant install-unknown-apps permission).
  final bool retryable;

  @override
  String toString() => 'AppUpdateInstallException($code)';
}
