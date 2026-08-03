/// Lightweight process start timestamp for diagnostics (uptime).
class AppRuntimeInfo {
  AppRuntimeInfo() : startedAt = DateTime.now();

  final DateTime startedAt;

  Duration get uptime => DateTime.now().difference(startedAt);
}
