import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/config/api_endpoint_service.dart';

void main() {
  group('ApiUrlNormalizer', () {
    test('accepts origin and appends /api/v1', () {
      expect(
        ApiUrlNormalizer.normalize('https://api.infinityfsm.com'),
        'https://api.infinityfsm.com/api/v1',
      );
    });

    test('keeps existing /api/v1 path', () {
      expect(
        ApiUrlNormalizer.normalize(
          'https://infinity-fsm-api.onrender.com/api/v1',
        ),
        'https://infinity-fsm-api.onrender.com/api/v1',
      );
    });

    test('trims whitespace', () {
      expect(
        ApiUrlNormalizer.normalize('  https://example.com  '),
        'https://example.com/api/v1',
      );
    });

    test('rejects empty and unsupported schemes', () {
      expect(ApiUrlNormalizer.normalize(''), isNull);
      expect(ApiUrlNormalizer.normalize('ftp://host'), isNull);
      expect(ApiUrlNormalizer.normalize('not-a-url'), isNull);
    });

    test('allows http for local/dev hosts', () {
      expect(
        ApiUrlNormalizer.normalize('http://192.168.1.10:3000'),
        'http://192.168.1.10:3000/api/v1',
      );
    });
  });
}
