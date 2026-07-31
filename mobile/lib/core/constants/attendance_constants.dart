class AttendanceConstants {
  AttendanceConstants._();

  /// Mirrors backend `config.attendance.gpsAccuracyThresholdMeters` default.
  static const double gpsAccuracyThresholdMeters = 100;

  /// Mirrors backend `config.security.maxDeviceClockSkewSeconds` default.
  static const Duration maxDeviceClockSkew = Duration(minutes: 2);

  static const int selfieImageQuality = 70;
  static const double selfieMaxWidth = 1080;

  static const Duration gpsTimeout = Duration(seconds: 20);
  static const Duration timerTickInterval = Duration(seconds: 1);
  static const Duration statusPollInterval = Duration(seconds: 30);
  static const Duration syncRetryInterval = Duration(seconds: 45);

  static const int maxSyncRetries = 8;
}
