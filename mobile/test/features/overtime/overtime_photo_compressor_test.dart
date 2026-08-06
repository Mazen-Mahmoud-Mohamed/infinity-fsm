import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mobile/features/overtime/domain/constants/overtime_media_config.dart';
import 'package:mobile/features/overtime/domain/services/overtime_photo_compressor.dart';

List<int> _buildFixtureJpeg({
  required int width,
  required int height,
  int quality = 95,
}) {
  final image = img.Image(width: width, height: height);
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      image.setPixelRgb(
        x,
        y,
        (x * 3) % 255,
        (y * 5) % 255,
        ((x + y) * 7) % 255,
      );
    }
  }
  return img.encodeJpg(image, quality: quality);
}

void main() {
  late List<int> largeJpegBytes;
  late List<int> mediumJpegBytes;

  setUp(() {
    largeJpegBytes = _buildFixtureJpeg(width: 2400, height: 3200);
    mediumJpegBytes = _buildFixtureJpeg(width: 1800, height: 2400, quality: 90);

    expect(
      largeJpegBytes.length,
      greaterThan(2 * 1024 * 1024),
      reason: 'large fixture must exceed the 2 MB policy',
    );
    expect(
      mediumJpegBytes.length,
      lessThan(5 * 1024 * 1024),
      reason: 'medium fixture must stay under the 5 MB policy',
    );
    expect(
      mediumJpegBytes.length,
      greaterThan(1 * 1024 * 1024),
      reason: 'medium fixture should still benefit from 1 MB policy',
    );
  });

  test('original policy returns source bytes unchanged', () async {
    final result = await OvertimePhotoCompressor.compressWithDetails(
      largeJpegBytes,
      maxPhotoSize: OvertimeMediaConfig.maxPhotoSizeOriginal,
    );

    expect(result.bytes, largeJpegBytes);
    expect(result.isOriginalPolicy, isTrue);
    expect(result.compressionRatioPercent, 0);
    expect(result.jpegQuality, isNull);
  });

  test('2 MB policy compresses oversized photos', () async {
    final result = await OvertimePhotoCompressor.compressWithDetails(
      largeJpegBytes,
      maxPhotoSize: 2,
    );

    expect(result.bytes.length, lessThan(largeJpegBytes.length));
    expect(result.bytes.length, lessThanOrEqualTo(2 * 1024 * 1024));
    expect(result.compressionRatioPercent, greaterThan(0));
    expect(result.jpegQuality, isNotNull);
    expect(result.wasReencoded, isTrue);
  });

  test('1 MB policy compresses more aggressively than 2 MB', () async {
    final twoMb = await OvertimePhotoCompressor.compressWithDetails(
      largeJpegBytes,
      maxPhotoSize: 2,
    );
    final oneMb = await OvertimePhotoCompressor.compressWithDetails(
      largeJpegBytes,
      maxPhotoSize: 1,
    );

    expect(oneMb.bytes.length, lessThan(twoMb.bytes.length));
    expect(
      oneMb.compressionRatioPercent,
      greaterThan(twoMb.compressionRatioPercent),
    );
  });

  test('5 MB policy leaves large-but-under-limit photos unchanged', () async {
    final result = await OvertimePhotoCompressor.compressWithDetails(
      mediumJpegBytes,
      maxPhotoSize: 5,
    );

    expect(result.bytes, mediumJpegBytes);
    expect(result.skippedBecauseUnderLimit, isTrue);
    expect(result.compressionRatioPercent, 0);
  });

  test('compressToPolicy remains backward compatible', () async {
    final bytes = await OvertimePhotoCompressor.compressToPolicy(
      largeJpegBytes,
      maxPhotoSize: 2,
    );

    expect(bytes.length, lessThanOrEqualTo(2 * 1024 * 1024));
  });

  test('compressed output decodes as valid JPEG', () async {
    final result = await OvertimePhotoCompressor.compressWithDetails(
      largeJpegBytes,
      maxPhotoSize: 1,
    );

    final decoded = img.decodeImage(Uint8List.fromList(result.bytes));
    expect(decoded, isNotNull);
    expect(decoded!.width, greaterThan(0));
    expect(decoded.height, greaterThan(0));
  });
}
