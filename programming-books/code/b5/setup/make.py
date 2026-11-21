"""Writes the examples of Book 5, chapter "Setting Up Flutter", in English and Arabic, and records them.
Run: python3 make.py   (needs Flutter 3.50.1, Node.js and Playwright's Chromium; takes a few minutes)

Everything the chapter shows really happened on the build machine: flutter --version and flutter doctor,
creating the first project, running it with hot reload (two screenshots, before and after), a test that
fails after the first change and passes once it is updated, flutter analyze and dart format, and the three
practice projects with their screenshots and tests. Transcripts are *.sh; screenshots are shots/*.png.

Only the files the reader writes are kept here (lib/main.dart, test/widget_test.dart); `flutter create`
makes the rest, exactly as in the chapter.
"""
import shutil
import subprocess
import sys
import threading
import time
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent))
from kit import WORK, Session, fill, popen, sh, shot, write  # noqa: E402

T = {
    "en": dict(
        w_title="Hello Bit", w_hello="Hello, Flutter!", w_hello2="Hello, hot reload!",
        w_c_main="Every Dart program starts by running main().",
        w_c_app="The whole app is one widget: a description of what to show.",
        w_c_seed="The colour of the bar, and of the text on it.",
        w_t_shows="shows the greeting",
        w_s_version="Which Flutter, and which Dart inside it?", w_s_doctor="Is everything ready?",
        w_s_create="A new project called hello_bit", w_s_run="Run it (here in a browser; on your machine, an emulator or a phone)",
        w_s_reload="lib/main.dart is saved with a new colour and text, then r is pressed",
        w_s_test1="Run the tests that came with the template", w_s_test2="The test, updated for our app",
        w_s_analyze="Look for problems without running anything", w_s_format="Format every file the standard way",
        w_s_devices="Which devices can run the app right now?",
        w_s_old="The same app with the import from older tutorials",
        # Project 1: a name card
        w_card_title="My Card", w_card_name="Sara Ahmed", w_card_job="Flutter developer in training",
        w_card_city="Cairo, Egypt",
        w_c_card_col="A Column puts its children one under the other (Chapter 6 explains it).",
        w_c_gap="An empty box of 8 pixels: a gap between two lines.",
        # Project 2 and 3: the counter
        w_t_two="counts in twos from ten", w_t_reset="the reset button goes back to zero",
        w_c_reset="A button in the bar: pressing it puts the counter back to zero.",
        w_s_test_two="The counter that starts at 10 and counts in twos",
        w_s_test_reset="The counter with a reset button",
        w_tip_reset="Reset",
    ),
    "ar": dict(
        w_title="مرحباً بِت", w_hello="مرحباً يا Flutter!", w_hello2="مرحباً بالتحديث الفوري!",
        w_c_main="كل برنامج Dart يبدأ بتشغيل main().",
        w_c_app="التطبيق كله Widget واحد: وصف لما يُعرض على الشاشة.",
        w_c_seed="لون الشريط، ولون النص عليه.",
        w_t_shows="يعرض التحية",
        w_s_version="أي Flutter، وأي Dart بداخله؟", w_s_doctor="هل كل شيء جاهز؟",
        w_s_create="مشروع جديد اسمه hello_bit", w_s_run="شغّله (هنا في متصفح، وعندك في محاكٍ أو جوال)",
        w_s_reload="حُفظ lib/main.dart بلون ونص جديدين، ثم ضُغط r",
        w_s_test1="شغّل الاختبارات التي جاءت مع القالب", w_s_test2="الاختبار بعد تحديثه لتطبيقنا",
        w_s_analyze="ابحث عن المشكلات دون تشغيل أي شيء", w_s_format="نسّق كل الملفات بالطريقة المعتمدة",
        w_s_devices="أي الأجهزة يمكنها تشغيل التطبيق الآن؟",
        w_s_old="التطبيق نفسه بالاستيراد الذي تستخدمه الدروس القديمة",
        w_card_title="بطاقتي", w_card_name="سارة أحمد", w_card_job="مطوّرة تطبيقات تحت التدريب",
        w_card_city="القاهرة، مصر",
        w_c_card_col="Column يضع أبناءه واحداً تحت الآخر (يشرحه الفصل 6).",
        w_c_gap="صندوق فارغ بارتفاع 8 بكسل: مسافة بين سطرين.",
        w_t_two="يعدّ اثنين اثنين بدءاً من عشرة", w_t_reset="زر التصفير يعيد العداد إلى الصفر",
        w_c_reset="زر في الشريط: الضغط عليه يعيد العداد إلى الصفر.",
        w_s_test_two="العداد الذي يبدأ من 10 ويعدّ اثنين اثنين",
        w_s_test_reset="العداد بزر للتصفير",
        w_tip_reset="تصفير",
    ),
}

