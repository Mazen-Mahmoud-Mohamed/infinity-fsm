import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/app_update/data/services/android_apk_installer_channel.dart';
import 'package:mobile/features/app_update/data/services/app_update_install_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AndroidApkInstallResult', () {
    test('parses session_committed payload', () {
      final result = AndroidApkInstallResult.fromMap({
        'status': 'session_committed',
        'code': 'session_committed',
        'sdkInt': 34,
        'canRequestPackageInstalls': true,
        'requireUserAction': 'not_required_requested',
        'sessionId': 7,
      });
      expect(result.isSessionCommitted, isTrue);
      expect(result.isPermissionRequired, isFalse);
      expect(result.sessionId, 7);
      expect(result.sdkInt, 34);
    });

    test('parses permission_required payload', () {
      final result = AndroidApkInstallResult.fromMap({
        'status': 'permission_required',
        'code': 'install_permission_required',
        'sdkInt': 36,
        'canRequestPackageInstalls': false,
        'requireUserAction': 'required',
      });
      expect(result.isPermissionRequired, isTrue);
      expect(result.isFailed, isFalse);
    });
  });

  group('AndroidApkInstallerChannel', () {
    const channelName = 'com.infinity.fsm/apk_installer';
    late List<MethodCall> calls;

    setUp(() {
      calls = <MethodCall>[];
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel(channelName),
        null,
      );
    });

    test('installApk maps native session_committed result', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel(channelName),
        (call) async {
          calls.add(call);
          if (call.method == 'installApk') {
            return <String, Object?>{
              'status': 'session_committed',
              'code': 'session_committed',
              'sdkInt': 34,
              'canRequestPackageInstalls': true,
              'requireUserAction': 'not_required_requested',
              'sessionId': 3,
            };
          }
          return null;
        },
      );

      final channel = AndroidApkInstallerChannel(
        channel: const MethodChannel(channelName),
        isAndroidOverride: true,
      );
      final result = await channel.installApk('/tmp/app.apk');
      expect(result.isSessionCommitted, isTrue);
      expect(calls.single.method, 'installApk');
      expect(calls.single.arguments, {'apkPath': '/tmp/app.apk'});
    });

    test('canRequestPackageInstalls reads native bool', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel(channelName),
        (call) async {
          calls.add(call);
          return true;
        },
      );

      final channel = AndroidApkInstallerChannel(
        channel: const MethodChannel(channelName),
        isAndroidOverride: true,
      );
      expect(await channel.canRequestPackageInstalls(), isTrue);
      expect(calls.single.method, 'canRequestPackageInstalls');
    });
  });

  group('AppUpdateInstallException', () {
    test('retryable distinguishes permission from hard failures', () {
      const retryable = AppUpdateInstallException(
        'install_permission_required',
        retryable: true,
      );
      const hard = AppUpdateInstallException('install_failed');
      expect(retryable.retryable, isTrue);
      expect(hard.retryable, isFalse);
    });
  });
}
