"""Writes the examples of Book 6, chapter "CI/CD, Flavors and Signing", in English and Arabic: one app built
for several environments from configuration files, Android product flavors, a release build signed with a
key whose password exists only in the environment, a release script that refuses unsafe builds, and the
CI script that a workflow runs on every push, run here for real.
Nothing secret is kept: the upload key is made fresh on every run in the build machine's home folder, and
its password is a random value in an environment variable during the run.
Run: python3 make.py   (needs Flutter 3.50.1 with the Android SDK, Java, Node.js and Playwright's Chromium)
"""
import secrets
import shutil
import sys
from pathlib import Path

import yaml

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent.parent / "b5"))
from kit import HOME, WORK, Session, flutter_gallery, sh, shot, write  # noqa: E402

AAPT2 = "/opt/android-sdk/build-tools/36.0.0/aapt2"
APKSIGNER = "/opt/android-sdk/build-tools/36.0.0/apksigner"

T = {
    "en": dict(
        w_rtl="",
        w_name="Bit Café", w_menu="Menu", w_server="Server", w_build="Build", w_debug="Debug tools are on",
        w_c_config="Decided when the app is built, from a file per environment: nothing here is secret.",
        w_c_banner="Every build that is not production says so, in a corner no one can miss and nothing else uses.",
        w_c_flavors="One app, several installable versions: each flavor has its own id and name.",
        w_c_signing="The upload key's file comes from android/key.properties (never in Git); its password from the environment.",
        w_c_ci="What CI runs on every push, and what you can run before pushing: stop at the first failure.",
        w_c_release="A release build only from a safe state: signing password present, build number higher than the last.",
        w_c_workflow="On every push and pull request, on a fresh Linux machine: the same script as on your computer.",
        w_t_defaults="the configuration this build was given", w_t_files="every environment defines the same keys",
        w_t_prod="the production values, from config/prod.json",
    ),
    "ar": dict(
        w_rtl="// من اليمين إلى اليسار، كما في الفصل 13 من الكتاب الخامس.\n"
              "builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),\n",
        w_name="بت كافيه", w_menu="القائمة", w_server="الخادم", w_build="النسخة", w_debug="أدوات التصحيح مفعّلة",
        w_c_config="تُقرَّر حين يُبنى التطبيق، من ملف لكل بيئة: لا شيء هنا سرّي.",
        w_c_banner="كل نسخة ليست للإنتاج تقول ذلك، في زاوية لا تفوت أحداً ولا يستخدمها شيء آخر.",
        w_c_flavors="تطبيق واحد، وعدة نسخ قابلة للتثبيت: لكل نكهة معرّفها واسمها.",
        w_c_signing="ملف مفتاح الرفع من android/key.properties (ولا يدخل Git أبداً)؛ وكلمة مروره من البيئة.",
        w_c_ci="ما يشغّله CI مع كل push، وما تستطيع تشغيله قبل الـ push: توقف عند أول فشل.",
        w_c_release="نسخة الإصدار لا تُبنى إلا من حالة آمنة: كلمة مرور التوقيع موجودة، ورقم البناء أعلى من الأخير.",
        w_c_workflow="مع كل push وطلب دمج، على جهاز Linux جديد: السكربت نفسه الذي على حاسوبك.",
        w_t_defaults="الإعدادات التي أُعطيت لهذه النسخة", w_t_files="كل بيئة تعرّف المفاتيح نفسها",
        w_t_prod="قيم الإنتاج، من config/prod.json",
    ),
}

