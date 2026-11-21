"""Writes the examples of Book 5, chapter "Publishing to Google Play and the App Store", in English and
Arabic: Chapter 14's Bit Notes, made ready for release and really built, signed and checked.
Run: python3 make.py   (needs Flutter 3.50.1, Java 17 or later and the Android SDK; downloads Gradle's
packages the first time, which takes a while)

Nothing secret is kept here: the upload key is made fresh on every run, its password exists only in an
environment variable during the run, and the key itself never leaves the build machine.
"""
import secrets
import shutil
import sys
from pathlib import Path

from PIL import Image, ImageDraw

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent))
from kit import HOME, WORK, Session, sh, shot, write  # noqa: E402

NOTES = HERE.parent / "notes"
ORG = "online.bitcafe"

T = {
    "en": dict(
        c_props="The upload key's file and name, from android/key.properties (never in Git).",
        c_password="The password is not in any file: it comes from the environment when you build.",
        c_release="Release builds are signed with the upload key.",
        c_script="Everything before a release, in order; stop at the first failure.",
        s_analyze="1. No problems in the code", s_test="2. Every test passes",
        s_build="3. A signed bundle", s_check="4. Signed with our key?",
    ),
    "ar": dict(
        c_props="ملف مفتاح الرفع واسمه، من android/key.properties (ولا يدخل Git أبداً).",
        c_password="كلمة المرور ليست في أي ملف: تأتي من البيئة وقت البناء.",
        c_release="نسخ الإصدار تُوقَّع بمفتاح الرفع.",
        c_script="كل ما قبل الإصدار، بالترتيب؛ وتوقف عند أول فشل.",
        s_analyze="1. لا مشكلات في الكود", s_test="2. كل الاختبارات تنجح",
        s_build="3. حزمة موقّعة", s_check="4. موقّعة بمفتاحنا؟",
    ),
}

STRINGS = {
    "values": "Bit Notes",
    "values-ar": "ملاحظات بِت",
}

SIGNING = """    // {c_props}
    signingConfigs {
        create("release") {
            val keyProperties = Properties()
            keyProperties.load(FileInputStream(rootProject.file("key.properties")))
            keyAlias = keyProperties.getProperty("keyAlias")
            storeFile = file(keyProperties.getProperty("storeFile"))
            // {c_password}
            storePassword = System.getenv("STORE_PASSWORD")
            keyPassword = System.getenv("STORE_PASSWORD")
        }
    }

    buildTypes {
        release {
            // {c_release}
            signingConfig = signingConfigs.getByName("release")
        }
    }
"""


def fill_words(text, words):
    for k, v in words.items():
        text = text.replace("{" + k + "}", v)
    return text


def draw_icons(folder):
    """The app's icon, drawn here: a note on the café's brown, and the same note alone for Android's
    adaptive icon (which adds its own background and shape)."""
    folder.mkdir(parents=True, exist_ok=True)
    size = 1024

    def note(d, scale, cx, cy):
        w, h = 520 * scale, 620 * scale
        x0, y0 = cx - w / 2, cy - h / 2
        fold = 130 * scale
        d.polygon([(x0, y0), (x0 + w - fold, y0), (x0 + w, y0 + fold), (x0 + w, y0 + h), (x0, y0 + h)], fill="#FFF8E1")
        d.polygon([(x0 + w - fold, y0), (x0 + w - fold, y0 + fold), (x0 + w, y0 + fold)], fill="#D7CCC8")
        for i in range(4):
            y = y0 + (200 + i * 105) * scale
            d.rounded_rectangle([x0 + 70 * scale, y, x0 + w - (70 + (i == 3) * 160) * scale, y + 34 * scale],
                                radius=17 * scale, fill="#8D6E63")
        d.ellipse([x0 + 60 * scale, y0 - 40 * scale, x0 + 150 * scale, y0 + 50 * scale], fill="#E53935")

    full = Image.new("RGBA", (size, size), "#6D4C41")
    note(ImageDraw.Draw(full), 1.0, size / 2, size / 2 + 20)
    full.save(folder / "icon.png")
    fg = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    note(ImageDraw.Draw(fg), 0.62, size / 2, size / 2 + 12)
    fg.save(folder / "foreground.png")


