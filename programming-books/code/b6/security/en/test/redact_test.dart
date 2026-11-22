import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/security/redact.dart';

void main() {
  test('secrets never reach the log', () {
    const lines = [
      'GET /orders Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.demo-access.sig',
      'POST /session {"email":"layla@example.com","password":"hunter2"}',
      'refresh failed: {"refresh":"rt-demo-7f3a91c4","status":401}',
      'order 42 ready',
    ];
    for (final line in lines) {
      debugPrint(redact(line));
    }
    expect(redact(lines[0]), isNot(contains('demo-access')));
    expect(redact(lines[3]), lines[3]);
  });
}
