"""Writes the examples of Book 6, chapter "Crash Reporting and Analytics", in English and Arabic. No outside
service is used: the app catches every error itself and sends reports to a real HTTP server started by the
test; a real release build for Linux, obfuscated, crashes on purpose, and its unreadable stack trace is
turned back into file names and lines with `flutter symbolize`; analytics events wait for consent.
Run: python3 make.py   (needs Flutter 3.50.1 with the Linux desktop tools, Xvfb, Node.js and Playwright's
Chromium)
"""
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent.parent / "b5"))
from kit import WORK, Session, flutter_gallery, write  # noqa: E402

T = {
    "en": dict(
        w_rtl="",
        w_menu="Menu", w_open="Open the specials", w_sorry="Something went wrong on this screen.",
        w_sorry_more="We have been told, and you can go back.", w_back="Back",
        w_c_install="Every error, from every place it can come from, goes through record().",
        w_c_flutter="Errors in build, layout and paint: Flutter reports them here.",
        w_c_async="Errors no one caught, in futures, timers and platform code.",
        w_c_friendly="In release builds, a broken widget shows this instead of a grey box.",
        w_c_crumbs="The last few things the user did: often the fastest way to the cause.",
        w_c_report="One report: what happened, where, in which version, and what came before. No user data.",
        w_c_consent="Nothing is collected before the user agrees, and everything queued is dropped when they say no.",
        w_c_batch="Events travel in batches: fewer requests, less battery.",
        w_c_crash="The release app below crashes on purpose a second after it starts.",
        w_c_material="It replaces the whole broken page, so it brings its own Material for text styles.",
        w_t_capture="errors from build and from async code are both recorded",
        w_t_server="a report reaches the server", w_t_consent="no consent, no events",
        w_t_batch="ten events, or thirty seconds, whichever comes first", w_t_rate="crash-free sessions per version",
    ),
    "ar": dict(
        w_rtl="// من اليمين إلى اليسار، كما في الفصل 13 من الكتاب الخامس.\n"
              "builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),\n",
        w_menu="القائمة", w_open="افتح العروض", w_sorry="حدث خطأ في هذه الشاشة.",
        w_sorry_more="وصلنا البلاغ، ويمكنك الرجوع.", w_back="رجوع",
        w_c_install="كل خطأ، من كل مكان قد يأتي منه، يمر عبر record().",
        w_c_flutter="أخطاء البناء والتخطيط والرسم: Flutter يبلّغ عنها هنا.",
        w_c_async="أخطاء لم يلتقطها أحد، في الـ futures والمؤقتات وكود المنصة.",
        w_c_friendly="في نسخ الإصدار يعرض الـ Widget المعطل هذا بدل مربع رمادي.",
        w_c_crumbs="آخر ما فعله المستخدم: كثيراً ما يكون أسرع طريق إلى السبب.",
        w_c_report="بلاغ واحد: ماذا حدث، وأين، وفي أي إصدار، وماذا سبقه. بلا بيانات المستخدم.",
        w_c_consent="لا يُجمع شيء قبل موافقة المستخدم، ويُحذف كل ما في الطابور حين يرفض.",
        w_c_batch="الأحداث تسافر دفعات: طلبات أقل، وبطارية أقل.",
        w_c_crash="تطبيق الإصدار أدناه ينهار عمداً بعد ثانية من بدئه.",
        w_c_material="إنه يحل محل الصفحة المعطلة كلها، فيحضر Material خاصاً به لأنماط النص.",
        w_t_capture="أخطاء البناء والكود غير المتزامن تُسجَّل كلها",
        w_t_server="البلاغ يصل إلى الخادم", w_t_consent="بلا موافقة، لا أحداث",
        w_t_batch="عشرة أحداث، أو ثلاثون ثانية، أيهما أسبق", w_t_rate="الجلسات بلا انهيار لكل إصدار",
    ),
}

