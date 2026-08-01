import 'package:flutter/foundation.dart';
import 'package:mobile/core/config/env_config.dart';

/// Resolves media URLs for network image widgets (avatars, selfies, logos).
///
/// - Absolute `http(s)` URLs are normalized for desktop-safe delivery.
/// - Relative API paths are joined to the API origin.
/// - Empty / unsupported schemes return null.
String? resolveMediaUrl(String? raw, {EnvConfig? config}) {
  if (raw == null) return null;
  final value = raw.trim();
  if (value.isEmpty) return null;

  final lower = value.toLowerCase();
  if (lower.startsWith('file:') || lower.startsWith('blob:')) {
    return null;
  }

  String absolute;
  if (lower.startsWith('http://') || lower.startsWith('https://')) {
    absolute = value;
  } else {
    final env = config ?? EnvConfig.current;
    final origin = env.socketBaseUrl;
    absolute = value.startsWith('/') ? '$origin$value' : '$origin/$value';
  }

  return normalizeMediaDeliveryUrl(absolute);
}

/// Ensures CDN delivery uses a Flutter-decodable format on desktop.
///
/// Cloudinary `f_auto` (and some account defaults) can return **AVIF**.
/// Android decodes AVIF; Flutter Windows often cannot — images appear blank
/// with broken-image / empty boxes while the same URL works on Android.
String normalizeMediaDeliveryUrl(String url) {
  if (!_shouldForceSafeRasterFormat) {
    return url;
  }
  return forceCloudinaryRasterFormat(url) ?? url;
}

bool get _shouldForceSafeRasterFormat {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS;
}

/// Inserts / replaces Cloudinary format transform with `f_jpg,q_auto`.
///
/// Returns null when [url] is not a Cloudinary upload URL.
String? forceCloudinaryRasterFormat(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;

  final host = uri.host.toLowerCase();
  final isCloudinary = host == 'res.cloudinary.com' ||
      host.endsWith('.cloudinary.com') ||
      host.contains('cloudinary');
  if (!isCloudinary) return null;

  final segments = List<String>.from(uri.pathSegments);
  final uploadIdx = segments.indexOf('upload');
  if (uploadIdx < 0 || uploadIdx >= segments.length - 1) {
    return null;
  }

  final afterUpload = segments.sublist(uploadIdx + 1);
  if (afterUpload.isEmpty) return null;

  final first = afterUpload.first;
  final isVersion = RegExp(r'^v\d+$').hasMatch(first);
  final looksLikeFile = first.contains('.');
  final hasTransforms = !isVersion && !looksLikeFile;

  late final List<String> rebuilt;
  if (hasTransforms) {
    final transforms = first
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty && !t.startsWith('f_'))
        .toList();
    transforms.insert(0, 'f_jpg');
    if (!transforms.any((t) => t.startsWith('q_'))) {
      transforms.add('q_auto');
    }
    rebuilt = [
      ...segments.sublist(0, uploadIdx + 1),
      transforms.join(','),
      ...afterUpload.sublist(1),
    ];
  } else {
    rebuilt = [
      ...segments.sublist(0, uploadIdx + 1),
      'f_jpg,q_auto',
      ...afterUpload,
    ];
  }

  return uri.replace(pathSegments: rebuilt).toString();
}
