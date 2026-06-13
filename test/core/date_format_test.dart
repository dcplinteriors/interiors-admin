import 'package:dcpl_admin/core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats an ISO date as "dd MMM yyyy"', () {
    expect(formatDate('2026-06-07'), '07 Jun 2026');
  });

  test('falls back to the raw string on an unparseable input', () {
    expect(formatDate('not-a-date'), 'not-a-date');
  });
}