FILES = {
    "lib/observe/crashes.dart": """import 'dart:convert';
import 'dart:ui';

import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';

// {w_c_crumbs}
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
  HttpSink(this.endpoint, {http.Client? client}) : client = client ?? http.Client();

  final Uri endpoint;
  final http.Client client;

  @override
  Future<void> send(Map<String, Object?> report) async {
    await client.post(endpoint, headers: {'content-type': 'application/json'}, body: jsonEncode(report));
  }
}

class Crashes {
  Crashes(this.sink, {required this.appVersion, required this.platform});

  final ReportSink sink;
  final String appVersion;
  final String platform;
  final breadcrumbs = Breadcrumbs(10);

  // {w_c_report}
  Future<void> record(Object error, StackTrace stack, {required bool fatal}) => sink.send({
    'type': error.runtimeType.toString(),
    'message': error.toString(),
    'fatal': fatal,
    'version': appVersion,
    'platform': platform,
    'breadcrumbs': breadcrumbs.items,
    'stack': stack.toString().split('\\n').take(8).toList(),
  });

  // {w_c_install}
  void install() {
    // {w_c_flutter}
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      record(details.exception, details.stack ?? StackTrace.current, fatal: false);
    };
    // {w_c_async}
    PlatformDispatcher.instance.onError = (error, stack) {
      record(error, stack, fatal: true);
      return true;
    };
  }
}
""",
    "lib/specials_app.dart": """import 'package:material_ui/material_ui.dart';

import 'observe/crashes.dart';

class PrintSink implements ReportSink {
  @override
  Future<void> send(Map<String, Object?> report) async => debugPrint('report: $report');
}

void main() {
  final crashes = Crashes(PrintSink(), appVersion: '1.4.0+42', platform: 'web')..install();
  // {w_c_friendly}
  ErrorWidget.builder = (details) => const FriendlyError();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      {w_rtl}
      theme: ThemeData(colorSchemeSeed: Colors.brown),
      home: MenuPage(crashes: crashes),
    ),
  );
}

class MenuPage extends StatelessWidget {
  const MenuPage({super.key, required this.crashes});

  final Crashes crashes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('{w_menu}')),
      body: Center(
        child: FilledButton(
          onPressed: () {
            crashes.breadcrumbs.add('open specials');
            Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SpecialsPage()));
          },
          child: const Text('{w_open}'),
        ),
      ),
    );
  }
}

class SpecialsPage extends StatelessWidget {
  const SpecialsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final specials = <String>[];
    return Scaffold(appBar: AppBar(), body: Text(specials.first));
  }
}

class FriendlyError extends StatelessWidget {
  const FriendlyError({super.key});

  @override
  Widget build(BuildContext context) {
    // {w_c_material}
    return Material(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            const Icon(Icons.sentiment_dissatisfied, size: 64),
            Text('{w_sorry}', style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
            const Text('{w_sorry_more}', textAlign: TextAlign.center),
            FilledButton(onPressed: () => Navigator.of(context).maybePop(), child: const Text('{w_back}')),
          ],
        ),
      ),
      ),
    );
  }
}
""",
    "test/capture_test.dart": """import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/observe/crashes.dart';

class Recorded implements ReportSink {
  final reports = <Map<String, Object?>>[];

  @override
  Future<void> send(Map<String, Object?> report) async => reports.add(report);
}

void main() {
  test('{w_t_capture}', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    final flutterHandler = FlutterError.onError;
    final sink = Recorded();
    final crashes = Crashes(sink, appVersion: '1.4.0+42', platform: 'test')..install();
    crashes.breadcrumbs
      ..add('open menu')
      ..add('open specials');
    FlutterError.presentError = (_) {};
    FlutterError.reportError(FlutterErrorDetails(exception: StateError('No element'), stack: StackTrace.current));
    PlatformDispatcher.instance.onError!(const FormatException('Unexpected character'), StackTrace.current);
    for (final report in sink.reports) {
      debugPrint('${report['fatal'] == true ? 'fatal    ' : 'non-fatal'} ${report['type']}: ${report['message']}');
    }
    debugPrint('breadcrumbs: ${sink.reports.first['breadcrumbs']}');
    FlutterError.onError = flutterHandler;
    FlutterError.presentError = FlutterError.dumpErrorToConsole;
    expect(sink.reports, hasLength(2));
  });
}
""",
    "test/server_test.dart": """import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/observe/crashes.dart';

void main() {
  test('{w_t_server}', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final received = <Map<String, Object?>>[];
    server.listen((request) async {
      received.add(jsonDecode(await utf8.decodeStream(request)) as Map<String, Object?>);
      request.response.statusCode = 202;
      await request.response.close();
    });
    final crashes = Crashes(HttpSink(Uri.parse('http://127.0.0.1:${server.port}/reports')), appVersion: '1.4.0+42', platform: 'linux');
    crashes.breadcrumbs.add('open specials');
    try {
      <String>[].first;
    } on StateError catch (error, stack) {
      await crashes.record(error, stack, fatal: false);
    }
    final report = received.single;
    debugPrint(const JsonEncoder.withIndent('  ').convert({...report, 'stack': (report['stack']! as List).take(2).toList()}));
    await server.close(force: true);
  });
}
""",
    "lib/crash_app.dart": """import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:material_ui/material_ui.dart';

class Order {
  Order(this.items);

  factory Order.fromJson(Map<String, Object?> json) => Order((json['items']! as List).cast<String>());

  final List<String> items;
}

int total(Map<String, Object?> json) => Order.fromJson(json).items.length * 45;

// {w_c_crash}
void main() {
  PlatformDispatcher.instance.onError = (error, stack) {
    stdout.writeln('crash: $error');
    stdout.writeln(stack);
    exit(1);
  };
  runApp(const MaterialApp(home: Scaffold(body: Center(child: Text('Bit Café')))));
  Timer(const Duration(seconds: 1), () => total({'customer': 'Layla'}));
}
""",
    # Projects
    "lib/observe/analytics.dart": """import 'dart:async';

abstract interface class EventTransport {
  Future<void> send(List<Map<String, Object?>> batch);
}

class Analytics {
  Analytics(this.transport, {this.batchSize = 10, this.every = const Duration(seconds: 30)});

  final EventTransport transport;
  final int batchSize;
  final Duration every;
  final _queue = <Map<String, Object?>>[];
  var _consent = false;
  Timer? _timer;

  // {w_c_consent}
  void setConsent(bool granted) {
    _consent = granted;
    if (!granted) {
      _queue.clear();
      _timer?.cancel();
    }
  }

  void log(String name, [Map<String, Object?> params = const {}]) {
    if (!_consent) {
      return;
    }
    _queue.add({'name': name, ...params});
    // {w_c_batch}
    if (_queue.length >= batchSize) {
      flush();
    } else {
      _timer ??= Timer(every, flush);
    }
  }

  Future<void> flush() async {
    _timer?.cancel();
    _timer = null;
    if (_queue.isEmpty) {
      return;
    }
    final batch = List.of(_queue);
    _queue.clear();
    await transport.send(batch);
  }
}
""",
    "test/consent_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/observe/analytics.dart';

class Sent implements EventTransport {
  final batches = <List<Map<String, Object?>>>[];

  @override
  Future<void> send(List<Map<String, Object?>> batch) async => batches.add(batch);
}

void main() {
  test('{w_t_consent}', () async {
    final sent = Sent();
    final analytics = Analytics(sent, batchSize: 2)..log('open_menu');
    analytics
      ..setConsent(true)
      ..log('open_menu')
      ..log('add_to_order', {'drink': 'latte'});
    analytics
      ..log('open_specials')
      ..setConsent(false)
      ..log('checkout');
    await analytics.flush();
    debugPrint('batches sent: ${sent.batches}');
    expect(sent.batches, hasLength(1));
  });
}
""",
    "test/batch_test.dart": """import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/observe/analytics.dart';

class Sent implements EventTransport {
  final batches = <int>[];

  @override
  Future<void> send(List<Map<String, Object?>> batch) async => batches.add(batch.length);
}

void main() {
  test('{w_t_batch}', () {
    fakeAsync((time) {
      final sent = Sent();
      final analytics = Analytics(sent)..setConsent(true);
      for (var i = 0; i < 23; i++) {
        analytics.log('scroll_menu');
      }
      time.flushMicrotasks();
      debugPrint('after 23 events:    batches of ${sent.batches}');
      time.elapse(const Duration(seconds: 29));
      debugPrint('after 29 seconds:   batches of ${sent.batches}');
      time.elapse(const Duration(seconds: 1));
      debugPrint('after 30 seconds:   batches of ${sent.batches}');
      expect(sent.batches, [10, 10, 3]);
    });
  });
}
""",
    "lib/observe/rates.dart": """class Session {
  const Session(this.version, {required this.crashed});

  final String version;
  final bool crashed;
}

Map<String, double> crashFreeRate(Iterable<Session> sessions) {
  final total = <String, int>{};
  final clean = <String, int>{};
  for (final session in sessions) {
    total.update(session.version, (n) => n + 1, ifAbsent: () => 1);
    if (!session.crashed) {
      clean.update(session.version, (n) => n + 1, ifAbsent: () => 1);
    }
  }
  return {for (final MapEntry(key: version, value: n) in total.entries) version: 100 * (clean[version] ?? 0) / n};
}
""",
    "test/rates_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/observe/rates.dart';

void main() {
  test('{w_t_rate}', () {
    final sessions = [
      for (var i = 0; i < 1000; i++) Session('1.3.0', crashed: i % 125 == 0),
      for (var i = 0; i < 400; i++) Session('1.4.0', crashed: i % 20 == 0),
    ];
    crashFreeRate(sessions).forEach((version, rate) => debugPrint('$version  ${rate.toStringAsFixed(1)}% of sessions without a crash'));
  });
}
""",
}

