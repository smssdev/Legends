"""Writes the examples of Book 6, chapter "Security on the Device", in English and Arabic. Everything the
chapter claims an attacker can see, it shows for real: a token in plain text on Linux, the web's "secure"
storage decrypted with the key it keeps beside the values, a secret recovered from an obfuscated release
build, and certificate pinning tested against real HTTPS servers with throwaway certificates.
Run: python3 make.py   (needs Flutter 3.50.1 with the Linux desktop tools and the Android SDK, Xvfb, openssl,
Python's cryptography package, Node.js and Playwright's Chromium)
"""
import os
import shutil
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent.parent / "b5"))
from kit import WORK, Session, flutter_gallery, write  # noqa: E402

KEY = "cafe-maps-key-DEMO-0000"

T = {
    "en": dict(
        w_rtl="",
        w_title="Bit Café", w_sign_in="Sign in", w_signed_in="Signed in. Your session is saved on this device.",
        w_maps="Maps key length",
        w_c_plain="Convenient, and readable by anything that can read the app's files.",
        w_c_secure="Keychain on iOS, keys from the Android Keystore; on the web, see section 14.2.",
        w_c_memory="The short-lived token lives in memory only: it dies with the app.",
        w_c_define="Compiled into the app: anyone with the app can read it.",
        w_c_pin="Trust only these certificates, not the device's list of authorities.",
        w_c_redact="Logs leave the device (crash reports, support emails): nothing secret goes in.",
        w_c_certs="Test certificates for the pinning tests: self-signed, for localhost, made on every run, never committed.",
        w_t_pin="only the pinned server is trusted", w_t_rotate="two pins: the current certificate and the next one",
        w_t_redact="secrets never reach the log", w_t_tokens="tokens expire, and signing out forgets them",
        w_t_prefs="where shared_preferences keeps a token on Linux",
    ),
    "ar": dict(
        w_rtl="// من اليمين إلى اليسار، كما في الفصل 13 من الكتاب الخامس.\n"
              "builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),\n",
        w_title="بت كافيه", w_sign_in="سجّل الدخول", w_signed_in="تم الدخول. جلستك محفوظة على هذا الجهاز.",
        w_maps="طول مفتاح الخرائط",
        w_c_plain="مريح، ومقروء لأي شيء يستطيع قراءة ملفات التطبيق.",
        w_c_secure="Keychain في iOS، ومفاتيح من Android Keystore؛ وعلى الويب انظر القسم 14.2.",
        w_c_memory="الرمز قصير العمر يعيش في الذاكرة فقط: يموت مع التطبيق.",
        w_c_define="مترجَم داخل التطبيق: يستطيع قراءته كل من يملك التطبيق.",
        w_c_pin="ثق بهذه الشهادات فقط، لا بقائمة الجهات الموثوقة في الجهاز.",
        w_c_redact="السجلات تغادر الجهاز (تقارير الأعطال، ورسائل الدعم): لا يدخلها سر.",
        w_c_certs="شهادات لاختبارات التثبيت: موقَّعة ذاتياً، لـ localhost، تُصنع في كل تشغيل، ولا تُحفظ في المستودع.",
        w_t_pin="الخادم المثبَّت وحده موثوق", w_t_rotate="تثبيتان: شهادة اليوم والشهادة التالية",
        w_t_redact="الأسرار لا تصل إلى السجل", w_t_tokens="الرموز تنتهي، وتسجيل الخروج ينساها",
        w_t_prefs="أين تحفظ shared_preferences رمزاً على Linux",
    ),
}

