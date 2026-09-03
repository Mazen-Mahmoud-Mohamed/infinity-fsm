import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/constants/storage_keys.dart';
import 'package:mobile/core/push/firebase_options.dart';
import 'package:mobile/core/push/notification_navigation.dart';
import 'package:mobile/core/services/window_focus_service.dart';
import 'package:mobile/core/storage/preferences_service.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/app_update/data/datasources/app_update_local_datasource.dart';
import 'package:mobile/features/app_update/domain/utils/app_update_notification_identity.dart';
import 'package:mobile/features/app_update/presentation/cubit/update_center_cubit.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/features/notifications/data/datasources/notifications_api_datasource.dart';
import 'package:mobile/features/notifications/presentation/cubit/notifications_unread_cubit.dart';
import 'package:mobile/shared/presentation/cubit/app_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Top-level background FCM handler (Android).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background/terminated display is handled by the OS when a notification
  // payload is present. Persist app_update dedupe so reconnect reconciliation
  // does not show a second local toast for the same release.
  try {
    final data = message.data;
    final type = (data['type'] ??
            data['entityType'] ??
            data['module'] ??
            data['category'] ??
            '')
        .toString()
        .toLowerCase();
    if (!type.contains('app_update') && type != 'update') {
      return;
    }
    final version = (data['version'] ?? '').toString().trim();
    final build = int.tryParse((data['build'] ?? '').toString().trim()) ?? 0;
    if (version.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'app_update_last_notified_version_v1',
      appUpdateNotificationDedupeKey(version: version, build: build),
    );
  } on Object {
    // Never throw from the background isolate entrypoint.
  }
}

/// Cross-platform push / desktop notification orchestration.
///
/// Android: FCM (+ local notification while foreground)
/// Windows: Socket.IO realtime + local toast while app is open
class PushNotificationService {
  PushNotificationService({
    required NotificationsApiDataSource api,
    required PreferencesService preferences,
    required AppCubit appCubit,
    required AuthCubit authCubit,
    required NotificationsUnreadCubit unreadCubit,
    required GoRouter router,
    required String Function() apiBaseUrlProvider,
    required Future<String?> Function() accessTokenProvider,
    required AppUpdateLocalDataSource appUpdateLocal,
    required UpdateCenterCubit Function() updateCenterCubitProvider,
    WindowFocusService? windowFocus,
  })  : _api = api,
        _preferences = preferences,
        _appCubit = appCubit,
        _authCubit = authCubit,
        _unreadCubit = unreadCubit,
        _router = router,
        _apiBaseUrlProvider = apiBaseUrlProvider,
        _accessTokenProvider = accessTokenProvider,
        _appUpdateLocal = appUpdateLocal,
        _updateCenterCubitProvider = updateCenterCubitProvider,
        _windowFocus = windowFocus ?? WindowFocusService();