MAIN_V1 = """import 'package:material_ui/material_ui.dart';

// {w_c_main}
void main() {
  runApp(const HelloBitApp());
}

// {w_c_app}
class HelloBitApp extends StatelessWidget {
  const HelloBitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '{w_title}',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('{w_title}'),
          centerTitle: true,
          // {w_c_seed}
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('{w_hello}', style: TextStyle(fontSize: 32)),
        ),
      ),
    );
  }
}
"""
# The change made while the app runs: another colour and another greeting.
MAIN = MAIN_V1.replace("Colors.indigo", "Colors.teal").replace("{w_hello}", "{w_hello2}")

TEST = """import 'package:flutter_test/flutter_test.dart';
import 'package:hello_bit/main.dart';

void main() {
  testWidgets('{w_t_shows}', (WidgetTester tester) async {
    await tester.pumpWidget(const HelloBitApp());
    expect(find.text('{w_hello2}'), findsOneWidget);
  });
}
"""

CARD = """import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const NameCardApp());
}

class NameCardApp extends StatelessWidget {
  const NameCardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('{w_card_title}'),
          centerTitle: true,
          backgroundColor: Colors.deepOrange,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          // {w_c_card_col}
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person, size: 96, color: Colors.deepOrange),
              Text('{w_card_name}', style: TextStyle(fontSize: 32)),
              // {w_c_gap}
              SizedBox(height: 8),
              Text('{w_card_job}', style: TextStyle(fontSize: 18)),
              Text('{w_card_city}', style: TextStyle(fontSize: 18)),
            ],
          ),
        ),
      ),
    );
  }
}
"""

# Projects 2 and 3 start from the counter app that `flutter create` writes, with these exact changes.
TWO = [("int _counter = 0;", "int _counter = 10;"), ("_counter++;", "_counter += 2;")]
TWO_TEST = [("expect(find.text('0'), findsOneWidget);", "expect(find.text('10'), findsOneWidget);"),
            ("expect(find.text('1'), findsNothing);", "expect(find.text('12'), findsNothing);"),
            ("expect(find.text('0'), findsNothing);", "expect(find.text('10'), findsNothing);"),
            ("expect(find.text('1'), findsOneWidget);", "expect(find.text('12'), findsOneWidget);"),
            ("testWidgets('Counter increments smoke test'", "testWidgets('{w_t_two}'")]
RESET = [("        title: Text(widget.title),\n",
          "        title: Text(widget.title),\n"
          "        // {w_c_reset}\n"
          "        actions: [\n"
          "          IconButton(\n"
          "            icon: const Icon(Icons.refresh),\n"
          "            tooltip: '{w_tip_reset}',\n"
          "            onPressed: () {\n"
          "              setState(() {\n"
          "                _counter = 0;\n"
          "              });\n"
          "            },\n"
          "          ),\n"
          "        ],\n")]
RESET_TEST = """import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:counter_reset/main.dart';

void main() {
  testWidgets('{w_t_reset}', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.byIcon(Icons.add));
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pump();
    expect(find.text('0'), findsOneWidget);
  });
}
"""


