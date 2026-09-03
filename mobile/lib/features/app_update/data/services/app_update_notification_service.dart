import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mobile/core/push/android_notification_channels.dart';
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/core/services/window_focus_service.dart';
import 'package:mobile/features/app_update/domain/utils/app_update_notification_identity.dart';

/// Local update notifications with deep-link payload to Update Center.
class AppUpdateNotificationService {
  AppUpdateNotificationService({
    FlutterLocalNotificationsPlugin? localNotifications,
    WindowFocusService? windowFocus,
    bool Function()? isPushEnabled,
  })  : _local = localNotifications ?? FlutterLocalNotificationsPlugin(),
        _windowFocus = windowFocus ?? WindowFocusService(),
        _isPushEnabled = isPushEnabled;

  final FlutterLocalNotificationsPlugin _local;
  final WindowFocusService _windowFocus;
  final bool Function()? _isPushEnabled;

  static const _notificationIdBase = 9100;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    _initialized = true;

    if (!Platform.isAndroid && !Platform.isWindows) {
      return;
    }

    if (Platform.isAndroid) {
      // Idempotent with PushNotificationService startup channel creation.
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(AndroidNotificationChannels.updates);
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
    if (_isPushEnabled != null && !_isPushEnabled()) {
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

    const channel = AndroidNotificationChannels.updates;
    await _local.show(
      id: notificationId,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
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