def build(s, cmd, env, shown, tries=3):
    """Gradle downloads from public servers that sometimes refuse for a moment (HTTP 429): try again, and
    record only the run that finished."""
    for _ in range(tries):
        out, code = sh(f"{env} {cmd}", s.cwd, timeout=3000)
        if code == 0:
            break
    else:
        raise RuntimeError(out)
    s.lines.append("$ " + shown)
    s.lines.extend(l for l in out.split("\n") if "Already watching path" not in l)
    return out


def main():
    password = secrets.token_urlsafe(18)
    env = f"STORE_PASSWORD='{password}'"
    for lang, words in T.items():
        out = HERE / lang
        shutil.rmtree(out, ignore_errors=True)
        base = WORK / "publish" / lang
        shutil.rmtree(base, ignore_errors=True)
        base.mkdir(parents=True)
        home = HOME

        s = Session(base)
        s.run(f"flutter create --org {ORG} --platforms android,ios,web bit_notes",
              keep=lambda lines: [l for l in lines if l.startswith(("Creating", "Wrote", "All done"))])
        s.save(out / "create.sh")
        p = base / "bit_notes"

        # Chapter 14's app, as it is: its files, its packages, its translations.
        src = NOTES / lang
        for f in ["lib/delegates.dart", "lib/l10n/app_en.arb", "lib/l10n/app_ar.arb", "l10n.yaml",
                  "analysis_options.yaml", "test/model_test.dart", "test/app_test.dart"] + \
                 [f"lib/notes/{n}.dart" for n in ("note", "store", "model", "list_page", "edit_page")]:
            (p / f).parent.mkdir(parents=True, exist_ok=True)
            shutil.copy(src / f, p / f)
        main_dart = (src / "lib/notes_app.dart").read_text()
        (p / "lib/main.dart").write_text(main_dart)
        for t in ("test/model_test.dart", "test/app_test.dart"):
            (p / t).write_text((p / t).read_text().replace("package:bit_app/notes_app.dart",
                                                           "package:bit_notes/main.dart")
                               .replace("package:bit_app/", "package:bit_notes/"))
        (p / "test/widget_test.dart").unlink(missing_ok=True)
        pk = ["'flutter_localizations:{\"sdk\":\"flutter\"}'", "intl:any", "provider", "shared_preferences",
              "dev:flutter_launcher_icons"]
        sh("flutter pub add " + " ".join(pk), p)

        # Version 1.0.0, build 1.
        pubspec = (p / "pubspec.yaml").read_text().replace("version: 0.1.0+1", "version: 1.0.0+1")
        pubspec = pubspec.replace("\nflutter:\n", "\nflutter:\n  generate: true\n", 1)
        draw_icons(p / "assets/icon")
        pubspec += """
flutter_launcher_icons:
  image_path: assets/icon/icon.png
  android: true
  adaptive_icon_background: "#6D4C41"
  adaptive_icon_foreground: assets/icon/foreground.png
  ios: true
  remove_alpha_ios: true
  web:
    generate: true
"""
        (p / "pubspec.yaml").write_text(pubspec)
        write(out, {"pubspec.yaml": pubspec})
        shutil.copytree(p / "assets/icon", out / "assets/icon")

        # The name people see, in each language.
        manifest = p / "android/app/src/main/AndroidManifest.xml"
        manifest.write_text(manifest.read_text().replace('android:label="bit_notes"', 'android:label="@string/app_name"'))
        for folder, name in STRINGS.items():
            xml = f'<?xml version="1.0" encoding="utf-8"?>\n<resources>\n    <string name="app_name">{name}</string>\n</resources>\n'
            write(p / "android/app/src/main/res", {f"{folder}/strings.xml": xml})
            write(out, {f"android/app/src/main/res/{folder}/strings.xml": xml})
        write(out, {"android/app/src/main/AndroidManifest.xml": manifest.read_text()})

        s = Session(p)
        s.run("flutter gen-l10n")
        s.lines = []
        s.run("dart run flutter_launcher_icons", keep=lambda lines: [l for l in lines if l.strip()])
        s.save(out / "icons.sh")
        (out / "shots").mkdir(parents=True, exist_ok=True)
        shutil.copy(p / "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png", out / "shots/launcher.png")

        # The upload key: made once, kept safe, never in the project.
        # A fresh key on every run of this script (never the reader's way: a key is made once).
        sh("rm -f ~/keys/upload-keystore.jks", p)
        s = Session(p)
        s.run("mkdir -p ~/keys")
        s.run(f"{env} keytool -genkeypair -v -keystore ~/keys/upload-keystore.jks -storetype JKS "
              "-keyalg RSA -keysize 2048 -validity 10000 -alias upload "
              "-storepass:env STORE_PASSWORD -keypass:env STORE_PASSWORD "
              "-dname 'CN=Bit Cafe, O=Bit Cafe, C=EG'",
              shown="keytool -genkeypair -v -keystore ~/keys/upload-keystore.jks -storetype JKS "
                    "-keyalg RSA -keysize 2048 -validity 10000 -alias upload "
                    "-storepass:env STORE_PASSWORD -keypass:env STORE_PASSWORD "
                    "-dname 'CN=Bit Cafe, O=Bit Cafe, C=EG'",
              keep=lambda lines: [l for l in lines if "JAVA_" not in l])
        s.save(out / "keytool.sh")
        props = f"storeFile={home}/keys/upload-keystore.jks\nkeyAlias=upload\n"
        write(p / "android", {"key.properties": props})
        write(out, {"android/key.properties": props})
        s.run("grep -n -A3 'never publicly' android/.gitignore")
        s.save(out / "gitignore.sh")

        gradle = p / "android/app/build.gradle.kts"
        text = gradle.read_text()
        start = text.index("    buildTypes {")
        end = text.index("\n}\n", start)
        text = "import java.io.FileInputStream\nimport java.util.Properties\n\n" + text[:start] + \
            fill_words(SIGNING, words) + text[end + 1:]
        text = text.replace("        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).\n", "")
        gradle.write_text(text)
        write(out, {"android/app/build.gradle.kts": text})

        sh("dart format lib test && flutter analyze", p)
        s = Session(p)
        build(s, "flutter build appbundle", env, "flutter build appbundle")
        s.save(out / "build.sh")
        s.run("keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab",
              keep=lambda lines: [l for l in lines if "JAVA_" not in l and not l.startswith("\t ")][:8])
        s.save(out / "printcert.sh")

        # Project 1: a new version, checked inside the built app.
        s = Session(p)
        build(s, "flutter build apk --build-name 1.0.1 --build-number 2", env,
              "flutter build apk --build-name 1.0.1 --build-number 2")
        aapt = sorted(Path("/opt/android-sdk/build-tools").glob("*/aapt2"))[-1]
        s.run(f"{aapt} dump badging build/app/outputs/flutter-apk/app-release.apk | grep -E \"^package|application-label\"",
              shown="aapt2 dump badging build/app/outputs/flutter-apk/app-release.apk | grep -E \"^package|application-label\"")
        s.save(out / "projects/version.sh")

        # Project 2: the same app on the web.
        s = Session(p)
        s.run("flutter build web")
        s.save(out / "projects/web.sh")
        shot(p / "build/web", out / "shots/web.png", "", 6000, f"?lang={lang}")

        # Project 3: one script before every release.
        script = f"""#!/bin/sh
# {words['c_script']}
set -e
echo "{words['s_analyze']}"
flutter analyze
echo "{words['s_test']}"
flutter test
echo "{words['s_build']}"
flutter build appbundle
echo "{words['s_check']}"
keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab | grep Owner
"""
        write(p, {"tool/release.sh": script})
        write(out, {"projects/release.sh": script})
        s = Session(p)
        for _ in range(3):
            out_text, code = sh(f"{env} sh tool/release.sh", p, timeout=3000)
            if code == 0:
                break
        else:
            raise RuntimeError(out_text)
        s.lines.append("$ sh tool/release.sh")
        s.lines.extend(l for l in out_text.split("\n") if "JAVA_" not in l and "Already watching path" not in l)
        s.save(out / "projects/release-run.sh")
        print("wrote", out)


if __name__ == "__main__":
    main()
