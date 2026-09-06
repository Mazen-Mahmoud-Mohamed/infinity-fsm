import 'package:timezone/data/latest.dart' as tzdata;

/// Lazy, idempotent timezone database init for company calendar logic.
///
/// Call before any `timezone` Location / TZDateTime usage. Safe under
/// concurrent callers — only the first invocation loads tzdata.
bool _timeZonesInitialized = false;

/// Ensures [tzdata.initializeTimeZones] has run exactly once in this isolate.
void ensureTimeZonesInitialized() {
  if (_timeZonesInitialized) {
    return;
  }
  tzdata.initializeTimeZones();
  _timeZonesInitialized = true;
}

/// Test-only: resets the one-time guard so lazy init can be re-exercised.
void resetTimeZonesInitializedForTest() {
  _timeZonesInitialized = false;
}
