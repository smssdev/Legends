import 'dart:convert';
import 'dart:io';

// A whole server in one file of plain Dart: run it with dart run server.dart.
const menu = [
  {'id': 1, 'name': 'Latte', 'price': 45, 'image': 'latte'},
  {'id': 2, 'name': 'Mint tea', 'price': 25, 'image': 'tea'},
  {'id': 3, 'name': 'Orange juice', 'price': 40, 'image': 'juice'},
  {'id': 4, 'name': 'Cherry cake', 'price': 60, 'image': 'cake'},
  {'id': 5, 'name': 'Cookie', 'price': 20, 'image': 'cookie'},
  {'id': 6, 'name': 'Muffin', 'price': 35, 'image': 'muffin'},
];

var nextOrder = 1;

Future<void> main() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8080);
  print('Serving the café on http://localhost:${server.port}');
  await for (final request in server) {
    await handle(request);
    print('${request.method} ${request.uri} -> ${request.response.statusCode}');
  }
}

Future<void> handle(HttpRequest request) async {
  final response = request.response;
  // Let pages from other addresses (the app in a browser) read the answers.
  response.headers.set('Access-Control-Allow-Origin', '*');
  response.headers.set('Access-Control-Allow-Headers', 'Content-Type');
  final path = request.uri.path;
  final parts = path.split('/');

  if (request.method == 'OPTIONS') {
    await response.close();
  } else if (path.startsWith('/images/')) {
    final file = File('images/${parts.last}');
    if (await file.exists()) {
      response.headers.contentType = ContentType('image', 'png');
      await response.addStream(file.openRead());
      await response.close();
    } else {
      await send(response, 404, {'error': 'Not found'});
    }
  } else if (request.method == 'GET' && path == '/menu') {
    // A real network is never instant: wait half a second.
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final q = (request.uri.queryParameters['q'] ?? '').toLowerCase();
    await send(response, 200, [
      for (final d in menu)
        if ((d['name'] as String).toLowerCase().contains(q)) d,
    ]);
  } else if (request.method == 'GET' &&
      parts.length == 3 &&
      parts[1] == 'menu') {
    final id = int.tryParse(parts[2]);
    final found = menu.where((d) => d['id'] == id);
    if (found.isEmpty) {
      await send(response, 404, {'error': 'No drink ${parts[2]}'});
    } else {
      await send(response, 200, found.first);
    }
  } else if (request.method == 'POST' && path == '/orders') {
    final body = jsonDecode(
      await utf8.decoder.bind(request).join(),
    ) as Map<String, Object?>;
    final name = (body['name'] as String? ?? '').trim();
    final items = (body['items'] as List<Object?>? ?? []).cast<int>();
    // Never trust what arrives: check it, and say what is wrong.
    if (name.isEmpty) {
      await send(response, 400, {'error': 'A name is needed'});
    } else if (items.isEmpty) {
      await send(response, 400, {'error': 'The order is empty'});
    } else {
      final total = items.fold(
        0,
        (sum, id) =>
            sum + (menu.firstWhere((d) => d['id'] == id)['price'] as int),
      );
      await send(response, 201, {
        'id': nextOrder++,
        'name': name,
        'total': total,
      });
    }
  } else if (path.startsWith('/broken')) {
    await send(response, 500, {'error': 'The kitchen is on fire'});
  } else {
    await send(response, 404, {'error': 'Not found'});
  }
}

Future<void> send(HttpResponse response, int status, Object body) async {
  response.statusCode = status;
  response.headers.contentType = ContentType.json;
  response.write(const JsonEncoder.withIndent('  ').convert(body));
  await response.close();
}
