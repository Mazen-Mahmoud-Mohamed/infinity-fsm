import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Brings the native Windows window to the foreground (toast click).
class WindowFocusService {
  WindowFocusService({
    MethodChannel? channel,
  }) : _channel =
            channel ?? const MethodChannel('com.infinity.fsm/window');

  final MethodChannel _channel;

  Future<void> focusApp() async {
    if (kIsWeb || !Platform.isWindows) return;
    try {
      await _channel.invokeMethod<void>('focusWindow');
    } on Object catch (error) {
      debugPrint('[WindowFocus] focusWindow failed: $error');
    }
  }
}
