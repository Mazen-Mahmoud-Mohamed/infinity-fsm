import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/utils/media_url.dart';

void main() {
  const cloudinaryBase =
      'https://res.cloudinary.com/demo/image/upload';
  const publicIdPath = 'v1710000000/work-orders/c1/photo.jpg';

  group('cloudinaryGalleryThumbUrl', () {
    test('A: Cloudinary secure URL gets square fill thumb transform', () {
      final original = '$cloudinaryBase/$publicIdPath';
      final thumb = cloudinaryGalleryThumbUrl(original);
      expect(
        thumb,
        '$cloudinaryBase/$kCloudinaryGalleryThumbTransform/$publicIdPath',
      );
      expect(original.contains('c_fill'), isFalse);
      expect(original, isNot(thumb));
    });

    test('B: existing w_ transform is left unchanged (no duplicate width)', () {
      final original =
          '$cloudinaryBase/c_fill,w_200,h_200,q_auto/$publicIdPath';
      expect(cloudinaryGalleryThumbUrl(original), original);
    });

    test('B: existing non-size transforms are preserved beside gallery thumb',
        () {
      final original = '$cloudinaryBase/e_art:audrey,f_auto/$publicIdPath';
      final thumb = cloudinaryGalleryThumbUrl(original);
      expect(thumb.contains('c_fill,w_400,h_400,q_auto,f_jpg'), isTrue);
      expect(thumb.contains('e_art:audrey'), isTrue);
      expect(thumb.contains('f_auto'), isFalse);
      // Single transform segment — no nested /f_auto/... after thumb.
      final afterUpload = Uri.parse(thumb).pathSegments
          .skipWhile((s) => s != 'upload')
          .skip(1)
          .toList();
      expect(afterUpload.first.startsWith('c_fill'), isTrue);
      expect(afterUpload[1], 'v1710000000');
    });

    test('C: non-Cloudinary HTTPS URL unchanged', () {
      const original = 'https://cdn.example.com/photos/a.jpg';
      expect(cloudinaryGalleryThumbUrl(original), original);
    });

    test('D: relative URL unchanged', () {
      const original = '/media/work-orders/photo.jpg';
      expect(cloudinaryGalleryThumbUrl(original), original);
    });

    test('E: file/blob/empty preserve resolveMediaUrl null behavior', () {
      expect(resolveMediaUrl('file:///tmp/a.jpg'), isNull);
      expect(resolveMediaUrl('blob:https://x/y'), isNull);
      expect(resolveMediaUrl(''), isNull);
      expect(resolveMediaUrl(null), isNull);
      expect(cloudinaryGalleryThumbUrl('file:///tmp/a.jpg'), 'file:///tmp/a.jpg');
    });

    test('F: original attachment URL remains byte-for-byte when unused', () {
      final original = '$cloudinaryBase/$publicIdPath';
      final copy = original;
      cloudinaryGalleryThumbUrl(original);
      expect(identical(original, copy) || original == copy, isTrue);
      expect(original, '$cloudinaryBase/$publicIdPath');
    });
  });

  group('forceCloudinaryRasterFormat composition', () {
    test('does not duplicate f_jpg after gallery thumb', () {
      final original = '$cloudinaryBase/$publicIdPath';
      final thumb = cloudinaryGalleryThumbUrl(original);
      final desktop = forceCloudinaryRasterFormat(thumb)!;
      final transform = Uri.parse(desktop).pathSegments
          .skipWhile((s) => s != 'upload')
          .skip(1)
          .first;
      expect(RegExp(r'f_jpg').allMatches(transform).length, 1);
      expect(transform.contains('c_fill'), isTrue);
      expect(transform.contains('w_400'), isTrue);
      expect(transform.contains('q_auto'), isTrue);
    });

    test('returns null for non-Cloudinary hosts', () {
      expect(
        forceCloudinaryRasterFormat('https://cdn.example.com/a.jpg'),
        isNull,
      );
    });
  });

  group('normalizeMediaDeliveryUrl desktop', () {
    test('applies raster format only on desktop platforms', () {
      final original = '$cloudinaryBase/$publicIdPath';
      final previous = debugDefaultTargetPlatformOverride;
      try {
        debugDefaultTargetPlatformOverride = TargetPlatform.windows;
        final normalized = normalizeMediaDeliveryUrl(original);
        expect(normalized.contains('f_jpg'), isTrue);

        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        expect(normalizeMediaDeliveryUrl(original), original);
      } finally {
        debugDefaultTargetPlatformOverride = previous;
      }
    });
  });
}
