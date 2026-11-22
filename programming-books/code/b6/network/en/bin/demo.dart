import 'dart:io';
import 'dart:math';

import 'package:bit_app/api/client.dart';
import 'package:bit_app/api/errors.dart';
import 'package:http/http.dart' as http;

Future<void> main() async {
  final watch = Stopwatch()..start();
  void log(String line) => stdout.writeln(
    '${(watch.elapsedMilliseconds / 1000).toStringAsFixed(1)}s  $line',
  );
  final api = ApiClient(
    http.Client(),
    base: 'http://localhost:8091',
    timeout: const Duration(seconds: 1),
    random: Random(1),
    log: log,
  );
  for (final path in ['/menu', '/slow', '/busy', '/missing']) {
    stdout.writeln('GET $path');
    watch.reset();
    try {
      stdout.writeln('  -> ${await api.get(path)}');
    } on ApiError catch (e) {
      stdout.writeln('  -> ${describe(e)}');
    }
  }
  api.client.close();
}
