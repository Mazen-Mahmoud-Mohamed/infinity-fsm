class StorageKeys {
  StorageKeys._();

  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String deviceId = 'device_id';
  static const String rememberedEmail = 'remembered_email';
  static const String rememberMe = 'remember_me';
  static const String tokenExpiresAt = 'token_expires_at';
  static const String currentUser = 'current_user';
  static const String locale = 'locale';
  static const String themeMode = 'theme_mode';

  /// Optional admin override for the Dio API base URL (`…/api/v1`).
  static const String customApiBaseUrl = 'custom_api_base_url';

  /// Last successful unauthenticated health probe (UTC ms).
  static const String lastSuccessfulApiConnectionMs =
      'last_successful_api_connection_ms';

  /// Device clock integrity anchors (UTC milliseconds since epoch).
  static const String lastSyncedServerUtcMs = 'last_synced_server_utc_ms';
  static const String lastSyncedDeviceUtcMs = 'last_synced_device_utc_ms';
  static const String lastSyncedMonoMs = 'last_synced_mono_ms';
  static const String lastAttendanceUtcMs = 'last_attendance_utc_ms';
  static const String securityEventQueue = 'security_event_queue';
  static const String pendingGpsAddressQueue = 'pending_gps_address_queue';
}
