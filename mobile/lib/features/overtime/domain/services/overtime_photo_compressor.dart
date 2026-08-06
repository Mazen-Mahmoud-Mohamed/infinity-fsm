import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:mobile/features/overtime/domain/constants/overtime_media_config.dart';

/// Compresses overtime checkpoint photos to fit within the configured size.
class OvertimePhotoCompressor {
  OvertimePhotoCompressor._();

  static Future<List<int>> compressToPolicy(
    List<int> bytes, {
    required Object maxPhotoSize,
  }) async {
    final limitMb = OvertimeMediaConfig.maxPhotoSizeMbOrNull(maxPhotoSize);
    if (limitMb == null) {
      return bytes;
    }

    final maxBytes = limitMb * 1024 * 1024;
    if (bytes.length <= maxBytes) {
      return bytes;
    }

    final decoded = img.decodeImage(Uint8List.fromList(bytes));
    if (decoded == null) {
      return bytes;
    }

    var quality = 85;
    var width = decoded.width;
    img.Image working = decoded;

    for (var attempt = 0; attempt < 12; attempt++) {
      if (width < decoded.width) {
        working = img.copyResize(
          decoded,
          width: width,
          interpolation: img.Interpolation.linear,
        );
      } else {
        working = decoded;
      }

      final compressed = Uint8List.fromList(
        img.encodeJpg(working, quality: quality),
      );
      if (compressed.length <= maxBytes) {
        return compressed;
      }

      if (quality > 45) {
        quality -= 10;
      } else if (width > 640) {
        width = (width * 0.85).round();
        quality = 75;
      } else {
        return compressed;
      }
    }

    return bytes;
  }
}
