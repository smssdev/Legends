import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:http/http.dart' as http;
import 'package:bit_app/security/pinned_client.dart';

Future<HttpServer> serve(String name) async {
  final context = SecurityContext()
    ..useCertificateChain('test/certs/$name.pem')
    ..usePrivateKey('test/certs/$name.key');
  final server = await HttpServer.bindSecure('localhost', 0, context);
  server.listen(
    (request) => request.response
      ..write('menu from the $name server')
      ..close(),
  );
  return server;
}

Future<String> ask(http.Client client, HttpServer server) async {
  try {
    return (await client.get(
      Uri.parse('https://localhost:${server.port}/menu'),
    )).body;
  } on HandshakeException {
    return 'refused: HandshakeException';
  } on http.ClientException catch (error) {
    return 'refused: ${error.message.split(':').first}';
  }
}

void main() {
  test('only the pinned server is trusted', () async {
    final pinnedServer = await serve('pinned');
    final otherServer = await serve('other');
    final pinned = pinnedClient([
      File('test/certs/pinned.pem').readAsBytesSync(),
    ]);
    final ordinary = http.Client();
    debugPrint(
      'pinned client   -> pinned server: ${await ask(pinned, pinnedServer)}',
    );
    debugPrint(
      'pinned client   -> other server:  ${await ask(pinned, otherServer)}',
    );
    debugPrint(
      'ordinary client -> pinned server: ${await ask(ordinary, pinnedServer)}',
    );
    await pinnedServer.close(force: true);
    await otherServer.close(force: true);
  });
}
