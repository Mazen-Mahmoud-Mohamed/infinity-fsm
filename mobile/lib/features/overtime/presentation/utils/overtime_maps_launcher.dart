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
    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      return false;
    }

    final queryLabel = (label != null && label.trim().isNotEmpty)
        ? label.trim()
        : '$latitude,$longitude';

    final candidates = <Uri>[
      // Android: native maps intent, then Google Maps app URI.
      if (!kIsWeb && Platform.isAndroid) ...[
        Uri.parse(
          'geo:$latitude,$longitude?q=$latitude,$longitude(${Uri.encodeComponent(queryLabel)})',
        ),
        Uri.parse(
          'google.navigation:q=$latitude,$longitude',
        ),
      ],
      if (!kIsWeb && Platform.isIOS)
        Uri.parse(
          'comgooglemaps://?q=$latitude,$longitude&center=$latitude,$longitude',
        ),
      // Windows / fallback: default browser.
      Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
      ),
      Uri.parse(
        'https://maps.google.com/?q=$latitude,$longitude',
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
