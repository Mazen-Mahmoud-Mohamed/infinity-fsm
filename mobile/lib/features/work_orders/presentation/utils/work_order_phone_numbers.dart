/// Shared helpers for work-order customer phone numbers (admin + technician).
class WorkOrderPhoneNumbers {
  WorkOrderPhoneNumbers._();

  static const int maxCount = 20;
  static const int maxLength = 40;

  /// Trims, drops empties, de-dupes by digit sequence, preserves display text.
  static List<String> normalize(Iterable<String> raw) {
    final result = <String>[];
    final seenDigits = <String>{};
    for (final item in raw) {
      final trimmed = item.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      if (!isValidPhoneInput(trimmed)) {
        continue;
      }
      final digits = digitsOnly(trimmed);
      if (seenDigits.contains(digits)) {
        continue;
      }
      seenDigits.add(digits);
      result.add(trimmed);
      if (result.length >= maxCount) {
        break;
      }
    }
    return result;
  }

  static String digitsOnly(String value) =>
      value.replaceAll(RegExp(r'\D'), '');

  /// Soft validation aligned with backend (international-friendly).
  static bool isValidPhoneInput(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed.length > maxLength) {
      return false;
    }
    if (!RegExp(r'^[+]?[\d\s().\-]+$').hasMatch(trimmed)) {
      return false;
    }
    final digits = digitsOnly(trimmed);
    return digits.length >= 7 && digits.length <= 15;
  }

  /// First invalid non-empty entry, or null if all ok / empty rows ignored.
  static String? firstInvalid(Iterable<String> raw) {
    for (final item in raw) {
      final trimmed = item.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      if (!isValidPhoneInput(trimmed)) {
        return trimmed;
      }
    }
    return null;
  }

  /// tel: URI for system dialer (does not place the call).
  static Uri? dialerUri(String phone) {
    final trimmed = phone.trim();
    if (!isValidPhoneInput(trimmed)) {
      return null;
    }
    final sanitized = trimmed.replaceAll(RegExp(r'[^\d+]'), '');
    if (sanitized.isEmpty) {
      return null;
    }
    return Uri(scheme: 'tel', path: sanitized);
  }
}
