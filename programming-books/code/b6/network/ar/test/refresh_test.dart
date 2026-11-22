import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:bit_app/api/auth_client.dart';

void main() {
  test('ثلاثة طلبات، وتجديد واحد', () async {
    var refreshes = 0;
    final server = MockClient((request) async {
      final ok = request.headers['authorization'] == 'Bearer fresh';
      return http.Response(ok ? '{}' : '', ok ? 200 : 401);
    });
    final client = AuthClient(
      server,
      'expired',
      refresh: () async {
        refreshes++;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return 'fresh';
      },
    );
    final answers = await Future.wait([
      for (final p in ['/a', '/b', '/c'])
        client.get(Uri.parse('https://cafe.example$p')),
    ]);
    expect([for (final r in answers) r.statusCode], [200, 200, 200]);
    expect(refreshes, 1);
  });
}