SHOTS = [
    ("menu.png", "lib/specials_app.dart", "wait=500"),
    ("friendly.png", "lib/specials_app.dart", "button={w_open}|wait=1500"),
]

TESTS = [
    ("capture-test.sh", "test/capture_test.dart"),
    ("server-test.sh", "test/server_test.dart"),
    ("projects/consent-test.sh", "test/consent_test.dart"),
    ("projects/batch-test.sh", "test/batch_test.dart"),
    ("projects/rates-test.sh", "test/rates_test.dart"),
]


def symbolize():
    """The release build for Linux, obfuscated, run until it crashes; then its stack trace, made readable."""
    project = WORK / HERE.name / "en" / "bit_app"
    s = Session(project)
    s.run("flutter build linux --release --obfuscate --split-debug-info=build/symbols -t lib/crash_app.dart",
          keep=lambda lines: [l for l in lines if l.startswith(("$", "✓"))])
    s.run("ls build/symbols")
    s.save(HERE / "en" / "build-obfuscated.sh")
    s.run("build/linux/x64/release/bundle/bit_app > crash.txt 2>/dev/null; cat crash.txt", check=False)
    s.save(HERE / "en" / "crash.sh")
    s.run("flutter symbolize -i crash.txt -d build/symbols/app.linux-x64.symbols", check=False)
    s.save(HERE / "en" / "symbolize.sh")
    s.run("dart pub global activate native_stack_traces", keep=lambda lines: [l for l in lines if l.startswith(("$", "Activated"))])
    s.run("dart pub global run native_stack_traces:decode translate -d build/symbols/app.linux-x64.symbols -i crash.txt "
          "| grep '^#' | head -3")
    s.save(HERE / "en" / "decode.sh")
    for name in ("build-obfuscated.sh", "crash.sh", "symbolize.sh", "decode.sh"):
        shutil.copy(HERE / "en" / name, HERE / "ar" / name)


def main():
    screen = ":97"
    xvfb = subprocess.Popen(["Xvfb", screen, "-screen", "0", "1024x768x24", "-ac"],
                            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    os.environ["DISPLAY"] = screen
    try:
        flutter_gallery(HERE, T, FILES, SHOTS, TESTS, packages=["http", "'dev:fake_async'"])
        symbolize()
    finally:
        xvfb.terminate()


if __name__ == "__main__":
    main()