FILES = {
    "lib/security/tokens.dart": """import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class SecureStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

// {w_c_secure}
class DeviceSecureStore implements SecureStore {
  final _storage = const FlutterSecureStorage();

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class TokenStore {
  TokenStore(this.secure, {DateTime Function()? now}) : now = now ?? DateTime.now;

  final SecureStore secure;
  final DateTime Function() now;
  // {w_c_memory}
  String? _access;
  DateTime? _expires;

  Future<void> signedIn({required String access, required Duration lifetime, required String refresh}) async {
    _access = access;
    _expires = now().add(lifetime);
    await secure.write('refresh', refresh);
  }

  String? get access => _expires != null && now().isBefore(_expires!) ? _access : null;

  Future<String?> refreshToken() => secure.read('refresh');

  Future<void> signOut() async {
    _access = null;
    _expires = null;
    await secure.delete('refresh');
  }
}
""",
    "lib/sign_in_app.dart": """import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'security/tokens.dart';

void main() => runApp(
  MaterialApp(
    debugShowCheckedModeBanner: false,
    {w_rtl}
    theme: ThemeData(colorSchemeSeed: Colors.brown),
    home: const SignInPage(),
  ),
);

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  var signedIn = false;

  Future<void> signIn() async {
    // The server's answer, in this demo.
    const access = 'eyJhbGciOiJIUzI1NiJ9.demo-access.sig';
    const refresh = 'rt-demo-7f3a91c4';
    // {w_c_plain}
    await SharedPreferencesAsync().setString('token', access);
    await TokenStore(DeviceSecureStore()).signedIn(access: access, lifetime: const Duration(minutes: 15), refresh: refresh);
    setState(() => signedIn = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('{w_title}')),
      body: Center(
        child: signedIn
            ? const Padding(padding: EdgeInsets.all(24), child: Text('{w_signed_in}', textAlign: TextAlign.center))
            : FilledButton(onPressed: signIn, child: const Text('{w_sign_in}')),
      ),
    );
  }
}
""",
    "root/tool/peek.py": """\"\"\"What anyone who can read this browser's storage can read: the secure storage keeps its key beside its values.\"\"\"
import base64
import json
import sys

from cryptography.hazmat.primitives.ciphers.aead import AESGCM

kept = json.load(open(sys.argv[1]))
print("shared_preferences, as stored:      ", kept["token"])
key = base64.b64decode(kept["FlutterSecureStorage"])
for name, value in kept.items():
    if name.startswith("FlutterSecureStorage."):
        iv, data = (base64.b64decode(part) for part in value.split("."))
        print(f"{name}, as stored:   {value[:32]}...")
        print(f"{name}, decrypted:   {AESGCM(key).decrypt(iv, data, None).decode()}")
""",
    "lib/maps_app.dart": """import 'package:material_ui/material_ui.dart';

// {w_c_define}
const mapsKey = String.fromEnvironment('MAPS_KEY');

final tiles = Uri.https('maps.example.com', '/tiles', {'key': mapsKey});

void main() => runApp(MaterialApp(home: Scaffold(body: Center(child: Text('{w_maps}: ${tiles.queryParameters['key']!.length}')))));
""",
    "lib/maps_length.dart": """import 'package:material_ui/material_ui.dart';

const mapsKey = String.fromEnvironment('MAPS_KEY');

// The first version: it shows only the key's length.
void main() => runApp(MaterialApp(home: Scaffold(body: Center(child: Text('{w_maps}: ${mapsKey.length}')))));
""",
    "lib/security/pinned_client.dart": """import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

// {w_c_pin}
http.Client pinnedClient(List<List<int>> certificates) {
  final context = SecurityContext(withTrustedRoots: false);
  for (final pem in certificates) {
    context.setTrustedCertificatesBytes(pem);
  }
  return IOClient(HttpClient(context: context));
}
""",
    "root/tool/make_certs.sh": """#!/bin/sh
# {w_c_certs}
mkdir -p test/certs
for name in pinned next other; do
  openssl req -x509 -newkey rsa:2048 -nodes -days 2 -subj "/CN=localhost" \\
    -addext "subjectAltName=DNS:localhost" -keyout test/certs/$name.key -out test/certs/$name.pem 2>/dev/null
done
ls test/certs
""",
    "test/pinning_test.dart": """import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:http/http.dart' as http;
import 'package:bit_app/security/pinned_client.dart';

Future<HttpServer> serve(String name) async {
  final context = SecurityContext()
    ..useCertificateChain('test/certs/$name.pem')
    ..usePrivateKey('test/certs/$name.key');
  final server = await HttpServer.bindSecure('localhost', 0, context);
  server.listen((request) => request.response
    ..write('menu from the $name server')
    ..close());
  return server;
}

Future<String> ask(http.Client client, HttpServer server) async {
  try {
    return (await client.get(Uri.parse('https://localhost:${server.port}/menu'))).body;
  } on HandshakeException {
    return 'refused: HandshakeException';
  } on http.ClientException catch (error) {
    return 'refused: ${error.message.split(':').first}';
  }
}

void main() {
  test('{w_t_pin}', () async {
    final pinnedServer = await serve('pinned');
    final otherServer = await serve('other');
    final pinned = pinnedClient([File('test/certs/pinned.pem').readAsBytesSync()]);
    final ordinary = http.Client();
    debugPrint('pinned client   -> pinned server: ${await ask(pinned, pinnedServer)}');
    debugPrint('pinned client   -> other server:  ${await ask(pinned, otherServer)}');
    debugPrint('ordinary client -> pinned server: ${await ask(ordinary, pinnedServer)}');
    await pinnedServer.close(force: true);
    await otherServer.close(force: true);
  });
}
""",
    "root/integration_test/prefs_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('{w_t_prefs}', (tester) async {
    await SharedPreferencesAsync().setString('token', 'eyJhbGciOiJIUzI1NiJ9.demo-access.sig');
    debugPrint('saved in ${(await getApplicationSupportDirectory()).path}');
  });
}
""",
    # Projects
    "lib/security/redact.dart": """// {w_c_redact}
final _rules = <(RegExp, String Function(Match))>[
  (RegExp(r'(Bearer\\s+)[A-Za-z0-9._~+/=-]+'), (m) => '${m[1]}***'),
  (RegExp(r'("(?:token|refresh|password)"\\s*:\\s*")[^"]*'), (m) => '${m[1]}***'),
  (RegExp(r'[A-Za-z0-9._%+-]+@([A-Za-z0-9.-]+\\.[A-Za-z]{2,})'), (m) => '***@${m[1]}'),
];

