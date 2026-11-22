import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/observe/crashes.dart';

void main() {
  test('البلاغ يصل إلى الخادم', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final received = <Map<String, Object?>>[];
    server.listen((request) async {
      received.add(
        jsonDecode(await utf8.decodeStream(request)) as Map<String, Object?>,
      );
      request.response.statusCode = 202;
      await request.response.close();
    });
    final crashes = Crashes(
      HttpSink(Uri.parse('http://127.0.0.1:${server.port}/reports')),
      appVersion: '1.4.0+42',
      platform: 'linux',
    );
    crashes.breadcrumbs.add('open specials');
    try {
      <String>[].first;
    } on StateError catch (error, stack) {
      await crashes.record(error, stack, fatal: false);
    }
    final report = received.single;
    debugPrint(
      const JsonEncoder.withIndent('  ').convert({
        ...report,
        'stack': (report['stack']! as List).take(2).toList(),
      }),
    );
    await server.close(force: true);
  });
}
