import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/services/app_log_buffer.dart';

void main() {
  test('sanitizeLogMessage redacts tokens and passwords', () {
    expect(
      sanitizeLogMessage('Authorization: Bearer abcdef.ghij.klmn'),
      contains('***'),
    );
    expect(
      sanitizeLogMessage('{"refreshToken":"secret-refresh","password":"hunter2"}'),
      isNot(contains('secret-refresh')),
    );
    expect(
      sanitizeLogMessage('{"refreshToken":"secret-refresh","password":"hunter2"}'),
      isNot(contains('hunter2')),
    );
  });
}
