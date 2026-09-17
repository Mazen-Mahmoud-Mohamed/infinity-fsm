/// In-memory company holiday YYYY-MM-DD keys for offline overtime preview.
///
/// Populated from network sync + durable local cache. When empty/unavailable,
/// [OvertimeCalculator] falls back to Friday-only non-working behavior.
class HolidayCalendarCache {
  Set<String> _dates = const <String>{};

  Set<String> get dates => _dates;

  void setDates(Iterable<String> dates) {
    _dates = Set<String>.unmodifiable(
      dates.map((d) => d.trim()).where((d) => d.isNotEmpty),
    );
  }

  void clear() {
    _dates = const <String>{};
  }
}
