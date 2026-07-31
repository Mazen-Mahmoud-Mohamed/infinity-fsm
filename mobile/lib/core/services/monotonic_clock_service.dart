import 'package:flutter/services.dart';

/// Platform monotonic elapsed time (survives wall-clock changes, resets on reboot).
class MonotonicClockService {
  MonotonicClockService({
    MethodChannel? channel,
  }) : _channel = channel ??
            const MethodChannel('com.infinity.fsm/monotonic_clock');

  final MethodChannel _channel;

  /// Process-local fallback when the platform channel is unavailable.
  final Stopwatch _sessionWatch = Stopwatch()..start();
  bool? _platformAvailable;

  /// Milliseconds since an arbitrary boot/process epoch (monotonic).
  Future<int> elapsedRealtimeMs() async {
    if (_platformAvailable == false) {
      return _sessionWatch.elapsedMilliseconds;
    }

    try {
      final value = await _channel.invokeMethod<dynamic>('elapsedRealtimeMs');
      if (value is int) {
        _platformAvailable = true;
        return value;
      }
      if (value is num) {
        _platformAvailable = true;
        return value.toInt();
      }
    } on MissingPluginException {
      _platformAvailable = false;
    } on Object {
      _platformAvailable = false;
    }

    return _sessionWatch.elapsedMilliseconds;
  }

  bool get usesPlatformClock => _platformAvailable == true;
}
