import 'package:url_launcher/url_launcher.dart';

/// Opens a work-order location URL in the platform external browser/maps app.
class WorkOrderLocationLauncher {
  WorkOrderLocationLauncher._();

  static bool isValidHttpUrl(String? value) {
    if (value == null) {
      return false;
    }
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return false;
    }
    final uri = Uri.tryParse(trimmed);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  static Future<bool> openUrl(String? url) async {
    if (!isValidHttpUrl(url)) {
      return false;
    }
    final uri = Uri.parse(url!.trim());
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