def edit(text, changes):
    for old, new in changes:
        assert text.count(old) == 1, f"the template changed: {old!r}"
        text = text.replace(old, new)
    return text


def notes(words, lines):
    """A transcript recorded once, with its # comments in the language of the book."""
    return "\n".join(fill(l, words) for l in lines) + "\n"


def run_with_reload(project, out_dir, words):
    """flutter run in a browser, a screenshot, a change saved and hot reloaded, another screenshot."""
    signal = WORK / "signal"
    shutil.rmtree(signal, ignore_errors=True)
    signal.mkdir(parents=True)
    sh("true", WORK)  # gives the folder to the reader user
    proc = popen("flutter run -d web-server --web-port 8099", project, stdin=subprocess.PIPE,
                 stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, bufsize=1)
    lines = []
    threading.Thread(target=lambda: [lines.append(l) for l in proc.stdout], daemon=True).start()
    while not any("is being served" in l for l in lines):
        if proc.poll() is not None:
            raise RuntimeError("".join(lines))
        time.sleep(0.5)
    time.sleep(2)
    browser = subprocess.Popen(["node", str(HERE.parent / "snap.cjs"), "http://localhost:8099/",
                                str(out_dir / "shots" / "first-run.png"), "--live", str(signal)])
    while not (signal / "ready").exists():
        time.sleep(0.5)
    (project / "lib" / "main.dart").write_text(fill(MAIN, words))
    before = len(lines)
    proc.stdin.write("r")
    proc.stdin.flush()
    while not any("Reloaded" in l or "hot reload" in l and "ms" in l for l in lines[before:]):
        time.sleep(0.3)
    time.sleep(1)
    (signal / "go").write_text(str(out_dir / "shots" / "hot-reload.png"))
    browser.wait()
    proc.stdin.write("q")
    proc.stdin.flush()
    proc.wait(timeout=60)
    time.sleep(0.5)
    return [l.rstrip("\n").replace("\r", "") for l in lines], before