  final NotificationsApiDataSource _api;
  final PreferencesService _preferences;
  final AppCubit _appCubit;
  final AuthCubit _authCubit;
  final NotificationsUnreadCubit _unreadCubit;
  final GoRouter _router;
  final String Function() _apiBaseUrlProvider;
  final Future<String?> Function() _accessTokenProvider;
  final AppUpdateLocalDataSource _appUpdateLocal;
  final UpdateCenterCubit Function() _updateCenterCubitProvider;
  final WindowFocusService _windowFocus;

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  io.Socket? _socket;
  String? _currentToken;
  bool _initialized = false;
  bool _permissionAsked = false;
  bool _fcmListenersAttached = false;
  bool _consumingPending = false;
  String? _lastHandledIdempotencyKey;
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onOpenedSub;
  StreamSubscription<String>? _onTokenRefreshSub;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'infinity_default',
    'INFINITY',
    description: 'Infinity FSM notifications',
    importance: Importance.defaultImportance,
  );

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _initLocalNotifications();
    await _captureLaunchNotificationIntents();

    if (!kIsWeb && Platform.isAndroid && DefaultFirebaseOptions.isConfigured) {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        FirebaseMessaging.onBackgroundMessage(
          firebaseMessagingBackgroundHandler,
        );
        await FirebaseMessaging.instance
            .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
        // Capture terminated-state tap before auth finishes.
        await _captureInitialFcmMessage();
        _attachFcmOpenListeners();
      } on Object catch (error) {
        debugPrint('[Push] Firebase init failed: $error');
      }
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const windowsInit = WindowsInitializationSettings(
      appName: 'INFINITY',
      appUserModelId: 'com.totalcom.infinity',
      guid: 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      windows: windowsInit,
    );

    await _local.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        unawaited(_onLocalNotificationTapped(response));
      },
    );

    if (!kIsWeb && Platform.isAndroid) {
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
    }
  }

  /// Local-plugin launch details (foreground local / Windows toast cold cases).
  Future<void> _captureLaunchNotificationIntents() async {
    try {
      final details = await _local.getNotificationAppLaunchDetails();
      if (details?.didNotificationLaunchApp != true) return;
      final payload = details!.notificationResponse?.payload;
      if (payload == null || payload.isEmpty) return;
      final data = _decodePayload(payload);
      if (data != null) {
        await _queueOrNavigate(data, source: 'local_launch');
      }
    } on Object catch (error) {
      debugPrint('[Push] launch details failed: $error');
    }
  }

  Future<void> _captureInitialFcmMessage() async {
    if (kIsWeb || !Platform.isAndroid || !DefaultFirebaseOptions.isConfigured) {
      return;
    }
    try {
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        await _queueOrNavigate(initial.data, source: 'fcm_initial');
      }
    } on Object catch (error) {
      debugPrint('[Push] getInitialMessage failed: $error');
    }
  }

  void _attachFcmOpenListeners() {
    if (_fcmListenersAttached) return;
    if (kIsWeb || !Platform.isAndroid || !DefaultFirebaseOptions.isConfigured) {
      return;
    }
    _fcmListenersAttached = true;

    _onOpenedSub?.cancel();
    _onOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen((message) {
      unawaited(_queueOrNavigate(message.data, source: 'fcm_opened'));
    });
  }

  /// Called after successful authentication.
  Future<void> onAuthenticated() async {
    await initialize();
    await _requestPermissionOnce();
    await _registerFcmTokenIfAndroid();
    await _connectSocket();
    // Router + auth redirects settle before consuming pending deep link.
    await Future<void>.delayed(const Duration(milliseconds: 450));
    await consumePendingNavigation();
  }

  Future<void> onLoggedOut() async {
    await _disconnectSocket();
    final token = _currentToken;
    if (token != null && token.isNotEmpty) {
      await _api.deactivateDeviceToken(token);
    }
    _currentToken = null;
    // Keep pending navigation so a tap while logged out survives re-login.
  }

  /// Applies the Settings push master switch without tearing down auth sockets.
  Future<void> applyPushPreference(bool enabled) async {
    if (!enabled) {
      final token = _currentToken;
      if (token != null && token.isNotEmpty) {
        await _api.deactivateDeviceToken(token);
      }
      return;
    }
    await _registerFcmTokenIfAndroid();
  }

  Future<void> _requestPermissionOnce() async {
    if (_permissionAsked) return;
    _permissionAsked = true;

    if (!kIsWeb && Platform.isAndroid) {
      final android = _local.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();

      if (DefaultFirebaseOptions.isConfigured) {
        try {
          await FirebaseMessaging.instance.requestPermission(
            alert: true,
            badge: true,
            sound: true,
          );
        } on Object catch (_) {}
      }
    }
  }

  Future<void> _registerFcmTokenIfAndroid() async {
    if (kIsWeb || !Platform.isAndroid || !DefaultFirebaseOptions.isConfigured) {
      return;
    }

    try {
      final messaging = FirebaseMessaging.instance;
      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await _upsertToken(token, platform: 'android');
      }

      _onTokenRefreshSub?.cancel();
      _onTokenRefreshSub = messaging.onTokenRefresh.listen((newToken) {
        _upsertToken(newToken, platform: 'android');
      });

      _onMessageSub?.cancel();
      _onMessageSub = FirebaseMessaging.onMessage.listen(_onForegroundMessage);

      _attachFcmOpenListeners();
    } on Object catch (error) {
      debugPrint('[Push] FCM token registration failed: $error');
    }
  }

  Future<void> _upsertToken(String token, {required String platform}) async {
    _currentToken = token;
    final locale = _appCubit.state.localeCode.startsWith('en') ? 'en' : 'ar';
    final deviceId = _preferences.getString(StorageKeys.deviceId);
    final result = await _api.registerDeviceToken(
      token: token,
      platform: platform,
      locale: locale,
      deviceId: deviceId,
    );
    if (result is Failure) {
      debugPrint('[Push] Token register failed: ${result.message}');
    }
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final data = Map<String, dynamic>.from(message.data);
    final appUpdateHandled = await _handleIncomingAppUpdateEvent(data);
    if (appUpdateHandled.suppressLocalToast) {
      unawaited(_unreadCubit.refresh());
      return;
    }

    final notification = message.notification;
    final title = notification?.title ??
        message.data['title']?.toString() ??
        'INFINITY';
    final body = notification?.body ?? message.data['body']?.toString() ?? '';
    await _showLocalNotification(
      title: title,
      body: body,
      payload: jsonEncode(message.data),
    );
    unawaited(_unreadCubit.refresh());
  }

  Future<void> _connectSocket() async {
    await _disconnectSocket();
    final accessToken = await _accessTokenProvider();
    if (accessToken == null || accessToken.isEmpty) return;

    final apiBase = _apiBaseUrlProvider();
    // apiBase ends with /api/v1 — Socket.IO is on the host origin.
    final uri = Uri.parse(apiBase);
    final origin =
        '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';

    try {
      final socket = io.io(
        origin,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .setAuth({'token': accessToken})
            .enableAutoConnect()
            .enableReconnection()
            .build(),
      );
      _socket = socket;

      socket.on('notification:new', (dynamic raw) {
        _onSocketNotification(raw);
      });
    } on Object catch (error) {
      debugPrint('[Push] Socket connect failed: $error');
    }
  }

  Future<void> _disconnectSocket() async {
    final socket = _socket;
    _socket = null;
    if (socket != null) {
      socket.dispose();
    }
  }

  void _onSocketNotification(dynamic raw) {
    Map<String, dynamic> data;
    if (raw is Map) {
      data = Map<String, dynamic>.from(raw);
    } else {
      return;
    }

    final payloadMap = _socketPayloadForNavigation(data);
    unawaited(() async {
      final appUpdateHandled = await _handleIncomingAppUpdateEvent(payloadMap);
      if (appUpdateHandled.suppressLocalToast) {
        unawaited(_unreadCubit.refresh());
        return;
      }

      final locale = _appCubit.state.localeCode.startsWith('en') ? 'en' : 'ar';
      final title = (locale == 'en'
              ? data['titleEn'] ?? data['title']
              : data['titleAr'] ?? data['title'])
          ?.toString() ??
          'INFINITY';
      final body = (locale == 'en'
              ? data['bodyEn'] ?? data['body']
              : data['bodyAr'] ?? data['body'])
          ?.toString() ??
          '';

      // Android already shows via FCM (system or foreground local). Avoid a
      // second toast from Socket.IO while keeping realtime unread refresh.
      final showToast = kIsWeb
          ? false
          : Platform.isWindows ||
              !(Platform.isAndroid && DefaultFirebaseOptions.isConfigured);

      if (showToast) {
        await _showLocalNotification(
          title: title,
          body: body,
          payload: jsonEncode(payloadMap),
        );
      }
      unawaited(_unreadCubit.refresh());
    }());
  }

  /// Marks an app_update event as notified and decides whether local UI toast
  /// should be suppressed (Auto Update ON owns the flow).
  Future<({bool isAppUpdate, bool suppressLocalToast})>
      _handleIncomingAppUpdateEvent(Map<String, dynamic> data) async {
    if (!_isAppUpdatePayload(data)) {
      return (isAppUpdate: false, suppressLocalToast: false);
    }

    final version = (data['version'] ?? '').toString().trim();
    final build = int.tryParse((data['build'] ?? '').toString().trim()) ?? 0;
    if (version.isNotEmpty) {
      final key = appUpdateNotificationDedupeKey(
        version: version,
        build: build,
      );
      final previous = _appUpdateLocal.readLastNotifiedUpdateVersion();
      if (!isSameAppUpdateNotification(
        storedKey: previous,
        version: version,
        build: build,
      )) {
        await _appUpdateLocal.writeLastNotifiedUpdateVersion(key);
      }
    }

    final autoUpdateEnabled = _appUpdateLocal.readAutoUpdateEnabled();
    if (autoUpdateEnabled) {
      unawaited(
        _updateCenterCubitProvider().maybeAutoCheck(
          reason: AppUpdateAutoCheckReason.connectivityRestored,
        ),
      );
      return (isAppUpdate: true, suppressLocalToast: true);
    }

    return (isAppUpdate: true, suppressLocalToast: false);
  }

  bool _isAppUpdatePayload(Map<String, dynamic> data) {
    final type = (data['type'] ??
            data['entityType'] ??
            data['module'] ??
            data['category'] ??
            data['event'] ??
            '')
        .toString()
        .toLowerCase();
    return type.contains('app_update') || type == 'update';
  }

  Map<String, dynamic> _socketPayloadForNavigation(Map<String, dynamic> data) {
    final nested = data['data'] is Map
        ? Map<String, dynamic>.from(data['data'] as Map)
        : <String, dynamic>{};
    return <String, dynamic>{
      'notificationId': data['id']?.toString() ?? '',
      'type': data['entityType'] ?? data['type'] ?? data['module'] ?? '',
      'entityId': data['entityId']?.toString() ?? '',
      'workOrderId': nested['workOrderId']?.toString() ??
          data['workOrderId']?.toString() ??
          '',
      'overtimeId': nested['overtimeId']?.toString() ??
          data['overtimeId']?.toString() ??
          '',
      'event': nested['event']?.toString() ?? data['type']?.toString() ?? '',
      'version': nested['version']?.toString() ?? data['version']?.toString() ?? '',
      'build': nested['build']?.toString() ?? data['build']?.toString() ?? '',
      'channel':
          nested['channel']?.toString() ?? data['channel']?.toString() ?? '',
      'route': nested['route']?.toString() ?? data['route']?.toString() ?? '',
      ...nested,
    };
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_appCubit.state.notificationPushEnabled) {
      return;
    }

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
      ),
      windows: const WindowsNotificationDetails(),
    );

    await _local.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  Future<void> _onLocalNotificationTapped(
    NotificationResponse response,
  ) async {
    final data = _decodePayload(response.payload);
    if (data == null) return;
    await _windowFocus.focusApp();
    await _queueOrNavigate(data, source: 'local_tap');
  }

  Map<String, dynamic>? _decodePayload(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } on Object catch (_) {}
    return null;
  }

  Future<void> _queueOrNavigate(
    Map<String, dynamic> data, {
    required String source,
  }) async {
    await _handleIncomingAppUpdateEvent(data);
    final intent = resolveNotificationNavigation(data);
    debugPrint('[Push] open ($source) → ${intent.route}');

    if (_isAuthenticated) {
      await _executeNavigation(intent);
    } else {
      await _persistPending(intent);
    }
  }

  bool get _isAuthenticated =>
      _authCubit.state.status == AuthStatus.authenticated;

  Future<void> consumePendingNavigation() async {
    if (!_isAuthenticated || _consumingPending) return;
    _consumingPending = true;
    try {
      final intent = _readPending();
      if (intent == null) return;
      await _clearPending();
      await _executeNavigation(intent);
    } finally {
      _consumingPending = false;
    }
  }

  Future<void> _executeNavigation(NotificationNavigationIntent intent) async {
    final key = intent.idempotencyKey;
    if (key != null && key.isNotEmpty && key == _lastHandledIdempotencyKey) {
      await _clearPending();
      return;
    }
    if (key != null && key.isNotEmpty) {
      _lastHandledIdempotencyKey = key;
    }

    await _clearPending();
    await _windowFocus.focusApp();

    try {
      _router.push(intent.route);
    } on Object catch (error) {
      debugPrint('[Push] navigate failed: $error');
      // Allow a later retry for the same intent if push failed.
      if (key != null && key == _lastHandledIdempotencyKey) {
        _lastHandledIdempotencyKey = null;
      }
      return;
    }

    final notificationId = intent.notificationId;
    if (notificationId != null && notificationId.isNotEmpty) {
      unawaited(_markReadAndRefresh(notificationId));
    }
  }

  Future<void> _markReadAndRefresh(String notificationId) async {
    final result = await _api.markAsRead(notificationId);
    if (result is Failure) {
      debugPrint('[Push] markAsRead failed: ${result.message}');
      return;
    }
    unawaited(_unreadCubit.refresh());
  }

  Future<void> _persistPending(NotificationNavigationIntent intent) async {
    await _preferences.setString(
      StorageKeys.pendingNotificationNav,
      jsonEncode(intent.toJson()),
    );
  }

  NotificationNavigationIntent? _readPending() {
    final raw = _preferences.getString(StorageKeys.pendingNotificationNav);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return NotificationNavigationIntent.fromJson(
          Map<String, dynamic>.from(decoded),
        );
      }
    } on Object catch (_) {}
    return null;
  }

  Future<void> _clearPending() async {
    await _preferences.remove(StorageKeys.pendingNotificationNav);
  }

  Future<void> dispose() async {
    await _onMessageSub?.cancel();
    await _onOpenedSub?.cancel();
    await _onTokenRefreshSub?.cancel();
    await _disconnectSocket();
  }
}