FILES = {
    "root/config/dev.json": """{
  "FLAVOR": "dev",
  "API_URL": "https://dev.api.bitcafe.online",
  "SHOW_DEBUG": true
}
""",
    "root/config/prod.json": """{
  "FLAVOR": "prod",
  "API_URL": "https://api.bitcafe.online",
  "SHOW_DEBUG": false
}
""",
    "lib/config.dart": """// {w_c_config}
abstract final class AppConfig {
  static const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  static const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:8080');
  static const showDebug = bool.fromEnvironment('SHOW_DEBUG', defaultValue: true);

  static bool get isProduction => flavor == 'prod';
}
""",
    "lib/main_app.dart": """import 'package:material_ui/material_ui.dart';

import 'config.dart';

void main() => runApp(const CafeApp());

class CafeApp extends StatelessWidget {
  const CafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final app = MaterialApp(
      debugShowCheckedModeBanner: false,
      {w_rtl}
      title: '{w_name}',
      theme: ThemeData(colorSchemeSeed: AppConfig.isProduction ? Colors.brown : Colors.indigo),
      home: Scaffold(
        appBar: AppBar(title: const Text('{w_menu}')),
        body: ListView(
          children: [
            const ListTile(leading: Icon(Icons.dns), title: Text('{w_server}'), subtitle: Text(AppConfig.apiUrl)),
            const ListTile(leading: Icon(Icons.layers), title: Text('{w_build}'), subtitle: Text(AppConfig.flavor)),
            if (AppConfig.showDebug) const ListTile(leading: Icon(Icons.bug_report), title: Text('{w_debug}')),
          ],
        ),
      ),
    );
    // {w_c_banner}
    return AppConfig.isProduction
        ? app
        : Directionality(
            textDirection: TextDirection.ltr,
            child: Banner(message: AppConfig.flavor.toUpperCase(), location: BannerLocation.bottomEnd, child: app),
          );
  }
}
""",
    "test/config_test.dart": """import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:bit_app/config.dart';

void main() {
  test('{w_t_defaults}', () {
    debugPrint('flavor ${AppConfig.flavor}, server ${AppConfig.apiUrl}, debug tools ${AppConfig.showDebug}');
  });
}
""",
    "root/tool/ci.sh": """#!/bin/sh
# {w_c_ci}
set -e
echo "== format"
dart format --output=none --set-exit-if-changed lib test
echo "== analyze"
flutter analyze
echo "== test"
flutter test
echo "== build"
flutter build web --release --dart-define-from-file=config/prod.json -t lib/main_app.dart
""",
    "root/.github/workflows/ci.yml": """# {w_c_workflow}
name: CI
on:
  push:
  pull_request:
jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: 3.50.1
          cache: true
      - run: flutter pub get
      - run: sh tool/ci.sh
""",
    "root/tool/release.sh": """#!/bin/sh
# {w_c_release}
set -e
BUILD_NUMBER=${1:?usage: tool/release.sh BUILD_NUMBER}
if [ -z "$STORE_PASSWORD" ]; then
  echo "refusing: STORE_PASSWORD is not set, the build could not be signed" >&2
  exit 1
fi
LAST=$(cat release/last_build_number 2>/dev/null || echo 0)
if [ "$BUILD_NUMBER" -le "$LAST" ]; then
  echo "refusing: build $BUILD_NUMBER is not higher than the last release, $LAST" >&2
  exit 1
fi
flutter build apk --release --flavor prod --dart-define-from-file=config/prod.json \\
  -t lib/main_app.dart --build-name=1.4.0 --build-number="$BUILD_NUMBER"
mkdir -p release
echo "$BUILD_NUMBER" > release/last_build_number
""",
    # Projects
    "root/config/staging.json": """{
  "FLAVOR": "staging",
  "API_URL": "https://staging.api.bitcafe.online",
  "SHOW_DEBUG": true
}
""",
    "test/config_files_test.dart": """import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  test('{w_t_files}', () {
    final files = Directory('config').listSync().whereType<File>().toList()..sort((a, b) => a.path.compareTo(b.path));
    final keys = <String, Set<String>>{};
    for (final file in files) {
      final config = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
      keys[file.path] = config.keys.toSet();
      expect((config['API_URL']! as String).startsWith('https://'), isTrue, reason: '${file.path} must use https');
      debugPrint('${file.path.padRight(22)} ${config['FLAVOR']}  ${config['API_URL']}');
    }
    final first = keys.values.first;
    for (final MapEntry(key: path, value: names) in keys.entries) {
      expect(names, first, reason: '$path defines different keys');
    }
  });
}
""",
}

SHOTS = []

TESTS = [
    ("config-test.sh", "test/config_test.dart"),
    ("projects/config-files-test.sh", "test/config_files_test.dart"),
]

FLAVORS = """    // {w_c_flavors}
    flavorDimensions += "environment"
    productFlavors {
        create("dev") {
            dimension = "environment"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
            resValue("string", "app_name", "Bit Café Dev")
        }
        create("staging") {
            dimension = "environment"
            applicationIdSuffix = ".staging"
            versionNameSuffix = "-staging"
            resValue("string", "app_name", "Bit Café Staging")
        }
        create("prod") {
            dimension = "environment"
            resValue("string", "app_name", "Bit Café")
        }
    }

    buildFeatures {
        resValues = true
    }

    // {w_c_signing}
    signingConfigs {
        create("release") {
            val keyProperties = Properties()
            keyProperties.load(FileInputStream(rootProject.file("key.properties")))
            keyAlias = keyProperties.getProperty("keyAlias")
            storeFile = file(keyProperties.getProperty("storeFile"))
            storePassword = System.getenv("STORE_PASSWORD")
            keyPassword = System.getenv("STORE_PASSWORD")
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
"""


def fill_words(text, words):
    for k, v in words.items():
        text = text.replace("{" + k + "}", v)
    return text


def badging(apk):
    return (f"{AAPT2} dump badging {apk} | grep -E \"^package|^application-label:\"",
            f"aapt2 dump badging {apk} | grep -E \"^package|^application-label:\"")