String redact(String line) => _rules.fold(line, (text, rule) => text.replaceAllMapped(rule.$1, rule.$2));
""",
    "test/redact_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/security/redact.dart';

void main() {
  test('{w_t_redact}', () {
    const lines = [
      'GET /orders Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.demo-access.sig',
      'POST /session {"email":"layla@example.com","password":"hunter2"}',
      'refresh failed: {"refresh":"rt-demo-7f3a91c4","status":401}',
      'order 42 ready',
    ];
    for (final line in lines) {
      debugPrint(redact(line));
    }
    expect(redact(lines[0]), isNot(contains('demo-access')));
    expect(redact(lines[3]), lines[3]);
  });
}
""",
    "test/tokens_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:bit_app/security/tokens.dart';

class MemoryStore implements SecureStore {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

void main() {
  test('{w_t_tokens}', () async {
    var clock = DateTime(2026, 11, 23, 9);
    final store = MemoryStore();
    final tokens = TokenStore(store, now: () => clock);
    await tokens.signedIn(access: 'a1', lifetime: const Duration(minutes: 15), refresh: 'r1');
    expect(tokens.access, 'a1');

    clock = clock.add(const Duration(minutes: 16));
    expect(tokens.access, isNull);
    expect(await tokens.refreshToken(), 'r1');

    await tokens.signOut();
    expect(await tokens.refreshToken(), isNull);
    expect(store.values, isEmpty);
  });
}
""",
    "test/rotation_test.dart": """import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/security/pinned_client.dart';

Future<HttpServer> serve(String name) async {
  final context = SecurityContext()
    ..useCertificateChain('test/certs/$name.pem')
    ..usePrivateKey('test/certs/$name.key');
  final server = await HttpServer.bindSecure('localhost', 0, context);
  server.listen((request) => request.response
    ..write('ok')
    ..close());
  return server;
}

void main() {
  test('{w_t_rotate}', () async {
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
""",
}

SHOTS = [
    ("signin.png", "lib/sign_in_app.dart", "button={w_sign_in}|wait=1500|storage=1"),
]

TESTS = [
    ("pinning-test.sh", "test/pinning_test.dart"),
    ("projects/redact-test.sh", "test/redact_test.dart"),
    ("projects/tokens-test.sh", "test/tokens_test.dart"),
    ("projects/rotation-test.sh", "test/rotation_test.dart"),
]

SETUP = [("certs.sh", "sh tool/make_certs.sh")]


def built(lines):
    return [l for l in lines if l.startswith("$") or l.startswith("✓")]


def extras(lang):
    """Linux: where the token lands. Web: the storage read back and decrypted. Android and web builds: the
    secret found in the files that are shipped (once, in English: the builds are the same code)."""
    project = WORK / HERE.name / lang / "bit_app"
    out = HERE / lang
    s = Session(project)
    s.run("flutter test integration_test/prefs_test.dart -d linux")
    s.run("cat ~/.local/share/com.example.bit_app/shared_preferences.json; echo")
    s.save(out / "prefs-test.sh")

    shutil.copy(out / "shots" / "signin-storage.json", project / "storage.json")
    s.run("cat storage.json")
    s.save(out / "storage.sh")
    s.run("python3 tool/peek.py storage.json")
    s.save(out / "peek.sh")

    if lang == "en":
        s.run(f"flutter build web -t lib/maps_length.dart --dart-define=MAPS_KEY={KEY}", keep=built)
        s.run(f'grep -c "{KEY}" build/web/main.dart.js', check=False)
        s.save(out / "secret-length.sh")
        s.run(f"flutter build web -t lib/maps_app.dart --dart-define=MAPS_KEY={KEY}", keep=built)
        s.run(f'grep -o "{KEY}" build/web/main.dart.js')
        s.save(out / "secret-web.sh")
        s.run(f"flutter build apk --release --obfuscate --split-debug-info=build/symbols -t lib/maps_app.dart "
              f"--dart-define=MAPS_KEY={KEY}", keep=built)
        s.run(f"unzip -p build/app/outputs/flutter-apk/app-release.apk lib/arm64-v8a/libapp.so | strings | grep {KEY}")
        s.save(out / "secret-apk.sh")
    else:
        for name in ("secret-length.sh", "secret-web.sh", "secret-apk.sh"):
            shutil.copy(HERE / "en" / name, out / name)
    (out / "shots" / "signin-storage.json").unlink()


def main():
    screen = ":96"
    xvfb = subprocess.Popen(["Xvfb", screen, "-screen", "0", "1024x768x24", "-ac"],
                            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    os.environ["DISPLAY"] = screen
    try:
        flutter_gallery(HERE, T, FILES, SHOTS, TESTS, setup=SETUP,
                        packages=["http", "shared_preferences", "flutter_secure_storage", "path_provider",
                                  "'dev:integration_test:{\"sdk\":\"flutter\"}'"])
        for lang in T:
            extras(lang)
    finally:
        xvfb.terminate()


if __name__ == "__main__":
    main()
