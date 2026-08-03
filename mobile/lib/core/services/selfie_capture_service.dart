import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:mobile/core/constants/attendance_constants.dart';

/// Thrown when the camera is closed without capturing a live photo.
class LivePhotoRequiredException implements Exception {
  const LivePhotoRequiredException([
    this.message = 'livePhotoRequired',
  ]);

  final String message;

  @override
  String toString() => message;
}

/// Thrown when the device camera cannot be opened.
class CameraUnavailableException implements Exception {
  const CameraUnavailableException([
    this.message = 'cameraUnavailable',
  ]);

  final String message;

  @override
  String toString() => message;
}

class _WatermarkParams {
  const _WatermarkParams({
    required this.bytes,
    required this.label,
    required this.timestampText,
    this.latitude,
    this.longitude,
  });

  final Uint8List bytes;
  final String label;
  final String timestampText;
  final double? latitude;
  final double? longitude;
}

/// Draws a semi-transparent bottom banner with checkpoint metadata.
///
/// Runs off the UI isolate. Never throws — returns the original bytes
/// on any failure so the capture workflow is never blocked.
Uint8List _drawWatermark(_WatermarkParams params) {
  try {
    final decoded = img.decodeImage(params.bytes);
    if (decoded == null) {
      return params.bytes;
    }

    final bannerHeight = (decoded.height * 0.18).clamp(56, 160).toInt();
    final bannerY = decoded.height - bannerHeight;
    final banner = img.Image(width: decoded.width, height: bannerHeight);
    img.fill(banner, color: img.ColorRgba8(0, 0, 0, 140));
    img.compositeImage(decoded, banner, dstX: 0, dstY: bannerY);

    final lines = <String>[
      params.label,
      params.timestampText,
      if (params.latitude != null && params.longitude != null)
        '${params.latitude!.toStringAsFixed(5)}, ${params.longitude!.toStringAsFixed(5)}',
    ];

    var textY = bannerY + 8;
    for (final line in lines) {
      img.drawString(
        decoded,
        line,
        font: img.arial14,
        x: 12,
        y: textY,
        color: img.ColorRgb8(255, 255, 255),
      );
      textY += 18;
    }

    return Uint8List.fromList(
      img.encodeJpg(decoded, quality: AttendanceConstants.selfieImageQuality),
    );
  } on Object {
    return params.bytes;
  }
}

/// Captures mandatory live photos for attendance and overtime.
///
/// Gallery selection is intentionally disabled — cancelling the camera
/// must abort the parent operation.
class SelfieCaptureService {
  SelfieCaptureService({ImagePicker? picker})
      : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Opens the camera only. Never falls back to the gallery.
  ///
  /// Returns compressed JPEG bytes on success. When [watermarkLabel] is
  /// provided, a bottom banner with the label, timestamp, and (optional)
  /// GPS coordinates is drawn onto the photo. Drawing never blocks or
  /// fails the capture — the original bytes are returned if it errors.
  ///
  /// Throws [LivePhotoRequiredException] if the user cancels.
  /// Throws [CameraUnavailableException] if the camera cannot be opened.
  Future<Uint8List> captureLivePhoto({
    CameraDevice preferredCamera = CameraDevice.front,
    String? watermarkLabel,
    DateTime? timestamp,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: preferredCamera,
        imageQuality: AttendanceConstants.selfieImageQuality,
        maxWidth: AttendanceConstants.selfieMaxWidth,
      );

      if (file == null) {
        throw const LivePhotoRequiredException();
      }

      final bytes = await file.readAsBytes();
      if (watermarkLabel == null || watermarkLabel.trim().isEmpty) {
        return bytes;
      }

      final params = _WatermarkParams(
        bytes: bytes,
        label: watermarkLabel.trim(),
        timestampText: (timestamp ?? DateTime.now()).toLocal().toIso8601String(),
        latitude: latitude,
        longitude: longitude,
      );

      try {
        return await compute(_drawWatermark, params);
      } on Object {
        return bytes;
      }
    } on LivePhotoRequiredException {
      rethrow;
    } on Object {
      throw const CameraUnavailableException();
    }
  }

  /// Backward-compatible alias used by attendance/overtime cubits.
  Future<Uint8List> captureSelfie() => captureLivePhoto();
}
