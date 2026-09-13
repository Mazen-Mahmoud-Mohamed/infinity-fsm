import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/push/android_notification_channels.dart';
import 'package:mobile/core/push/windows_notification_identity.dart';

/// Documents fail-safe Windows notification contracts that must not regress.
///
/// Native WinRT abort paths are covered by the vendored
/// `flutter_local_notifications_windows` FFI wrappers (return false / log,
/// never throw across FFI). This suite locks Dart-side identity and the
/// Android channel surface that must remain unchanged.
void main() {
  group('Windows notification fail-safe contracts', () {
    test('identity constants remain stable production values', () {
      expect(kWindowsNotificationAppName, 'INFINITY');
      expect(kWindowsNotificationAumid, 'Com.TotalCom.Infinity');
      expect(
        kWindowsNotificationAumidDevelopment,
        'Com.TotalCom.Infinity.Development',
      );
      expect(
        kWindowsNotificationGuid,
        '04a35421-e8d4-4192-9ad2-abc142836211',
      );
    });

    test('Android startup channels are unchanged', () {
      final ids = AndroidNotificationChannels.requiredAtStartup
          .map((c) => c.id)
          .toList();
      expect(ids, contains(AndroidNotificationChannels.defaultChannel.id));
      expect(ids, contains(AndroidNotificationChannels.updates.id));
    });
  });
}
