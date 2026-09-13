import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mobile/core/constants/storage_keys.dart';
import 'package:mobile/core/push/android_notification_channels.dart';
import 'package:mobile/core/push/firebase_options.dart';
import 'package:mobile/core/push/local_notification_id.dart';
import 'package:mobile/core/push/notification_deep_link_coordinator.dart';
import 'package:mobile/core/push/notification_navigation.dart';
import 'package:mobile/core/push/pending_notification_store.dart';
import 'package:mobile/core/push/windows_notification_identity.dart';
import 'package:mobile/core/services/window_focus_service.dart';
import 'package:mobile/core/storage/preferences_service.dart';
import 'package:mobile/core/utils/result.dart';
import 'package:mobile/features/app_update/data/datasources/app_update_local_datasource.dart';
import 'package:mobile/features/app_update/domain/utils/app_update_notification_identity.dart';
import 'package:mobile/features/app_update/presentation/cubit/update_center_cubit.dart';
import 'package:mobile/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mobile/features/notifications/data/datasources/notifications_api_datasource.dart';
import 'package:mobile/features/notifications/data/datasources/notifications_local_datasource.dart';
import 'package:mobile/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:mobile/features/notifications/presentation/cubit/notifications_unread_cubit.dart';
import 'package:mobile/features/settings/domain/entities/settings_entities.dart';
import 'package:mobile/features/settings/domain/services/technician_interface_notification_policy.dart';
import 'package:mobile/features/settings/presentation/cubit/technician_interface_cubits.dart';
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
    required NotificationsLocalDataSource localReadIds,
    required NotificationDeepLinkCoordinator deepLinks,
    required String Function() apiBaseUrlProvider,
    required Future<String?> Function() accessTokenProvider,
    required AppUpdateLocalDataSource appUpdateLocal,
    required UpdateCenterCubit Function() updateCenterCubitProvider,
    required NotificationsCubit Function() inboxCubitProvider,
    required TechnicianInterfaceCubit technicianInterfaceCubit,
    PendingNotificationStore? pending,
    WindowFocusService? windowFocus,
  })  : _api = api,
        _preferences = preferences,
        _appCubit = appCubit,
        _authCubit = authCubit,
        _unreadCubit = unreadCubit,
        _inboxCubitProvider = inboxCubitProvider,
        _technicianInterfaceCubit = technicianInterfaceCubit,
        _localReadIds = localReadIds,
        _deepLinks = deepLinks,
        _apiBaseUrlProvider = apiBaseUrlProvider,
        _accessTokenProvider = accessTokenProvider,
        _appUpdateLocal = appUpdateLocal,
        _updateCenterCubitProvider = updateCenterCubitProvider,
        _windowFocus = windowFocus ?? WindowFocusService(),
        _pending = pending ?? PendingNotificationStore(preferences);

  final NotificationsApiDataSource _api;
  final PreferencesService _preferences;
  final AppCubit _appCubit;
  final AuthCubit _authCubit;
  final NotificationsUnreadCubit _unreadCubit;
  final NotificationsCubit Function() _inboxCubitProvider;
  final TechnicianInterfaceCubit _technicianInterfaceCubit;
  final NotificationsLocalDataSource _localReadIds;
  final NotificationDeepLinkCoordinator _deepLinks;
  final String Function() _apiBaseUrlProvider;
  final Future<String?> Function() _accessTokenProvider;
  final AppUpdateLocalDataSource _appUpdateLocal;
  final UpdateCenterCubit Function() _updateCenterCubitProvider;
  final WindowFocusService _windowFocus;
  final PendingNotificationStore _pending;

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  io.Socket? _socket;
  String? _currentToken;
  String? _boundUserId;
  bool _initialized = false;
  bool _localPluginReady = false;
  bool _permissionAsked = false;
  bool _fcmListenersAttached = false;
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onOpenedSub;
  StreamSubscription<String>? _onTokenRefreshSub;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await _initLocalNotifications();
    } on Object catch (error) {
      _localPluginReady = false;
      debugPrint('[Push] local notification init failed (non-fatal): $error');
    }

    try {
      await _captureLaunchNotificationIntents();
    } on Object catch (error) {
      debugPrint('[Push] launch intent capture failed (non-fatal): $error');
    }

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
    final windowsInit = WindowsInitializationSettings(
      appName: kWindowsNotificationAppName,
      appUserModelId: windowsNotificationAumidForCurrentBuild(),
      guid: kWindowsNotificationGuid,
    );
    final initSettings = InitializationSettings(
      android: androidInit,
      windows: windowsInit,
    );

    if (!kIsWeb && Platform.isWindows) {
      debugPrint(
        '[Push] Windows local notifications initializing '
        'aumid=${windowsNotificationAumidForCurrentBuild()} '
        'guid=$kWindowsNotificationGuid',
      );
    }

    final initialized = await _local.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        unawaited(_onLocalNotificationTapped(response));
      },
    );
    _localPluginReady = initialized == true;

    if (!kIsWeb && Platform.isWindows) {
      debugPrint(
        '[Push] Windows local notifications initialized='
        '$_localPluginReady aumid=${windowsNotificationAumidForCurrentBuild()}',
      );
      if (!_localPluginReady) {
        debugPrint(
          '[Push] Windows toast init returned false — notification '
          'platform unavailable or activator registration failed. '
          'App continues without local toasts.',
        );
      }
    }

    if (!kIsWeb && Platform.isAndroid && _localPluginReady) {
      final androidPlugin = _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      // Create both channels before any FCM message can arrive. Android's
      // createNotificationChannel is idempotent for the same channel id, so
      // AppUpdateNotificationService may safely recreate `infinity_updates`.
      for (final channel in AndroidNotificationChannels.requiredAtStartup) {
        await androidPlugin?.createNotificationChannel(channel);
      }
    }
  }

  /// Local-plugin launch details (foreground local / Windows toast cold cases).
  Future<void> _captureLaunchNotificationIntents() async {
    if (!_localPluginReady) return;
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
    final userId = _authCubit.state.user?.id;
    if (userId != _boundUserId) {
      _boundUserId = userId;
    }
    await _localReadIds.bindUser(userId);
    try {
      _inboxCubitProvider().bindAuthenticatedUser(userId);
    } on Object catch (_) {}
    await _requestPermissionOnce();
    await _registerFcmTokenIfAndroid();
    await _connectSocket();
    // Event-driven: wait for MainNavigationShell readiness, not a fixed delay.
    await consumePendingNavigation();
  }

  Future<void> onLoggedOut() async {
    await _tearDownFcmListeners();
    await _disconnectSocket();
    final token = _currentToken;
    if (token != null && token.isNotEmpty) {
      await _api.deactivateDeviceToken(token);
    }
    _currentToken = null;
    _boundUserId = null;
    _deepLinks.clearSession();
    await _localReadIds.clearSession();
    await _pending.clear();
    try {
      _inboxCubitProvider().reset();
    } on Object catch (_) {}
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

    // Keep unread refresh authoritative; suppress toast only for TI-hidden features.
    if (!_shouldShowForegroundToast(data)) {
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
            .enableForceNew()
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionDelayMax(10000)
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

    final payloadMap = socketPayloadForNavigation(data);
    final capturedUserId = _authCubit.state.user?.id;
    unawaited(() async {
      final appUpdateHandled = await _handleIncomingAppUpdateEvent(payloadMap);
      if (capturedUserId != null &&
          capturedUserId.isNotEmpty &&
          capturedUserId == _boundUserId) {
        _ingestInboxFromSocket(data, capturedUserId: capturedUserId);
      }
      if (appUpdateHandled.suppressLocalToast) {
        unawaited(_unreadCubit.refresh());
        return;
      }

      if (!_shouldShowForegroundToast(payloadMap)) {
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

  /// Foreground/local toast policy for Technician Interface feature gates.
  ///
  /// Residual: server unread count is unchanged, so the badge may still
  /// include items filtered from the technician inbox list.
  bool _shouldShowForegroundToast(Map<String, dynamic> data) {
    return TechnicianInterfaceNotificationPolicy.isPayloadVisible(
      user: _authCubit.state.user,
      config: _technicianInterfaceConfigOrNull(),
      data: data,
    );
  }

  TechnicianInterfaceConfig? _technicianInterfaceConfigOrNull() {
    final state = _technicianInterfaceCubit.state;
    return state.isReady ? state.config : null;
  }

  void _ingestInboxFromSocket(
    Map<String, dynamic> data, {
    required String? capturedUserId,
  }) {
    try {
      final cubit = _inboxCubitProvider();
      if (cubit.isClosed) return;
      cubit.ingestRealtimePayload(
        data,
        localeCode: _appCubit.state.localeCode,
        authenticatedUserId: capturedUserId,
      );
    } on Object catch (error) {
      debugPrint('[Push] inbox ingest failed: $error');
    }
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

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_localPluginReady) return;
    if (!_appCubit.state.notificationPushEnabled) {
      return;
    }

    const channel = AndroidNotificationChannels.defaultChannel;
    final data = _decodePayload(payload) ?? const <String, dynamic>{};
    final notificationId = (data['notificationId'] ?? data['id'] ?? '')
        .toString()
        .trim();
    final tag = notificationId.isEmpty ? null : notificationId;
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
        tag: tag,
      ),
      windows: const WindowsNotificationDetails(),
    );

    try {
      await _local.show(
        id: localNotificationIdFor(
          notificationId: notificationId,
          fallbackSeed: payload ?? '$title|$body',
        ),
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
    } on Object catch (error) {
      debugPrint('[Push] local notification show failed (non-fatal): $error');
    }
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

    final ownerId = _ownerIdForPending(data);
    final owned = intent.copyWith(userId: ownerId);

    if (_isAuthenticated) {
      await _deepLinks.open(
        intent: owned,
        user: _authCubit.state.user,
        config: _technicianInterfaceConfigOrNull(),
        source: source,
      );
      final notificationId = owned.notificationId;
      if (notificationId != null && notificationId.isNotEmpty) {
        unawaited(_markReadAndRefresh(notificationId));
      }
    } else {
      await _pending.persist(owned);
    }
  }

  String? _ownerIdForPending(Map<String, dynamic> data) {
    final authenticated = _authCubit.state.user?.id.trim();
    if (authenticated != null && authenticated.isNotEmpty) {
      return authenticated;
    }
    final recipient = data['recipientUserId']?.toString().trim() ?? '';
    if (recipient.isNotEmpty) return recipient;
    return null;
  }

  bool get _isAuthenticated =>
      _authCubit.state.status == AuthStatus.authenticated;

  Future<void> consumePendingNavigation() async {
    if (!_isAuthenticated) return;
    await _deepLinks.flushAfterAuthentication(
      userId: _authCubit.state.user?.id,
      user: _authCubit.state.user,
      config: _technicianInterfaceConfigOrNull(),
    );
  }

  Future<void> _markReadAndRefresh(String notificationId) async {
    final result = await _api.markAsRead(notificationId);
    if (result is Failure) {
      debugPrint('[Push] markAsRead failed: ${result.message}');
      return;
    }
    unawaited(_unreadCubit.refresh());
  }

  Future<void> _tearDownFcmListeners() async {
    await _onMessageSub?.cancel();
    _onMessageSub = null;
    await _onOpenedSub?.cancel();
    _onOpenedSub = null;
    await _onTokenRefreshSub?.cancel();
    _onTokenRefreshSub = null;
    _fcmListenersAttached = false;
  }

  Future<void> dispose() async {
    await _tearDownFcmListeners();
    await _disconnectSocket();
  }
}
