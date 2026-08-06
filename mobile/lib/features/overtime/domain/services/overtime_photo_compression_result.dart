/// Result of applying the overtime photo compression policy.
class OvertimePhotoCompressionResult {
  const OvertimePhotoCompressionResult({
    required this.bytes,
    required this.originalBytes,
    this.jpegQuality,
    this.outputWidth,
    this.outputHeight,
    this.policyLimitMb,
    this.skippedBecauseUnderLimit = false,
    this.decodeFailed = false,
    this.reachedMinQuality = false,
  });

  /// Output bytes after applying the policy (may equal [originalBytes]).
  final List<int> bytes;

  /// Unmodified source bytes selected for the preview/upload flow.
  final List<int> originalBytes;

  /// JPEG quality used when re-encoding; null when no re-encoding occurred.
  final int? jpegQuality;

  final int? outputWidth;
  final int? outputHeight;

  /// Configured MB cap, or null for the original/no-limit policy.
  final int? policyLimitMb;

  /// True when the file was already under the configured cap.
  final bool skippedBecauseUnderLimit;

  /// True when the source image could not be decoded for compression.
  final bool decodeFailed;

  /// True when the compressor exhausted quality/resize attempts.
  final bool reachedMinQuality;

  bool get isOriginalPolicy => policyLimitMb == null;

  bool get wasReencoded =>
      jpegQuality != null && !_identicalBytes(bytes, originalBytes);

  int get compressionRatioPercent {
    if (originalBytes.isEmpty) return 0;
    if (_identicalBytes(bytes, originalBytes)) return 0;
    return ((1 - (bytes.length / originalBytes.length)) * 100).round().clamp(
      0,
      100,
    );
  }

  static bool _identicalBytes(List<int> a, List<int> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
