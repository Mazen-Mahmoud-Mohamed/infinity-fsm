/// Shared GPS / selfie / clock-skew constants used by Overtime and core services.
class CaptureConstants {
  CaptureConstants._();

  /// Mirrors backend overtime GPS accuracy threshold default.
  static const double gpsAccuracyThresholdMeters = 100;

  /// Mirrors backend `config.security.maxDeviceClockSkewSeconds` default.
  static const Duration maxDeviceClockSkew = Duration(minutes: 2);

  static const int selfieImageQuality = 70;
  static const double selfieMaxWidth = 1080;

  static const Duration gpsTimeout = Duration(seconds: 20);
}
