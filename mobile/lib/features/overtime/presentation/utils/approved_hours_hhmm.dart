/// Parses Partial Approve `HH:MM` input into total minutes.
///
/// Does **not** treat values as decimal hours (`14.30` ≠ 14h 30m).
class ApprovedHoursHhMm {
  ApprovedHoursHhMm._();

  /// Formats total minutes as `H:MM` (e.g. `870` → `14:30`).
  static String formatFromMinutes(int minutes) {
    final safe = minutes < 0 ? 0 : minutes;
    final hours = safe ~/ 60;
    final mins = safe % 60;
    return '$hours:${mins.toString().padLeft(2, '0')}';
  }

  /// Converts total minutes to the existing API `approvedHours` decimal
  /// representation (2 d.p.), matching backend `minutesToHours`.
  static double toApiHours(int totalMinutes) {
    final safe = totalMinutes < 0 ? 0 : totalMinutes;
    return (safe * 100 / 60).round() / 100.0;
  }

  /// Parses `HH:MM` into total minutes.
  ///
  /// Returns a failed [ApprovedHoursHhMmResult] for empty/invalid input,
  /// minutes outside 0–59, or negative hours.
  static ApprovedHoursHhMmResult parse(String? raw) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty) {
      return const ApprovedHoursHhMmResult.invalid();
    }

    final match = RegExp(r'^(\d+):(\d{1,2})$').firstMatch(text);
    if (match == null) {
      return const ApprovedHoursHhMmResult.invalid();
    }

    final hours = int.tryParse(match.group(1)!);
    final minutes = int.tryParse(match.group(2)!);
    if (hours == null || minutes == null) {
      return const ApprovedHoursHhMmResult.invalid();
    }
    if (hours < 0 || minutes < 0 || minutes > 59) {
      return const ApprovedHoursHhMmResult.invalid();
    }

    final totalMinutes = hours * 60 + minutes;
    return ApprovedHoursHhMmResult.valid(totalMinutes);
  }

  /// Validates [raw] as `HH:MM` and ensures it does not exceed [workedMinutes].
  static ApprovedHoursHhMmResult parseAndValidateAgainstWorked({
    required String? raw,
    required int workedMinutes,
  }) {
    final parsed = parse(raw);
    if (!parsed.isValid) {
      return parsed;
    }
    final safeWorked = workedMinutes < 0 ? 0 : workedMinutes;
    if (parsed.totalMinutes! > safeWorked) {
      return const ApprovedHoursHhMmResult.invalid();
    }
    return parsed;
  }
}

class ApprovedHoursHhMmResult {
  const ApprovedHoursHhMmResult._({this.totalMinutes});

  const ApprovedHoursHhMmResult.valid(int minutes)
      : this._(totalMinutes: minutes);

  const ApprovedHoursHhMmResult.invalid() : this._(totalMinutes: null);

  final int? totalMinutes;

  bool get isValid => totalMinutes != null;

  /// API payload for `approvedHours` when [isValid].
  double? get apiHours =>
      totalMinutes == null ? null : ApprovedHoursHhMm.toApiHours(totalMinutes!);
}
