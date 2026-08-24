import 'package:url_launcher/url_launcher.dart';
import 'package:mobile/features/work_orders/presentation/utils/work_order_phone_numbers.dart';

/// Opens the platform phone dialer for a customer number (does not auto-dial).
class WorkOrderPhoneLauncher {
  WorkOrderPhoneLauncher._();

  static Future<bool> openDialer(String phone) async {
    final uri = WorkOrderPhoneNumbers.dialerUri(phone);
    if (uri == null) {
      return false;
    }
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
