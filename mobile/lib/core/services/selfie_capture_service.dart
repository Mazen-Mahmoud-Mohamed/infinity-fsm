import 'dart:typed_data';

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
  /// Returns compressed JPEG bytes on success.
  /// Throws [LivePhotoRequiredException] if the user cancels.
  /// Throws [CameraUnavailableException] if the camera cannot be opened.
  Future<Uint8List> captureLivePhoto({
    CameraDevice preferredCamera = CameraDevice.front,
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

      return file.readAsBytes();
    } on LivePhotoRequiredException {
      rethrow;
    } on Object {
      throw const CameraUnavailableException();
    }
  }

  /// Backward-compatible alias used by attendance/overtime cubits.
  Future<Uint8List> captureSelfie() => captureLivePhoto();
}
