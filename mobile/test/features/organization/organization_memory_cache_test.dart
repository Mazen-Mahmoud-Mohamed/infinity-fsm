import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/organization/data/cache/organization_memory_cache.dart';

void main() {
  test('OrganizationMemoryCache.clear removes session-scoped entries', () {
    final cache = OrganizationMemoryCache();
    cache.set('org:profile', {'id': '1'});
    cache.set('org:settings', 'x');
    expect(cache.get<Map<String, Object?>>('org:profile'), isNotNull);

    cache.clear();

    expect(cache.get<Map<String, Object?>>('org:profile'), isNull);
    expect(cache.get<String>('org:settings'), isNull);
  });
}
