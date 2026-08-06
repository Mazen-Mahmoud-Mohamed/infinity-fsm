import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:mobile/features/overtime/domain/constants/overtime_media_config.dart';
import 'package:mobile/features/overtime/domain/services/overtime_photo_compression_result.dart';

/// Compresses overtime checkpoint photos to fit within the configured size.
class OvertimePhotoCompressor {
  OvertimePhotoCompressor._();

  static Future<List<int>> compressToPolicy(
    List<int> bytes, {
    required Object maxPhotoSize,
  }) async {
    final result = await compressWithDetails(bytes, maxPhotoSize: maxPhotoSize);
    return result.bytes;
  }

  static Future<OvertimePhotoCompressionResult> compressWithDetails(
    List<int> bytes, {
    required Object maxPhotoSize,
  }) async {
    final normalized = OvertimeMediaConfig.normalizeMaxPhotoSize(maxPhotoSize);
    final limitMb = OvertimeMediaConfig.maxPhotoSizeMbOrNull(normalized);
    final decoded = img.decodeImage(Uint8List.fromList(bytes));
    final originalWidth = decoded?.width;
    final originalHeight = decoded?.height;

    if (limitMb == null) {
      return OvertimePhotoCompressionResult(
        bytes: bytes,
        originalBytes: bytes,
        outputWidth: originalWidth,
        outputHeight: originalHeight,
        policyLimitMb: null,
      );
    }

    final maxBytes = limitMb * 1024 * 1024;
    if (bytes.length <= maxBytes) {
      return OvertimePhotoCompressionResult(
        bytes: bytes,
        originalBytes: bytes,
        outputWidth: originalWidth,
        outputHeight: originalHeight,
        policyLimitMb: limitMb,
        skippedBecauseUnderLimit: true,
      );
    }

    if (decoded == null) {
      return OvertimePhotoCompressionResult(
        bytes: bytes,
        originalBytes: bytes,
        outputWidth: originalWidth,
        outputHeight: originalHeight,
        policyLimitMb: limitMb,
        decodeFailed: true,
      );
    }

    var quality = 85;
    var width = decoded.width;
    List<int>? bestAttempt;
    int? bestQuality;
    img.Image? bestWorking;
    var reachedMinQuality = false;

    for (var attempt = 0; attempt < 16; attempt++) {
      final working = width < decoded.width
          ? img.copyResize(
              decoded,
              width: width,
              interpolation: img.Interpolation.linear,
            )
          : decoded;

      final compressed = Uint8List.fromList(
        img.encodeJpg(working, quality: quality),
      );
      bestAttempt = compressed;
      bestQuality = quality;
      bestWorking = working;

      if (compressed.length <= maxBytes) {
        return OvertimePhotoCompressionResult(
          bytes: compressed,
          originalBytes: bytes,
          jpegQuality: quality,
          outputWidth: working.width,
          outputHeight: working.height,
          policyLimitMb: limitMb,
        );
      }

      if (quality > 35) {
        quality -= 10;
      } else if (width > 480) {
        width = (width * 0.82).round();
        quality = 70;
      } else if (quality > 25) {
        quality -= 5;
      } else {
        reachedMinQuality = true;
        break;
      }
    }

    final fallback = bestAttempt ?? bytes;
    final working = bestWorking;

    return OvertimePhotoCompressionResult(
      bytes: fallback,
      originalBytes: bytes,
      jpegQuality: bestQuality,
      outputWidth: working?.width ?? originalWidth,
      outputHeight: working?.height ?? originalHeight,
      policyLimitMb: limitMb,
      reachedMinQuality: reachedMinQuality,
    );
  }
}
