import 'package:flutter/foundation.dart';

class DeviceInfoProvider {
  DeviceInfoProvider._();

  static Map<String, String> current() {
    return {
      'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
    };
  }
}
