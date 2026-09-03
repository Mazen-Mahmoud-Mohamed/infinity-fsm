import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Canonical Android notification channels for Infinity FSM.
///
/// [updates] must match the backend FCM `android.notification.channelId`
/// for app-update pushes (`infinity_updates`) so terminated-state system-tray
/// rendering works before any Dart isolate is alive.
abstract final class AndroidNotificationChannels {
  static const String defaultId = 'infinity_default';
  static const String updatesId = 'infinity_updates';

  static const AndroidNotificationChannel defaultChannel =
      AndroidNotificationChannel(
    defaultId,
    'INFINITY',
    description: 'Infinity FSM notifications',
    importance: Importance.defaultImportance,
  );

  static const AndroidNotificationChannel updates =
      AndroidNotificationChannel(
    updatesId,
    'INFINITY Updates',
    description: 'Application update availability',
    importance: Importance.high,
  );

  /// Channels that must exist before any FCM notification can arrive.
  static const List<AndroidNotificationChannel> requiredAtStartup = [
    defaultChannel,
    updates,
  ];
}
