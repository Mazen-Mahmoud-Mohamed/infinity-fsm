import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

/// Structured result from the native Android PackageInstaller channel.
class AndroidApkInstallResult {
  const AndroidApkInstallResult({
    required this.status,
    required this.code,
    required this.sdkInt,
    required this.canRequestPackageInstalls,
    required this.requireUserAction,
    this.sessionId,
  });

  factory AndroidApkInstallResult.fromMap(Map<dynamic, dynamic> map) {
    return AndroidApkInstallResult(
      status: map['status']?.toString() ?? 'failed',
      code: map['code']?.toString() ?? 'install_failed',
      sdkInt: _asInt(map['sdkInt']) ?? 0,
      canRequestPackageInstalls: map['canRequestPackageInstalls'] == true,
      requireUserAction: map['requireUserAction']?.toString() ?? 'required',
      sessionId: _asInt(map['sessionId']),
    );
  }

  final String status;
  final String code;
  final int sdkInt;
  final bool canRequestPackageInstalls;
  final String requireUserAction;
  final int? sessionId;

  bool get isPermissionRequired =>
      status == 'permission_required' || code == 'install_permission_required';

  bool get isSessionCommitted => status == 'session_committed';

  bool get isFailed => status == 'failed';

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}

/// Flutter ↔ Android bridge for PackageInstaller-based APK updates.
class AndroidApkInstallerChannel {
  AndroidApkInstallerChannel({
    MethodChannel? channel,
    Logger? logger,
    bool? isAndroidOverride,
  })  : _channel =
            channel ?? const MethodChannel('com.infinity.fsm/apk_installer'),
        _logger = logger ?? Logger(),
        _isAndroidOverride = isAndroidOverride;

  final MethodChannel _channel;
  final Logger _logger;
  final bool? _isAndroidOverride;

  bool get _isAndroid => _isAndroidOverride ?? (!kIsWeb && Platform.isAndroid);

  Future<bool> canRequestPackageInstalls() async {
    if (!_isAndroid) return false;
    try {
      final value = await _channel.invokeMethod<bool>('canRequestPackageInstalls');
      return value ?? false;
    } on PlatformException catch (error) {
      _logger.w(
        'canRequestPackageInstalls failed: ${error.code}',
      );
      return false;
    }
  }

  Future<void> openUnknownSourcesSettings() async {
    if (!_isAndroid) return;
    await _channel.invokeMethod<void>('openUnknownSourcesSettings');
  }

  Future<AndroidApkInstallResult> installApk(String apkPath) async {
    if (!_isAndroid) {
      return const AndroidApkInstallResult(
        status: 'failed',
        code: 'unsupported_platform',
        sdkInt: 0,
        canRequestPackageInstalls: false,
        requireUserAction: 'required',
      );
    }

    try {
      final raw = await _channel.invokeMethod<dynamic>(
        'installApk',
        <String, dynamic>{'apkPath': apkPath},
      );
      if (raw is Map) {
        final result = AndroidApkInstallResult.fromMap(raw);
        _logger.i(
          'Android APK install result status=${result.status} '
          'code=${result.code} sdk=${result.sdkInt} '
          'canInstall=${result.canRequestPackageInstalls} '
          'requireUserAction=${result.requireUserAction} '
          'sessionId=${result.sessionId}',
        );
        return result;
      }
      return const AndroidApkInstallResult(
        status: 'failed',
        code: 'install_failed',
        sdkInt: 0,
        canRequestPackageInstalls: false,
        requireUserAction: 'required',
      );
    } on PlatformException catch (error) {
      _logger.w('installApk platform error: ${error.code}');
      return AndroidApkInstallResult(
        status: 'failed',
        code: error.code.isEmpty ? 'install_failed' : error.code,
        sdkInt: 0,
        canRequestPackageInstalls: false,
        requireUserAction: 'required',
      );
    }
  }
}
