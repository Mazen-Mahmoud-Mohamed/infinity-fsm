import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class AppUpdateInstallService {
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

    final result = await OpenFilex.open(apkPath);
    if (result.type != ResultType.done) {
      throw AppUpdateInstallException(result.message);
    }
  }
}

class AppUpdateInstallException implements Exception {
  const AppUpdateInstallException(this.code);

  final String code;

  @override
  String toString() => 'AppUpdateInstallException($code)';
}
