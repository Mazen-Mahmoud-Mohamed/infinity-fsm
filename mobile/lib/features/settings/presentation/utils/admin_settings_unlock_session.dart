/// In-memory session gate for Settings admin tools (Server / Developer / Logs).
///
/// Biometric unlock marks the session; deep links cannot bypass it.
/// Does not replace role checks — callers must still enforce admin access.
class AdminSettingsUnlockSession {
  AdminSettingsUnlockSession({this.ttl = const Duration(minutes: 15)});

  final Duration ttl;
  DateTime? _unlockedUntil;

  bool get isUnlocked {
    final until = _unlockedUntil;
    if (until == null) return false;
    if (DateTime.now().isAfter(until)) {
      _unlockedUntil = null;
      return false;
    }
    return true;
  }

  void markUnlocked() {
    _unlockedUntil = DateTime.now().add(ttl);
  }

  void clear() {
    _unlockedUntil = null;
  }
}
