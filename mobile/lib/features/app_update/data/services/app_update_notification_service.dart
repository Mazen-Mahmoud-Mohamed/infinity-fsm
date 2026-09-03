import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/core/services/window_focus_service.dart';
import 'package:mobile/features/app_update/domain/utils/app_update_notification_identity.dart';

/// Local update notifications with deep-link payload to Update Center.
class AppUpdateNotificationService {
  AppUpdateNotificationService({
    FlutterLocalNotificationsPlugin? localNotifications,
    WindowFocusService? windowFocus,
  })  : _local = localNotifications ?? FlutterLocalNotificationsPlugin(),
        _windowFocus = windowFocus ?? WindowFocusService();

  final FlutterLocalNotificationsPlugin _local;
  final WindowFocusService _windowFocus;

  static const _channelId = 'infinity_updates';
  static const _notificationIdBase = 9100;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    _initialized = true;

    if (!Platform.isAndroid && !Platform.isWindows) {
      return;
    }

    if (Platform.isAndroid) {
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _channelId,
              'INFINITY Updates',
              description: 'Application update availability',
              importance: Importance.high,
            ),
          );
    }
  }

  Future<void> showUpdateAvailable({
    required String version,
    required int build,
    required String title,
    required String body,
    required String updateActionLabel,
  }) async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isWindows)) {
      return;
    }

    await initialize();

    final dedupeKey = appUpdateNotificationDedupeKey(
      version: version,
      build: build,
    );

    final payload = jsonEncode({
      'type': 'app_update',
      'entityType': 'app_update',
      'module': 'app_update',
      'category': 'app_update',
      'version': version,
      'build': build.toString(),
      'route': RoutePaths.settingsUpdates,
      'dedupeKey': dedupeKey,
    });

    final notificationId = _notificationIdBase + dedupeKey.hashCode.abs() % 100;

    await _local.show(
      id: notificationId,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'INFINITY Updates',
          channelDescription: 'Application update availability',
          importance: Importance.high,
          priority: Priority.high,
          tag: dedupeKey,
          actions: [
            AndroidNotificationAction(
              'update',
              updateActionLabel,
              showsUserInterface: true,
            ),
          ],
        ),
        windows: const WindowsNotificationDetails(),
      ),
      payload: payload,
    );
  }

  Future<void> focusAppWindow() => _windowFocus.focusApp();
}
