import 'dart:collection';

/// In-memory ring buffer of recent app log lines for the Admin Logs UI.
///
/// Never stores secrets — callers must sanitize messages before [add].
class AppLogBuffer {
  AppLogBuffer({this.capacity = 1000});

  final int capacity;
  final Queue<AppLogEntry> _entries = Queue<AppLogEntry>();

  List<AppLogEntry> get entries => List.unmodifiable(_entries.toList().reversed);

  void add(AppLogEntry entry) {
    _entries.addLast(entry);
    while (_entries.length > capacity) {
      _entries.removeFirst();
    }
  }

  void clear() => _entries.clear();

  List<AppLogEntry> filtered({
    String? query,
    AppLogLevel? level,
    AppLogCategory? category,
  }) {
    final q = query?.trim().toLowerCase();
    return entries.where((e) {
      if (level != null && e.level != level) return false;
      if (category != null && e.category != category) return false;
      if (q != null && q.isNotEmpty) {
        return e.message.toLowerCase().contains(q);
      }
      return true;
    }).toList();
  }
}

enum AppLogLevel { debug, info, warning, error }

enum AppLogCategory {
  general,
  network,
  authentication,
  synchronization,
  error,
}

class AppLogEntry {
  AppLogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.category = AppLogCategory.general,
  });

  final DateTime timestamp;
  final AppLogLevel level;
  final AppLogCategory category;
  final String message;

  String get levelLabel => level.name.toUpperCase();

  String toExportLine() =>
      '${timestamp.toIso8601String()} [$levelLabel] [${category.name}] $message';
}

/// Redacts common secret patterns from log text.
String sanitizeLogMessage(String raw) {
  var text = raw;
  text = text.replaceAll(
    RegExp(r'(Bearer\s+)[A-Za-z0-9\-._~+/]+=*', caseSensitive: false),
    r'$1***',
  );
  text = text.replaceAll(
    RegExp(
      r'eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+',
    ),
    '***JWT***',
  );
  text = text.replaceAll(
    RegExp(
      r'("?(?:password|passwd|pwd|token|accessToken|refreshToken|authorization|secret|apiKey|api_key)"?\s*[:=]\s*")[^"]*"',
      caseSensitive: false,
    ),
    r'$1***"',
  );
  text = text.replaceAll(
    RegExp(
      r'("?(?:password|passwd|pwd|token|accessToken|refreshToken|authorization|secret|apiKey|api_key)"?\s*[:=]\s*)[^\s,;}]+',
      caseSensitive: false,
    ),
    r'$1***',
  );
  return text;
}
