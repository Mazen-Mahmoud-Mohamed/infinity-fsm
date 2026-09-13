import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/push/windows_notification_identity.dart';

void main() {
  group('Windows notification identity', () {
    test('app name is non-empty product display name', () {
      expect(kWindowsNotificationAppName, 'INFINITY');
      expect(kWindowsNotificationAppName.trim(), isNotEmpty);
    });

    test('production AUMID follows Company.Product form without spaces', () {
      expect(kWindowsNotificationAumid, 'Com.TotalCom.Infinity');
      expect(kWindowsNotificationAumid.contains(' '), isFalse);
      expect(kWindowsNotificationAumid.length, lessThanOrEqualTo(129));
      expect(kWindowsNotificationAumid, contains('.'));
    });

    test('development AUMID is distinct from production', () {
      expect(
        kWindowsNotificationAumidDevelopment,
        'Com.TotalCom.Infinity.Development',
      );
      expect(
        kWindowsNotificationAumidDevelopment,
        isNot(equals(kWindowsNotificationAumid)),
      );
      expect(kWindowsNotificationAumidDevelopment.contains(' '), isFalse);
    });

    test('toast activator GUID matches xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx', () {
      const guid = kWindowsNotificationGuid;
      expect(guid.length, 36);
      expect(guid[8], '-');
      expect(guid[13], '-');
      expect(guid[18], '-');
      expect(guid[23], '-');
      expect(
        RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
        ).hasMatch(guid),
        isTrue,
      );
    });

    test('does not use historical placeholder GUID', () {
      expect(
        kWindowsNotificationGuid,
        isNot(equals('a1b2c3d4-e5f6-7890-abcd-ef1234567890')),
      );
    });

    test('GUID matches installer AppId without braces', () {
      expect(
        kWindowsNotificationGuid.toLowerCase(),
        '04a35421-e8d4-4192-9ad2-abc142836211',
      );
    });

    test('current-build AUMID helper returns a known Infinity AUMID', () {
      final aumid = windowsNotificationAumidForCurrentBuild();
      expect(
        aumid,
        anyOf(
          kWindowsNotificationAumid,
          kWindowsNotificationAumidDevelopment,
        ),
      );
      // Unit tests run in debug mode; on Windows that must be Development.
      if (!kIsWeb &&
          defaultTargetPlatform == TargetPlatform.windows &&
          kDebugMode) {
        expect(aumid, kWindowsNotificationAumidDevelopment);
      }
    });
  });
}
