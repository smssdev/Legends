"""Writes the examples of Book 6, chapter "Platform Channels and Native Code", in English and Arabic.
The native side runs for real on the machine this book is built on: a Linux desktop app, with C++ code
that answers a method channel by hand, a Pigeon API (generated for Dart, Kotlin, Swift and GObject) and an
event channel; integration tests run it under a virtual screen and print what Linux answered. The Kotlin
side is compiled into a real Android APK. The Swift side is generated but not compiled: that needs a Mac.
Run: python3 make.py   (needs Flutter 3.50.1 with the Linux desktop tools and the Android SDK, Xvfb,
ImageMagick, Node.js and Playwright's Chromium)
"""
import os
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent.parent / "b5"))
from kit import WORK, Session, flutter_gallery, popen, write  # noqa: E402

T = {
    "en": dict(
        w_rtl="",
        w_title="This device", w_system="System", w_version="Version", w_memory="Memory", w_battery="Battery",
        w_mb="MB", w_no_battery="No battery", w_no_host="No native side here", w_reading="Reading the device",
        w_c_hand="The channel by hand: a name, a method, and whatever the other side sends back.",
        w_c_missing="No handler on this platform (the web, say): not an error for the app.",
        w_c_pigeon="One definition; Pigeon writes the Dart, Kotlin, Swift and GObject code from it.",
        w_c_port="The app depends on this; the generated class already has these methods.",
        w_c_report="Every platform error becomes something the screen can say.",
        w_c_native_hand="The channel by hand: one method, \"info\", answered with a map.",
        w_c_native_pigeon="Pigeon: typed answers, through the generated code.",
        w_c_native_error="No battery is an answer too: an error with a code Dart can check.",
        w_c_native_events="An event channel: free memory every half second, while Dart listens.",
        w_c_register="Called once, when the window and its Flutter view exist.",
        w_c_kotlin_hand="The same channel by hand, in Kotlin.",
        w_c_kotlin_pigeon="The Pigeon API in Kotlin: the compiler checks it against the generated interface.",
        w_t_report="a missing battery becomes a sentence", w_t_host="no native side becomes a sentence",
        w_t_native="the native side answers, on Linux", w_t_hand="the channel by hand, with a mock",
        w_t_memory="free memory, streamed from C++",
        w_c_ltr="A version is left-to-right text: isolate it (U+2066 ... U+2069) inside any line.",
    ),
    "ar": dict(
        w_rtl="// من اليمين إلى اليسار، كما في الفصل 13 من الكتاب الخامس.\n"
              "builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),\n",
        w_title="هذا الجهاز", w_system="النظام", w_version="الإصدار", w_memory="الذاكرة", w_battery="البطارية",
        w_mb="ميغابايت", w_no_battery="لا بطارية", w_no_host="لا جانب أصلياً هنا", w_reading="نقرأ الجهاز",
        w_c_hand="القناة باليد: اسم، ودالة، وما يرسله الطرف الآخر.",
        w_c_missing="لا معالج على هذه المنصة (الويب مثلاً): ليس خطأً في التطبيق.",
        w_c_pigeon="تعريف واحد؛ ويكتب Pigeon منه كود Dart وKotlin وSwift وGObject.",
        w_c_port="التطبيق يعتمد على هذه؛ والصنف المولَّد فيه هاتان الدالتان أصلاً.",
        w_c_report="كل خطأ من المنصة يصير شيئاً تستطيع الشاشة قوله.",
        w_c_native_hand="القناة باليد: دالة واحدة، \"info\"، جوابها خريطة.",
        w_c_native_pigeon="Pigeon: أجوبة بأنواع، عبر الكود المولَّد.",
        w_c_native_error="غياب البطارية جواب أيضاً: خطأ برمز يستطيع Dart فحصه.",
        w_c_native_events="قناة أحداث: الذاكرة الحرة كل نصف ثانية، ما دام Dart يستمع.",
        w_c_register="تُنادى مرة واحدة، حين توجد النافذة وعرض Flutter فيها.",
        w_c_kotlin_hand="القناة نفسها باليد، بـ Kotlin.",
        w_c_kotlin_pigeon="واجهة Pigeon بـ Kotlin: المترجم يطابقها مع الواجهة المولَّدة.",
        w_t_report="غياب البطارية يصير جملة", w_t_host="غياب الجانب الأصلي يصير جملة",
        w_t_native="الجانب الأصلي يجيب، على Linux", w_t_hand="القناة باليد، مع بديل",
        w_t_memory="الذاكرة الحرة، تتدفق من C++",
        w_c_ltr="رقم الإصدار نص من اليسار إلى اليمين: اعزله (U+2066 ... U+2069) داخل أي سطر.",
    ),
}

