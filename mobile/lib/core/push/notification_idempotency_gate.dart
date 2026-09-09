/// In-process duplicate-navigation guard, scoped to the authenticated user.
class NotificationIdempotencyGate {
  String? _userId;
  String? _lastKey;

  /// Returns true when [key] was already handled for [userId].
  bool shouldSkip(String? key, {required String? userId}) {
    if (userId != _userId) {
      _lastKey = null;
      _userId = userId;
    }
    if (key == null || key.isEmpty) return false;
    if (key == _lastKey) return true;
    _lastKey = key;
    return false;
  }

  void forgetLastKey() {
    _lastKey = null;
  }

  void clear() {
    _userId = null;
    _lastKey = null;
  }
}
