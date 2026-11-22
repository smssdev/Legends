import 'dart:convert';
import 'dart:io';

// A café server that is overloaded two times out of three, and slow on /slow.
Future<void> main() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8091);
  var menuCalls = 0;
  // Each request is handled on its own: a slow one must not hold up the others.
  server.listen((request) async {
    final response = request.response..headers.contentType = ContentType.json;
    switch (request.uri.path) {
      case '/menu' when ++menuCalls % 3 != 0:
        response
          ..statusCode = 503
          ..write('{"error": "busy"}');
      case '/menu':
        response.write(
          jsonEncode([
            {'name': 'Latte', 'price': 45},
          ]),
        );
      case '/slow':
        await Future<void>.delayed(const Duration(seconds: 3));
        response.write('[]');
      case '/busy':
        response
          ..statusCode = 429
          ..headers.set('retry-after', '1')
          ..write('{"error": "slow down"}');
      default:
        response
          ..statusCode = 404
          ..write('{"error": "not found"}');
    }
    await response.close();
  });
}