FILES = {
    "root/pigeons/device.dart": """import 'package:pigeon/pigeon.dart';

// {w_c_pigeon}
@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/device/device_api.g.dart',
    kotlinOut: 'android/app/src/main/kotlin/com/example/bit_app/DeviceApi.g.kt',
    kotlinOptions: KotlinOptions(package: 'com.example.bit_app'),
    swiftOut: 'ios/Runner/DeviceApi.g.swift',
    gobjectHeaderOut: 'linux/runner/device_api.g.h',
    gobjectSourceOut: 'linux/runner/device_api.g.cc',
    gobjectOptions: GObjectOptions(module: 'Cafe'),
  ),
)
class DeviceInfo {
  DeviceInfo({required this.system, required this.version, required this.memoryMb});

  String system;
  String version;
  int memoryMb;
}

@HostApi()
abstract class DeviceApi {
  DeviceInfo info();
  int batteryLevel();
}
""",
    "lib/device/device_channel.dart": """import 'package:flutter/services.dart';

class HostInfo {
  const HostInfo(this.system, this.version, this.memoryMb);

  final String system;
  final String version;
  final int memoryMb;
}

// {w_c_hand}
class DeviceChannel {
  static const _channel = MethodChannel('bitcafe/device');

  Future<HostInfo?> info() async {
    try {
      final map = await _channel.invokeMapMethod<String, Object?>('info');
      return HostInfo(map!['system'] as String, map['version'] as String, map['memoryMb'] as int);
    } on MissingPluginException {
      // {w_c_missing}
      return null;
    }
  }
}

const _memory = EventChannel('bitcafe/memory');

Stream<int> freeMemoryMb() => _memory.receiveBroadcastStream().cast<int>();
""",
    "lib/device/device_source.dart": """import 'package:flutter/services.dart';

import 'device_api.g.dart';

// {w_c_port}
abstract interface class DeviceSource {
  Future<DeviceInfo> info();
  Future<int> batteryLevel();
}

class PigeonDevice extends DeviceApi implements DeviceSource {}

class DeviceReport {
  const DeviceReport({this.info, this.battery, this.problem});

  final DeviceInfo? info;
  final int? battery;
  final String? problem;
}

// {w_c_report}
Future<DeviceReport> readDevice(DeviceSource source) async {
  final DeviceInfo info;
  try {
    info = await source.info();
  } on PlatformException catch (error) {
    return DeviceReport(problem: error.code);
  }
  try {
    return DeviceReport(info: info, battery: await source.batteryLevel());
  } on PlatformException catch (error) {
    return DeviceReport(info: info, problem: error.code);
  }
}
""",
    "lib/device_app.dart": """import 'package:material_ui/material_ui.dart';

import 'device/device_source.dart';

void main() => runApp(
  MaterialApp(
    debugShowCheckedModeBanner: false,
    {w_rtl}
    theme: ThemeData(colorSchemeSeed: Colors.brown),
    home: DevicePage(source: PigeonDevice()),
  ),
);

class DevicePage extends StatelessWidget {
  const DevicePage({super.key, required this.source});

  final DeviceSource source;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('{w_title}')),
      body: FutureBuilder(
        future: readDevice(source),
        builder: (context, snapshot) {
          final report = snapshot.data;
          if (report == null) {
            return const Center(child: Text('{w_reading}'));
          }
          final info = report.info;
          if (info == null) {
            return Center(child: Text('{w_no_host} (${report.problem})'));
          }
          final battery = switch (report) {
            DeviceReport(:final int battery) => '$battery%',
            DeviceReport(problem: 'UNAVAILABLE') => '{w_no_battery}',
            DeviceReport(:final problem) => '$problem',
          };
          return ListView(
            children: [
              ListTile(leading: const Icon(Icons.computer), title: const Text('{w_system}'), subtitle: Text(info.system)),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('{w_version}'),
                // {w_c_ltr}
                subtitle: Text('\\u2066${info.version}\\u2069'),
              ),
              ListTile(leading: const Icon(Icons.memory), title: const Text('{w_memory}'), subtitle: Text('${info.memoryMb} {w_mb}')),
              ListTile(leading: const Icon(Icons.battery_unknown), title: const Text('{w_battery}'), subtitle: Text(battery)),
            ],
          );
        },
      ),
    );
  }
}
""",
    "test/report_test.dart": """import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/device/device_api.g.dart';
import 'package:bit_app/device/device_source.dart';
import 'package:bit_app/device_app.dart';

class Desktop implements DeviceSource {
  @override
  Future<DeviceInfo> info() async => DeviceInfo(system: 'Linux', version: '6.1', memoryMb: 8000);

  @override
  Future<int> batteryLevel() => throw PlatformException(code: 'UNAVAILABLE', message: 'This device has no battery.');
}

class Nowhere implements DeviceSource {
  @override
  Future<DeviceInfo> info() => throw PlatformException(code: 'channel-error');

  @override
  Future<int> batteryLevel() => throw PlatformException(code: 'channel-error');
}

void main() {
  testWidgets('{w_t_report}', (tester) async {
    await tester.pumpWidget(MaterialApp(home: DevicePage(source: Desktop())));
    await tester.pump();
    expect(find.text('{w_no_battery}'), findsOneWidget);
    expect(find.text('8000 {w_mb}'), findsOneWidget);
  });

  testWidgets('{w_t_host}', (tester) async {
    await tester.pumpWidget(MaterialApp(home: DevicePage(source: Nowhere())));
    await tester.pump();
    expect(find.text('{w_no_host} (channel-error)'), findsOneWidget);
  });
}
""",
    "root/integration_test/native_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/device/device_channel.dart';
import 'package:bit_app/device/device_source.dart';
import 'package:bit_app/device_app.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('{w_t_native}', (tester) async {
    final byHand = (await DeviceChannel().info())!;
    debugPrint('by hand: ${byHand.system} ${byHand.version}, ${byHand.memoryMb} MB');
    final report = await readDevice(PigeonDevice());
    final info = report.info!;
    debugPrint('pigeon:  ${info.system} ${info.version}, ${info.memoryMb} MB, battery: ${report.battery ?? report.problem}');

    app.main();
    await tester.pumpAndSettle();
    expect(find.text(info.system), findsOneWidget);
    expect(find.text('{w_no_battery}'), findsOneWidget);
  });
}
""",
    "root/linux/runner/cafe_channels.h": """#ifndef RUNNER_CAFE_CHANNELS_H_
