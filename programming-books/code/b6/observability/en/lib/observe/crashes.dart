import 'dart:convert';
import 'dart:ui';

import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';

// The last few things the user did: often the fastest way to the cause.
class Breadcrumbs {
  Breadcrumbs(this.max);

  final int max;
  final _items = <String>[];

  void add(String step) {
    _items.add(step);
    if (_items.length > max) {
      _items.removeAt(0);
    }
  }

  List<String> get items => List.unmodifiable(_items);
}

abstract interface class ReportSink {
  Future<void> send(Map<String, Object?> report);
}

class HttpSink implements ReportSink {
  HttpSink(this.endpoint, {http.Client? client})
    : client = client ?? http.Client();

  final Uri endpoint;
  final http.Client client;

  @override
  Future<void> send(Map<String, Object?> report) async {
    await client.post(
      endpoint,
      headers: {'content-type': 'application/json'},
      body: jsonEncode(report),
    );
  }
}

class Crashes {
  Crashes(this.sink, {required this.appVersion, required this.platform});

  final ReportSink sink;
  final String appVersion;
  final String platform;
  final breadcrumbs = Breadcrumbs(10);

  // One report: what happened, where, in which version, and what came before. No user data.
  Future<void> record(Object error, StackTrace stack, {required bool fatal}) =>
      sink.send({
        'type': error.runtimeType.toString(),
        'message': error.toString(),
        'fatal': fatal,
        'version': appVersion,
        'platform': platform,
        'breadcrumbs': breadcrumbs.items,
        'stack': stack.toString().split('\n').take(8).toList(),
      });

  // Every error, from every place it can come from, goes through record().
  void install() {
    // Errors in build, layout and paint: Flutter reports them here.
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      record(
        details.exception,
        details.stack ?? StackTrace.current,
        fatal: false,
      );
    };
    // Errors no one caught, in futures, timers and platform code.
    PlatformDispatcher.instance.onError = (error, stack) {
      record(error, stack, fatal: true);
      return true;
    };
  }
}