def main():
    shutil.rmtree(WORK, ignore_errors=True)
    WORK.mkdir(parents=True)
    rec = {}

    # The tools themselves (the same for both books): recorded once.
    s = Session(WORK)
    s.note("{w_s_version}")
    s.run("flutter --version")
    rec["version"] = s.lines
    s = Session(WORK)
    s.note("{w_s_doctor}")
    s.run("flutter doctor", check=False)
    rec["doctor"] = s.lines
    s = Session(WORK)
    s.note("{w_s_devices}")
    s.run("flutter devices", check=False)
    rec["devices"] = s.lines

    for lang, words in T.items():
        out = HERE / lang
        shutil.rmtree(out, ignore_errors=True)
        (out / "shots").mkdir(parents=True)
        for key in ("version", "doctor", "devices"):
            (out / f"{key}.sh").write_text(notes(words, rec[key]))
        base = WORK / lang
        base.mkdir()

        # The first project, created, opened, changed while running, tested.
        s = Session(base)
        s.note(fill("{w_s_create}", words))
        s.run("flutter create hello_bit")
        s.save(out / "create.sh")
        project = base / "hello_bit"
        template = (project / "lib" / "main.dart").read_text()
        write(out / "template", {"main.dart": template, "widget_test.dart": (project / "test" / "widget_test.dart").read_text()})
        tree = ["hello_bit/"] + sorted(
            f"  {p.name}{'/' if p.is_dir() else ''}" for p in project.iterdir() if p.name not in (".dart_tool", ".idea"))
        (out / "tree.txt").write_text("\n".join(tree) + "\n")

        write(out / "hello_bit", {"lib/main_v1.dart": fill(MAIN_V1, words)})
        (project / "lib" / "main.dart").write_text(fill(MAIN_V1, words))
        lines, pressed = run_with_reload(project, out, words)
        started = [fill("# {w_s_run}", words), "$ flutter run"] + [l for l in lines[:pressed] if l.strip()]
        reloaded = [fill("# {w_s_reload}", words), "r"] + [l for l in lines[pressed:] if l.strip()]
        (out / "run.sh").write_text("\n".join(started) + "\n")
        (out / "reload.sh").write_text("\n".join(reloaded) + "\n")

        s = Session(project)
        s.note(fill("{w_s_test1}", words))
        s.run("flutter test", check=False)
        s.save(out / "test-fails.sh")
        write(project, {"test/widget_test.dart": fill(TEST, words)})
        s.note(fill("{w_s_test2}", words))
        s.run("flutter test")
        s.save(out / "test-passes.sh")
        s.note(fill("{w_s_analyze}", words))
        s.run("flutter analyze")
        s.note(fill("{w_s_format}", words))
        s.run("dart format .")
        s.save(out / "analyze.sh")
        # As formatted by dart format above (a long Arabic greeting goes on lines of its own).
        formatted = (project / "lib" / "main.dart").read_text()
        write(out / "hello_bit", {"lib/main.dart": formatted, "test/widget_test.dart": fill(TEST, words),
                                  "pubspec.yaml": (project / "pubspec.yaml").read_text()})

        # What the analyzer says about the import that older tutorials use.
        old = fill(MAIN, words).replace("package:material_ui/material_ui.dart", "package:flutter/material.dart")
        write(project, {"lib/main.dart": old})
        s.note(fill("{w_s_old}", words))
        s.run("flutter analyze", check=False)
        s.save(out / "old-import.sh")
        write(project, {"lib/main.dart": formatted})

        # Project 1: a name card, built for release (no debug banner) and photographed.
        sh("flutter create name_card", base)
        card = base / "name_card"
        write(card, {"lib/main.dart": fill(CARD, words)})
        (card / "test" / "widget_test.dart").unlink()
        sh("dart format . && flutter analyze && flutter build web --no-web-resources-cdn", card)
        shot(card / "build" / "web", out / "shots" / "name-card.png")
        write(out / "projects" / "name_card", {"lib/main.dart": (card / "lib" / "main.dart").read_text()})

        # Project 2: the counter from ten, in twos, with its test changed to match.
        sh("flutter create counter_by_two", base)
        two = base / "counter_by_two"
        main_two = edit((two / "lib" / "main.dart").read_text(), TWO)
        test_two = fill(edit((two / "test" / "widget_test.dart").read_text(), TWO_TEST), words)
        write(two, {"lib/main.dart": main_two, "test/widget_test.dart": test_two})
        sh("dart format .", two)
        main_two, test_two = (two / "lib" / "main.dart").read_text(), (two / "test" / "widget_test.dart").read_text()
        s = Session(two)
        s.note(fill("{w_s_test_two}", words))
        s.run("flutter test")
        s.save(out / "projects" / "counter-by-two.sh")
        write(out / "projects" / "counter_by_two", {"lib/main.dart": main_two, "test/widget_test.dart": test_two})

        # Project 3: a reset button, tested, and a screenshot after three taps on +.
        sh("flutter create counter_reset", base)
        reset = base / "counter_reset"
        main_reset = fill(edit((reset / "lib" / "main.dart").read_text(), RESET), words)
        write(reset, {"lib/main.dart": main_reset, "test/widget_test.dart": fill(RESET_TEST, words)})
        sh("dart format .", reset)
        s = Session(reset)
        s.note(fill("{w_s_test_reset}", words))
        s.run("flutter test")
        s.save(out / "projects" / "counter-reset.sh")
        sh("flutter build web --no-web-resources-cdn", reset)
        shot(reset / "build" / "web", out / "shots" / "counter-reset.png", "350,740 350,740 350,740")
        write(out / "projects" / "counter_reset", {"lib/main.dart": (reset / "lib" / "main.dart").read_text(),
                                                   "test/widget_test.dart": (reset / "test" / "widget_test.dart").read_text()})
        print("wrote", out)


if __name__ == "__main__":
    main()