#define RUNNER_CAFE_CHANNELS_H_

#include <flutter_linux/flutter_linux.h>

// {w_c_register}
void cafe_channels_register(FlBinaryMessenger* messenger);

#endif  // RUNNER_CAFE_CHANNELS_H_
""",
    "root/linux/runner/cafe_channels.cc": """#include "cafe_channels.h"

#include <sys/sysinfo.h>
#include <sys/utsname.h>

#include <cstring>

#include "device_api.g.h"

static int64_t megabytes(unsigned long amount, unsigned int unit) {
  return static_cast<int64_t>(amount) * unit / (1024 * 1024);
}

// {w_c_native_hand}
static FlMethodChannel* device_channel = nullptr;

static void on_device_call(FlMethodChannel* channel, FlMethodCall* call, gpointer user_data) {
  g_autoptr(FlMethodResponse) response = nullptr;
  if (strcmp(fl_method_call_get_name(call), "info") == 0) {
    struct utsname name;
    uname(&name);
    struct sysinfo memory;
    sysinfo(&memory);
    g_autoptr(FlValue) result = fl_value_new_map();
    fl_value_set_string_take(result, "system", fl_value_new_string(name.sysname));
    fl_value_set_string_take(result, "version", fl_value_new_string(name.release));
    fl_value_set_string_take(result, "memoryMb", fl_value_new_int(megabytes(memory.totalram, memory.mem_unit)));
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }
  g_autoptr(GError) error = nullptr;
  if (!fl_method_call_respond(call, response, &error)) {
    g_warning("Failed to answer %s: %s", fl_method_call_get_name(call), error->message);
  }
}

// {w_c_native_pigeon}
static CafeDeviceApiInfoResponse* info(gpointer user_data) {
  struct utsname name;
  uname(&name);
  struct sysinfo memory;
  sysinfo(&memory);
  g_autoptr(CafeDeviceInfo) device =
      cafe_device_info_new(name.sysname, name.release, megabytes(memory.totalram, memory.mem_unit));
  return cafe_device_api_info_response_new(device);
}

