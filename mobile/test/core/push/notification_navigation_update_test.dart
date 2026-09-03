import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/push/notification_navigation.dart';
import 'package:mobile/core/router/route_paths.dart';

void main() {
  group('resolveNotificationNavigation app_update', () {
    test('routes app_update type to Update Center', () {
      final intent = resolveNotificationNavigation({
        'type': 'app_update',
        'version': '1.0.3',
        'build': '4',
        'channel': 'stable',
      });

      expect(intent.route, RoutePaths.settingsUpdates);
    });

    test('routes module app_update to Update Center', () {
      final intent = resolveNotificationNavigation({
        'module': 'app_update',
      });

      expect(intent.route, RoutePaths.settingsUpdates);
    });

    test('routes category app_update to Update Center', () {
      final intent = resolveNotificationNavigation({
        'category': 'app_update',
        'version': '1.0.3',
        'build': '4',
      });

      expect(intent.route, RoutePaths.settingsUpdates);
    });
  });
}
