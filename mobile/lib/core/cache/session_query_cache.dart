/// In-memory session cache for list/dashboard payloads.
/// Survives Cubit dispose so re-opening a page can paint immediately.
class SessionQueryCache {
  SessionQueryCache({this.ttl = const Duration(minutes: 10)});

  final Duration ttl;
  final Map<String, _CacheEntry> _entries = <String, _CacheEntry>{};

  T? get<T>(String key) {
    final entry = _entries[key];
    if (entry == null) return null;
    if (DateTime.now().isAfter(entry.expiresAt)) {
      _entries.remove(key);
      return null;
    }
    final value = entry.value;
    if (value is T) {
      return value as T;
    }
    return null;
  }

  void set(String key, Object value) {
    _entries[key] = _CacheEntry(
      value: value,
      expiresAt: DateTime.now().add(ttl),
    );
  }

  void invalidate(String key) => _entries.remove(key);

  void invalidatePrefix(String prefix) {
    _entries.removeWhere((key, _) => key.startsWith(prefix));
  }

  /// Updates cached values whose keys start with [prefix] and match [T].
  void updatePrefix<T>(String prefix, T Function(T value) mapper) {
    final keys = _entries.keys.where((key) => key.startsWith(prefix)).toList();
    for (final key in keys) {
      final entry = _entries[key];
      if (entry == null) continue;
      if (DateTime.now().isAfter(entry.expiresAt)) {
        _entries.remove(key);
        continue;
      }
      final value = entry.value;
      if (value is! T) continue;
      final mapped = mapper(value as T);
      _entries[key] = _CacheEntry(
        value: mapped as Object,
        expiresAt: entry.expiresAt,
      );
    }
  }

  void clear() => _entries.clear();
}

class _CacheEntry {
  const _CacheEntry({required this.value, required this.expiresAt});

  final Object value;
  final DateTime expiresAt;
}