static CafeDeviceApiBatteryLevelResponse* battery_level(gpointer user_data) {
  g_autofree gchar* text = nullptr;
  if (!g_file_get_contents("/sys/class/power_supply/BAT0/capacity", &text, nullptr, nullptr)) {
    // {w_c_native_error}
    return cafe_device_api_battery_level_response_new_error("UNAVAILABLE", "This device has no battery.", nullptr);
  }
  return cafe_device_api_battery_level_response_new(g_ascii_strtoll(text, nullptr, 10));
}

static const CafeDeviceApiVTable device_api = {info, battery_level};

// {w_c_native_events}
static FlEventChannel* memory_channel = nullptr;
static guint memory_timer = 0;

static gboolean send_free_memory(gpointer user_data) {
  struct sysinfo memory;
  sysinfo(&memory);
  g_autoptr(FlValue) value = fl_value_new_int(megabytes(memory.freeram, memory.mem_unit));
  fl_event_channel_send(memory_channel, value, nullptr, nullptr);
  return G_SOURCE_CONTINUE;
}

static FlMethodErrorResponse* on_listen(FlEventChannel* channel, FlValue* args, gpointer user_data) {
  memory_timer = g_timeout_add(500, send_free_memory, nullptr);
  return nullptr;
}

static FlMethodErrorResponse* on_cancel(FlEventChannel* channel, FlValue* args, gpointer user_data) {
  g_clear_handle_id(&memory_timer, g_source_remove);
  return nullptr;
}

void cafe_channels_register(FlBinaryMessenger* messenger) {
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  device_channel = fl_method_channel_new(messenger, "bitcafe/device", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(device_channel, on_device_call, nullptr, nullptr);

  cafe_device_api_set_method_handlers(messenger, nullptr, &device_api, nullptr, nullptr);

  memory_channel = fl_event_channel_new(messenger, "bitcafe/memory", FL_METHOD_CODEC(codec));
  fl_event_channel_set_stream_handlers(memory_channel, on_listen, on_cancel, nullptr, nullptr);
}
""",
    # Projects
    "test/channel_test.dart": """import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/device/device_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('{w_t_hand}', () async {
    const channel = MethodChannel('bitcafe/device');
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final calls = <String>[];

    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      return {'system': 'Linux', 'version': '6.1.0', 'memoryMb': 15872};
    });
    final info = (await DeviceChannel().info())!;
    debugPrint('answered: ${info.system} ${info.version}, ${info.memoryMb} MB, after calls $calls');

    messenger.setMockMethodCallHandler(channel, (call) async => throw PlatformException(code: 'BUSY'));
    await expectLater(DeviceChannel().info(), throwsA(isA<PlatformException>().having((e) => e.code, 'code', 'BUSY')));
    debugPrint('an error from the platform reaches Dart as PlatformException(BUSY)');

    messenger.setMockMethodCallHandler(channel, null);
    debugPrint('no handler at all: ${await DeviceChannel().info()}');
  });
}
""",
    "root/integration_test/memory_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/device/device_channel.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('{w_t_memory}', (tester) async {
    final watch = Stopwatch()..start();
    final readings = await freeMemoryMb().take(4).toList();
    debugPrint('free memory: ${readings.map((mb) => '$mb MB').join(', ')} in ${watch.elapsedMilliseconds} ms');
    expect(readings, hasLength(4));
  });
}
""",
    "root/android/app/src/main/kotlin/com/example/bit_app/MainActivity.kt": """package com.example.bit_app

import android.app.ActivityManager
import android.content.Context
import android.os.BatteryManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        val device = AndroidDevice(this)

        // {w_c_kotlin_hand}
        MethodChannel(messenger, "bitcafe/device").setMethodCallHandler { call, result ->
            when (call.method) {
                "info" -> device.info().let {
                    result.success(mapOf("system" to it.system, "version" to it.version, "memoryMb" to it.memoryMb))
                }
                else -> result.notImplemented()
            }
        }

        DeviceApi.setUp(messenger, device)
    }
}

// {w_c_kotlin_pigeon}
class AndroidDevice(private val context: Context) : DeviceApi {
    override fun info(): DeviceInfo {
        val memory = ActivityManager.MemoryInfo()
        (context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager).getMemoryInfo(memory)
        return DeviceInfo(system = "Android", version = Build.VERSION.RELEASE, memoryMb = memory.totalMem / (1024 * 1024))
    }

    override fun batteryLevel(): Long {
        val battery = context.getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        val level = battery.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
        if (level <= 0) {
            throw FlutterError("UNAVAILABLE", "This device has no battery.", null)
        }
        return level.toLong()
    }
}
""",
}

