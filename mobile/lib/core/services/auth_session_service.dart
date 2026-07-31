import 'dart:async';

class AuthSessionService {
  final StreamController<void> _sessionExpiredController =
      StreamController<void>.broadcast();

  Stream<void> get onSessionExpired => _sessionExpiredController.stream;

  void notifySessionExpired() {
    if (!_sessionExpiredController.isClosed) {
      _sessionExpiredController.add(null);
    }
  }

  void dispose() {
    unawaited(_sessionExpiredController.close());
  }
}
