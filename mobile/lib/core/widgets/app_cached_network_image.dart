import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile/core/utils/media_url.dart';

/// Enterprise network image for Infinity FSM.
///
/// Resolves relative URLs and, on desktop, rewrites Cloudinary delivery to
/// `f_jpg` so Windows never receives undecodable AVIF from `f_auto`.
class AppCachedNetworkImage extends StatelessWidget {
  const AppCachedNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.memCacheWidth,
    this.memCacheHeight,
    this.errorIcon = Icons.broken_image_outlined,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final IconData errorIcon;

  /// Prefer JPEG/PNG/WebP — never advertise AVIF to CDNs.
  static const Map<String, String> _safeAcceptHeaders = {
    'Accept': 'image/jpeg,image/png,image/webp,image/*;q=0.8,*/*;q=0.5',
  };

  static bool get _isDesktop {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final resolved = resolveMediaUrl(imageUrl);

    if (resolved == null) {
      debugPrint('AppCachedNetworkImage: unresolved url="$imageUrl"');
      return _errorBox(colorScheme);
    }

    if (resolved != imageUrl.trim()) {
      debugPrint(
        'AppCachedNetworkImage: original="$imageUrl" resolved="$resolved"',
      );
    }

    Widget image;
    if (_isDesktop) {
      // Bypass CachedNetworkImage on desktop (OneDrive cache path issues) and
      // load JPEG-forced Cloudinary URLs with a safe Accept header.
      image = Image.network(
        resolved,
        width: width,
        height: height,
        fit: fit,
        headers: _safeAcceptHeaders,
        filterQuality: FilterQuality.medium,
        gaplessPlayback: true,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _placeholder(colorScheme);
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint(
            'AppCachedNetworkImage FAILED: original="$imageUrl" '
            'resolved="$resolved" error=$error',
          );
          return _errorBox(colorScheme);
        },
      );
    } else {
      image = CachedNetworkImage(
        imageUrl: resolved,
        width: width,
        height: height,
        fit: fit,
        httpHeaders: _safeAcceptHeaders,
        memCacheWidth: memCacheWidth,
        memCacheHeight: memCacheHeight,
        fadeInDuration: const Duration(milliseconds: 150),
        placeholder: (context, url) => _placeholder(colorScheme),
        errorWidget: (context, url, error) {
          debugPrint(
            'AppCachedNetworkImage FAILED: original="$imageUrl" '
            'resolved="$url" error=$error',
          );
          return _errorBox(colorScheme);
        },
      );
    }

    if (width != null || height != null) {
      image = SizedBox(width: width, height: height, child: image);
    }

    if (borderRadius == null) return image;
    return ClipRRect(borderRadius: borderRadius!, child: image);
  }

  Widget _placeholder(ColorScheme colorScheme) {
    return ColoredBox(
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _errorBox(ColorScheme colorScheme) {
    return ColoredBox(
      color: colorScheme.surfaceContainerHighest,
      child: Icon(errorIcon, color: colorScheme.onSurfaceVariant),
    );
  }
}

/// Circular avatar that loads remote photos via [AppCachedNetworkImage].
class AppNetworkAvatar extends StatelessWidget {
  const AppNetworkAvatar({
    super.key,
    this.imageUrl,
    this.radius = 24,
    this.fallbackLabel,
  });

  final String? imageUrl;
  final double radius;
  final String? fallbackLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final resolved = resolveMediaUrl(imageUrl);
    final size = radius * 2;

    if (resolved == null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: colorScheme.surfaceContainerHighest,
        child: Text(
          _initials(fallbackLabel ?? '?'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
      );
    }

    return ClipOval(
      child: AppCachedNetworkImage(
        imageUrl: imageUrl!,
        width: size,
        height: size,
        memCacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
        memCacheHeight: (size * MediaQuery.devicePixelRatioOf(context)).round(),
        errorIcon: Icons.person_outline,
      ),
    );
  }

  static String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}