SHOTS = [
    ("web.png", "lib/device_app.dart", "wait=1500"),
]

TESTS = [
    ("report-test.sh", "test/report_test.dart"),
    ("projects/channel-test.sh", "test/channel_test.dart"),
]

SETUP = [("pigeon.sh", "dart run pigeon --input pigeons/device.dart")]


def native(lang, screen):
    """Wires the C++ into the Linux runner, runs the integration tests on Linux, takes a screenshot of the
    real desktop app, and (once, for English) builds the Android app with the Kotlin side."""
    project = WORK / HERE.name / lang / "bit_app"
    out = HERE / lang
    runner = project / "linux" / "runner"
    app = (runner / "my_application.cc").read_text()
    if "cafe_channels" not in app:
        app = app.replace('#include "flutter/generated_plugin_registrant.h"\n',
                          '#include "cafe_channels.h"\n#include "flutter/generated_plugin_registrant.h"\n')
        app = app.replace("  fl_register_plugins(FL_PLUGIN_REGISTRY(view));\n",
                          "  fl_register_plugins(FL_PLUGIN_REGISTRY(view));\n"
                          "  cafe_channels_register(fl_engine_get_binary_messenger(fl_view_get_engine(view)));\n")
        app = app.replace("gtk_window_set_default_size(window, 1280, 720);", "gtk_window_set_default_size(window, 420, 640);")
        (runner / "my_application.cc").write_text(app)
    cmake = (runner / "CMakeLists.txt").read_text()
    if "cafe_channels.cc" not in cmake:
        cmake = cmake.replace('  "my_application.cc"\n', '  "my_application.cc"\n  "cafe_channels.cc"\n  "device_api.g.cc"\n')
        (runner / "CMakeLists.txt").write_text(cmake)
    write(out, {"linux/runner/my_application.cc": app, "linux/runner/CMakeLists.txt": cmake,
                "linux/runner/device_api.g.h": (runner / "device_api.g.h").read_text()})
    subprocess.run(["chown", "-R", "reader:reader", str(project)], check=False)

    s = Session(project)
    for name, test in (("native-test.sh", "native_test"), ("projects/memory-test.sh", "memory_test")):
        s.run(f"flutter test integration_test/{test}.dart -d linux")
        s.save(out / name)

    s.run("flutter build linux --release -t lib/device_app.dart", keep=lambda lines: [l for l in lines if l.startswith("✓")])
    s.lines = []
    bundle = project / "build" / "linux" / "x64" / "release" / "bundle" / "bit_app"
    running = popen(f"DISPLAY={screen} {bundle}", project)
    time.sleep(6)
    shots = out / "shots"
    shots.mkdir(parents=True, exist_ok=True)
    subprocess.run(["import", "-display", screen, "-window", "root", "-crop", "420x640+0+0", "+repage",
                    str(shots / "linux.png")], check=True)
    running.terminate()
    subprocess.run(["pkill", "-f", str(bundle)], check=False)

    if lang == "en":
        s.run("flutter build apk --debug -t lib/device_app.dart", keep=lambda lines: [l for l in lines if l.startswith("✓")])
        s.save(out / "projects" / "android-build.sh")
        kotlin = project / "android/app/src/main/kotlin/com/example/bit_app/DeviceApi.g.kt"
        lines = kotlin.read_text().split("\n")
        start = next(i for i, l in enumerate(lines) if l.startswith("interface DeviceApi"))
        write(out, {"projects/DeviceApi.g.kt.part": "\n".join(lines[start:start + 4]) + "\n  ...\n"})
    else:
        shutil.copy(HERE / "en" / "projects" / "android-build.sh", out / "projects" / "android-build.sh")
        shutil.copy(HERE / "en" / "projects" / "DeviceApi.g.kt.part", out / "projects" / "DeviceApi.g.kt.part")


def main():
    screen = ":95"
    xvfb = subprocess.Popen(["Xvfb", screen, "-screen", "0", "1024x768x24", "-ac"],
                            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    os.environ["DISPLAY"] = screen
    try:
        flutter_gallery(HERE, T, FILES, SHOTS, TESTS, setup=SETUP,
                        packages=["'dev:pigeon'", "'dev:integration_test:{\"sdk\":\"flutter\"}'"])
        for lang in T:
            native(lang, screen)
    finally:
        xvfb.terminate()


if __name__ == "__main__":
    main()
