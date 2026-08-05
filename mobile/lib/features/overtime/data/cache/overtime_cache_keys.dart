class OvertimeCacheKeys {
  OvertimeCacheKeys._();

  static const String runningSession = 'overtime_running_session';
  static const String history = 'overtime_history';
  static const String pendingQueue = 'overtime_pending_queue';

  /// Maps optimistic `local-*` session ids → server ids across sync passes.
  static const String localIdMap = 'overtime_local_id_map';

  /// Per-action photo payload (base64). Kept outside the queue JSON so
  /// four-stage offline sessions do not blow SharedPreferences size limits.
  static const String pendingPhotoPrefix = 'overtime_pending_photo_';

  static String pendingPhotoKey(String actionId) =>
      '$pendingPhotoPrefix$actionId';

  /// Per-action voice payload (base64). Kept outside the queue JSON so
  /// offline sessions do not blow SharedPreferences size limits.
  static const String pendingVoicePrefix = 'overtime_pending_voice_';

  static String pendingVoiceKey(String actionId) =>
      '$pendingVoicePrefix$actionId';
}
