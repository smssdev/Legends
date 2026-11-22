import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/observe/crashes.dart';

class Recorded implements ReportSink {
  final reports = <Map<String, Object?>>[];

  @override
  Future<void> send(Map<String, Object?> report) async => reports.add(report);
}

void main() {
  test('errors from build and from async code are both recorded', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    final flutterHandler = FlutterError.onError;
    final sink = Recorded();
    final crashes = Crashes(sink, appVersion: '1.4.0+42', platform: 'test')
      ..install();
    crashes.breadcrumbs
      ..add('open menu')
      ..add('open specials');
    FlutterError.presentError = (_) {};
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: StateError('No element'),
        stack: StackTrace.current,
      ),
    );
    PlatformDispatcher.instance.onError!(
      const FormatException('Unexpected character'),
      StackTrace.current,
    );
    for (final report in sink.reports) {
      debugPrint(
        '${report['fatal'] == true ? 'fatal    ' : 'non-fatal'} ${report['type']}: ${report['message']}',
      );
    }
    debugPrint('breadcrumbs: ${sink.reports.first['breadcrumbs']}');
    FlutterError.onError = flutterHandler;
    FlutterError.presentError = FlutterError.dumpErrorToConsole;
    expect(sink.reports, hasLength(2));
  });
}
