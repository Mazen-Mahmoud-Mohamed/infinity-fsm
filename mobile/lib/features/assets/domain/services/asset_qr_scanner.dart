import 'package:mobile/core/utils/result.dart';

/// Architecture prep for QR scanning — no camera/scanner execution in Phase 1.
abstract class AssetQrScanner {
  /// Scans a QR/barcode and returns the decoded payload when available.
  Future<Result<String>> scan();
}

/// Online MVP stub — ready to be replaced by a platform scanner implementation.
class StubAssetQrScanner implements AssetQrScanner {
  @override
  Future<Result<String>> scan() async {
    return const Failure(
      'assetsQrScannerNotReady',
      code: 'QR_SCANNER_NOT_READY',
    );
  }
}
