import 'dart:convert';
import 'dart:ui';

import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';

// آخر ما فعله المستخدم: كثيراً ما يكون أسرع طريق إلى السبب.
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

  // بلاغ واحد: ماذا حدث، وأين، وفي أي إصدار، وماذا سبقه. بلا بيانات المستخدم.
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

  // كل خطأ، من كل مكان قد يأتي منه، يمر عبر record().
  void install() {
    // أخطاء البناء والتخطيط والرسم: Flutter يبلّغ عنها هنا.
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      record(
        details.exception,
        details.stack ?? StackTrace.current,
        fatal: false,
      );
    };
    // أخطاء لم يلتقطها أحد، في الـ futures والمؤقتات وكود المنصة.
    PlatformDispatcher.instance.onError = (error, stack) {
      record(error, stack, fatal: true);
      return true;
    };
  }
}
