import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/security/pinned_client.dart';

Future<HttpServer> serve(String name) async {
  final context = SecurityContext()
    ..useCertificateChain('test/certs/$name.pem')
    ..usePrivateKey('test/certs/$name.key');
  final server = await HttpServer.bindSecure('localhost', 0, context);
  server.listen(
    (request) => request.response
      ..write('ok')
      ..close(),
  );
  return server;
}

void main() {
  test('two pins: the current certificate and the next one', () async {
    final client = pinnedClient([
      File('test/certs/pinned.pem').readAsBytesSync(),
      File('test/certs/next.pem').readAsBytesSync(),
    ]);
    for (final name in ['pinned', 'next', 'other']) {
      final server = await serve(name);
      try {
        await client.get(Uri.parse('https://localhost:${server.port}/'));
        debugPrint('$name: trusted');
      } on Exception catch (error) {
        debugPrint('$name: refused (${error.runtimeType})');
      }
      await server.close(force: true);
    }
  });
}
