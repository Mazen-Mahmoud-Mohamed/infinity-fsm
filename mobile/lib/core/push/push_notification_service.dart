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
import 'package:mobile/core/router/route_paths.dart';
import 'package:mobile/core/storage/preferences_service.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/notifications/data/datasources/notifications_api_datasource.dart';
import 'package:mobile/features/notifications/presentation/cubit/notifications_unread_cubit.dart';
import 'package:mobile/shared/presentation/cubit/app_cubit.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Top-level background FCM handler (Android).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background/terminated display is handled by the OS when a notification
  // payload is present. Data-only messages are ignored here intentionally.
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
    required NotificationsUnreadCubit unreadCubit,
    required GoRouter router,
    required String Function() apiBaseUrlProvider,
    required Future<String?> Function() accessTokenProvider,
  })  : _api = api,
        _preferences = preferences,
        _appCubit = appCubit,
        _unreadCubit = unreadCubit,
        _router = router,
        _apiBaseUrlProvider = apiBaseUrlProvider,
        _accessTokenProvider = accessTokenProvider;

  final NotificationsApiDataSource _api;
  final PreferencesService _preferences;
  final AppCubit _appCubit;
  final NotificationsUnreadCubit _unreadCubit;
  final GoRouter _router;
  final String Function() _apiBaseUrlProvider;
  final Future<String?> Function() _accessTokenProvider;

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  io.Socket? _socket;
  String? _currentToken;
  bool _initialized = false;
  bool _permissionAsked = false;
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
        _handlePayload(response.payload);
      },
    );

    if (!kIsWeb && Platform.isAndroid) {
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
    }
  }

  /// Called after successful authentication.
  Future<void> onAuthenticated() async {
    await initialize();
    await _requestPermissionOnce();
    await _registerFcmTokenIfAndroid();
    await _connectSocket();
    await _consumeInitialMessage();
  }

  Future<void> onLoggedOut() async {
    await _disconnectSocket();
    final token = _currentToken;
    if (token != null && token.isNotEmpty) {
      await _api.deactivateDeviceToken(token);
    }
    _currentToken = null;
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

      _onOpenedSub?.cancel();
      _onOpenedSub =
          FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpened);
    } on Object catch (error) {
      debugPrint('[Push] FCM token registration failed: $error');
    }
  }

  Future<void> _consumeInitialMessage() async {
    if (kIsWeb || !Platform.isAndroid || !DefaultFirebaseOptions.isConfigured) {
      return;
    }
    try {
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        // Delay until router is ready.
        Future<void>.delayed(const Duration(milliseconds: 600), () {
          _navigateFromData(initial.data);
        });
      }
    } on Object catch (_) {}
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

  void _onMessageOpened(RemoteMessage message) {
    _navigateFromData(message.data);
  }

  Future<void> _connectSocket() async {
    await _disconnectSocket();
    final accessToken = await _accessTokenProvider();
    if (accessToken == null || accessToken.isEmpty) return;

    final apiBase = _apiBaseUrlProvider();
    // apiBase ends with /api/v1 — Socket.IO is on the host origin.
    final uri = Uri.parse(apiBase);
    final origin = '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';

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

    // Windows (and Android foreground via socket) show a desktop/local toast.
    unawaited(
      _showLocalNotification(
        title: title,
        body: body,
        payload: jsonEncode({
          'notificationId': data['id']?.toString() ?? '',
          'type': data['entityType'] ?? data['type'] ?? data['module'],
          'entityId': data['entityId']?.toString() ?? '',
          'workOrderId': data['data'] is Map
              ? (data['data'] as Map)['workOrderId']?.toString()
              : data['workOrderId']?.toString(),
          'overtimeId': data['data'] is Map
              ? (data['data'] as Map)['overtimeId']?.toString()
              : data['overtimeId']?.toString(),
          ...Map<String, dynamic>.from(
            data['data'] is Map ? data['data'] as Map : const {},
          ),
        }),
      ),
    );
    unawaited(_unreadCubit.refresh());
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
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

  void _handlePayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      final data = jsonDecode(payload);
      if (data is Map) {
        _navigateFromData(Map<String, dynamic>.from(data));
      }
    } on Object catch (_) {}
  }

  void _navigateFromData(Map<String, dynamic> data) {
    final type = (data['type'] ?? data['entityType'] ?? '').toString();
    final entityId = (data['entityId'] ??
            data['workOrderId'] ??
            data['overtimeId'] ??
            '')
        .toString();

    if (entityId.isEmpty) {
      _router.push(RoutePaths.notifications);
      return;
    }

    if (type.contains('work_order') || type == 'work_orders') {
      _router.push(RoutePaths.workOrderDetail(entityId));
      return;
    }
    if (type.contains('overtime')) {
      _router.push(RoutePaths.overtimeAdminDetail(entityId));
      return;
    }
    _router.push(RoutePaths.notifications);
  }

  Future<void> dispose() async {
    await _onMessageSub?.cancel();
    await _onOpenedSub?.cancel();
    await _onTokenRefreshSub?.cancel();
    await _disconnectSocket();
  }
}
