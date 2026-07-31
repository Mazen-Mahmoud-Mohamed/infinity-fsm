import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a coordinate in the Google Maps app when available, otherwise the web UI.
class OvertimeMapsLauncher {
  OvertimeMapsLauncher._();

  static Future<bool> openCoordinates({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    final queryLabel = (label != null && label.trim().isNotEmpty)
        ? label.trim()
        : '$latitude,$longitude';

    final candidates = <Uri>[
      if (!kIsWeb && Platform.isAndroid)
        Uri.parse(
          'geo:$latitude,$longitude?q=$latitude,$longitude(${Uri.encodeComponent(queryLabel)})',
        ),
      if (!kIsWeb && Platform.isIOS)
        Uri.parse(
          'comgooglemaps://?q=$latitude,$longitude&center=$latitude,$longitude',
        ),
      Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
      ),
    ];

    for (final uri in candidates) {
      try {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) {
          return true;
        }
      } on Object {
        // Try the next candidate.
      }
    }

    return false;
  }
}
