class OvertimeFormatters {
  OvertimeFormatters._();

  static String durationFromMinutes(int? minutes) {
    if (minutes == null) {
      return '-';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours <= 0) {
      return '${mins}m';
    }
    if (mins == 0) {
      return '${hours}h';
    }
    return '${hours}h ${mins}m';
  }

  static String coordinates({
    required double latitude,
    required double longitude,
  }) {
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }
}