def android(lang):
    """Flavors and signing in the Gradle build, then the real builds: dev and staging for testing, prod for
    release through the release script, and what each APK says it is. Done once, in English: the Arabic
    project is the same Android code."""
    project = WORK / HERE.name / lang / "bit_app"
    out = HERE / lang
    gradle = project / "android" / "app" / "build.gradle.kts"
    text = gradle.read_text()
    if "productFlavors" not in text:
        text = "import java.io.FileInputStream\nimport java.util.Properties\n\n" + text
        start = text.index("    buildTypes {")
        end = text.index("\n}\n", start)
        text = text[:start] + fill_words(FLAVORS, T[lang]) + text[end + 3:]
        gradle.write_text(text)
    manifest = project / "android" / "app" / "src" / "main" / "AndroidManifest.xml"
    manifest.write_text(manifest.read_text().replace('android:label="bit_app"', 'android:label="@string/app_name"'))
    keys = HOME / "keys"
    props = f"storeFile={keys}/upload-keystore.jks\nkeyAlias=upload\n"
    write(project / "android", {"key.properties": props})
    write(out, {"android/app/build.gradle.kts": text, "android/key.properties": props.replace(str(HOME), "~")})
    if lang != "en":
        for name in ("android-dev.sh", "projects/android-staging.sh", "release-refused.sh", "release.sh",
                     "projects/release-again.sh", "keytool.sh"):
            (out / name).parent.mkdir(parents=True, exist_ok=True)
            shutil.copy(HERE / "en" / name, out / name)
        return

    password = secrets.token_urlsafe(18)
    env = f"STORE_PASSWORD='{password}'"
    s = Session(project)
    sh(f"rm -rf {keys} && mkdir -p {keys}", project)
    s.run(f"{env} keytool -genkeypair -keystore {keys}/upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 "
          "-validity 10000 -alias upload -storepass:env STORE_PASSWORD -keypass:env STORE_PASSWORD "
          "-dname 'CN=Bit Cafe, O=Bit Cafe, C=EG' 2>&1 | tail -1",
          shown="keytool -genkeypair -keystore ~/keys/upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 "
                "-validity 10000 -alias upload -storepass:env STORE_PASSWORD -keypass:env STORE_PASSWORD "
                "-dname 'CN=Bit Cafe, O=Bit Cafe, C=EG'")
    s.save(out / "keytool.sh")

    built = lambda lines: [l for l in lines if l.startswith("✓")]  # noqa: E731
    s.run("flutter build apk --debug --flavor dev --dart-define-from-file=config/dev.json -t lib/main_app.dart", keep=built)
    s.run(*badging("build/app/outputs/flutter-apk/app-dev-debug.apk")[:1],
          shown=badging("build/app/outputs/flutter-apk/app-dev-debug.apk")[1])
    s.save(out / "android-dev.sh")
    s.run("flutter build apk --debug --flavor staging --dart-define-from-file=config/staging.json -t lib/main_app.dart",
          keep=built)
    s.run(badging("build/app/outputs/flutter-apk/app-staging-debug.apk")[0],
          shown=badging("build/app/outputs/flutter-apk/app-staging-debug.apk")[1])
    s.save(out / "projects" / "android-staging.sh")

    sh("rm -rf release", project)
    s.run("sh tool/release.sh 42", check=False)
    s.save(out / "release-refused.sh")
    s.run(f"{env} sh tool/release.sh 42", shown="sh tool/release.sh 42", keep=built)
    s.run(badging("build/app/outputs/flutter-apk/app-prod-release.apk")[0],
          shown=badging("build/app/outputs/flutter-apk/app-prod-release.apk")[1])
    s.run(f"{APKSIGNER} verify --print-certs build/app/outputs/flutter-apk/app-prod-release.apk | grep DN",
          shown="apksigner verify --print-certs build/app/outputs/flutter-apk/app-prod-release.apk | grep DN")
    s.save(out / "release.sh")
    s.run(f"{env} sh tool/release.sh 42", shown="sh tool/release.sh 42", check=False)
    s.save(out / "projects" / "release-again.sh")


def web(lang):
    """The same app built for the web twice, from two configuration files, and both screenshots."""
    project = WORK / HERE.name / lang / "bit_app"
    out = HERE / lang
    s = Session(project)
    for name in ("dev", "prod"):
        sh(f"flutter build web --release --dart-define-from-file=config/{name}.json -t lib/main_app.dart "
           f"-o build/web-{name} --no-web-resources-cdn", project, timeout=1800)
        shot(project / "build" / f"web-{name}", out / "shots" / f"{name}.png", "", 6000, "")
    s.run("flutter test --dart-define-from-file=config/prod.json test/config_test.dart")
    s.save(out / "config-prod-test.sh")
    s.run("sh tool/ci.sh", keep=lambda lines: [l for l in lines if l.startswith(("$", "==", "No issues", "✓"))
                                               or "All tests passed" in l])
    s.save(out / "ci.sh")


def main():
    flutter_gallery(HERE, T, FILES, SHOTS, TESTS)
    yaml.safe_load((HERE / "en" / ".github" / "workflows" / "ci.yml").read_text())
    for lang in T:
        web(lang)
        android(lang)


if __name__ == "__main__":
    main()
