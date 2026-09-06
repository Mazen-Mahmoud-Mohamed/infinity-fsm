import 'package:flutter/foundation.dart';
import 'package:mobile/core/app/injection.dart';
import 'package:mobile/core/config/env_config.dart';

/// Square gallery-tile Cloudinary transform (display only).
///
/// Matches Work Order photo tiles (`BoxFit.cover` + `memCacheWidth: 400`).
@visibleForTesting
const String kCloudinaryGalleryThumbTransform =
    'c_fill,w_400,h_400,q_auto,f_jpg';

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
    final env = config ??
        (getIt.isRegistered<EnvConfig>()
            ? getIt<EnvConfig>()
            : EnvConfig.current);
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

/// Returns a Cloudinary delivery URL sized for Work Order gallery tiles.
///
/// Display-only helper: callers must keep the original stored URL for remove,
/// keep-by-URL, API payloads, and fullscreen.
///
/// - Confirmed Cloudinary `/upload/` URLs without a width transform get
///   [kCloudinaryGalleryThumbTransform] inserted after `/upload/`.
/// - URLs that already include a `w_` transform are returned unchanged.
/// - Non-Cloudinary / relative / invalid URLs are returned unchanged.
String cloudinaryGalleryThumbUrl(String url) {
  final parsed = _parseCloudinaryUploadUrl(url);
  if (parsed == null) return url;

  final afterUpload = parsed.afterUpload;
  final first = afterUpload.first;
  final isVersion = RegExp(r'^v\d+$').hasMatch(first);
  final looksLikeFile = first.contains('.');
  final hasTransforms = !isVersion && !looksLikeFile;

  if (hasTransforms) {
    final existing = first
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    // Avoid conflicting / duplicate size transforms (same rule as OT Excel).
    if (existing.any((t) => RegExp(r'^w_\d+').hasMatch(t))) {
      return url;
    }

    final preserved = existing.where((t) {
      if (t.startsWith('f_') || t.startsWith('q_')) return false;
      if (t.startsWith('w_') || t.startsWith('h_')) return false;
      if (t.startsWith('c_')) return false;
      return true;
    });

    final transform = [
      ...kCloudinaryGalleryThumbTransform.split(','),
      ...preserved,
    ].join(',');

    return parsed.rebuild(transformSegment: transform);
  }

  return parsed.rebuild(transformSegment: kCloudinaryGalleryThumbTransform);
}

/// Inserts / replaces Cloudinary format transform with `f_jpg,q_auto`.
///
/// Returns null when [url] is not a Cloudinary upload URL.
///
/// Composes safely with [cloudinaryGalleryThumbUrl]: existing `q_*` is kept,
/// and only one `f_jpg` is present after rewrite.
String? forceCloudinaryRasterFormat(String url) {
  final parsed = _parseCloudinaryUploadUrl(url);
  if (parsed == null) return null;

  final afterUpload = parsed.afterUpload;
  final first = afterUpload.first;
  final isVersion = RegExp(r'^v\d+$').hasMatch(first);
  final looksLikeFile = first.contains('.');
  final hasTransforms = !isVersion && !looksLikeFile;

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
    return parsed.rebuild(transformSegment: transforms.join(','));
  }

  return parsed.rebuild(transformSegment: 'f_jpg,q_auto');
}

class _CloudinaryUploadPath {
  const _CloudinaryUploadPath({
    required this.uri,
    required this.segments,
    required this.uploadIdx,
    required this.afterUpload,
  });

  final Uri uri;
  final List<String> segments;
  final int uploadIdx;
  final List<String> afterUpload;

  String rebuild({required String transformSegment}) {
    final rebuilt = [
      ...segments.sublist(0, uploadIdx + 1),
      transformSegment,
      ...afterUpload.skip(_afterUploadPayloadStart),
    ];
    return uri.replace(pathSegments: rebuilt).toString();
  }

  /// When [afterUpload] already starts with a transform segment, payload begins
  /// at index 1; otherwise the whole [afterUpload] list is the payload.
  int get _afterUploadPayloadStart {
    final first = afterUpload.first;
    final isVersion = RegExp(r'^v\d+$').hasMatch(first);
    final looksLikeFile = first.contains('.');
    final hasTransforms = !isVersion && !looksLikeFile;
    return hasTransforms ? 1 : 0;
  }
}

_CloudinaryUploadPath? _parseCloudinaryUploadUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;

  final host = uri.host.toLowerCase();
  final isCloudinary = host == 'res.cloudinary.com' ||
      host.endsWith('.cloudinary.com') ||
      host.contains('cloudinary');
  if (!isCloudinary) return null;

  // Relative-looking paths without a real host never reach here (no scheme).
  final segments = List<String>.from(uri.pathSegments);
  final uploadIdx = segments.indexOf('upload');
  if (uploadIdx < 0 || uploadIdx >= segments.length - 1) {
    return null;
  }

  final afterUpload = segments.sublist(uploadIdx + 1);
  if (afterUpload.isEmpty) return null;

  return _CloudinaryUploadPath(
    uri: uri,
    segments: segments,
    uploadIdx: uploadIdx,
    afterUpload: afterUpload,
  );
}
