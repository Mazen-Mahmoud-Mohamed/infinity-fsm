class OrganizationMemoryCache {
  final Map<String, Object?> _cache = {};

  T? get<T>(String key) {
    final value = _cache[key];
    if (value is T) {
      return value;
    }
    return null;
  }

  void set(String key, Object? value) {
    _cache[key] = value;
  }

  void clear() => _cache.clear();
}
