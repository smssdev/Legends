"""Helpers for Book 5's examples: run Dart and Flutter for real and save what the terminal showed.

  sh(cmd, cwd)            runs a shell command as a reader would (see below) -> (output, exit code)
  Session(cwd)            s.note("comment"); s.run("dart run x.dart", shown=None) -> output; s.save(path)
  fill(text, words)       replaces {w_name} placeholders, and nothing else (Dart is full of braces)
  shot(web_dir, png, ...) serves a Flutter web build and screenshots it at phone size (see snap.cjs)

The tools: Flutter 3.50.1 with its Dart 3.14 in /opt/flutter (or on PATH). Flutter warns when it runs as
root, so when this machine's user is root the commands run as the ordinary user "reader" (create it with
useradd -m reader), with only the settings a reader's terminal has.
"""
import os
import re
import shutil
import subprocess
from pathlib import Path

B5 = Path(__file__).parent
FLUTTER = Path(os.environ.get("FLUTTER_ROOT", "/opt/flutter"))
RUNUSER = shutil.which("runuser")
AS_READER = os.geteuid() == 0 and RUNUSER and Path("/home/reader").exists()
HOME = Path("/home/reader") if AS_READER else Path.home()
WORK = HOME / "b5-work"  # projects are created here, outside the repository, as a reader would


def env():
    e = {"HOME": str(HOME), "USER": HOME.name, "LANG": "C.UTF-8", "TERM": "dumb", "CI": "1",
         "PATH": f"{FLUTTER}/bin:/usr/local/bin:/usr/bin:/bin", "PUB_CACHE": str(HOME / ".pub-cache")}
    # Downloading packages through this machine's proxy, if it has one: never shown in a transcript.
    for k in ("HTTPS_PROXY", "https_proxy"):
        if os.environ.get(k):
            e[k] = os.environ[k]
    e["NO_PROXY"] = "localhost,127.0.0.1"
    cert = Path("/opt/ca-bundle.crt")
    if os.environ.get("SSL_CERT_FILE"):
        if AS_READER and not cert.exists():
            shutil.copy(os.environ["SSL_CERT_FILE"], cert)
            cert.chmod(0o644)
        e["SSL_CERT_FILE"] = str(cert) if AS_READER else os.environ["SSL_CERT_FILE"]
    return e


def wrap(cmd):
    return [RUNUSER, "-u", "reader", "--", "bash", "-c", cmd] if AS_READER else ["bash", "-c", cmd]


def popen(cmd, cwd, **kw):
    return subprocess.Popen(wrap(cmd), cwd=cwd, env=env(), **kw)


def clean(out, cwd):
    out = out.replace("\r", "")
    out = re.sub(r"\x1b\[[0-9;?]*[A-Za-z]", "", out)  # no terminal colours in a book
    out = out.replace(str(cwd) + "/", "").replace(str(WORK) + "/", "").replace(str(HOME), "~")
    return out.rstrip("\n")


def sh(cmd, cwd, timeout=900):
    Path(cwd).mkdir(parents=True, exist_ok=True)
    if AS_READER:
        subprocess.run(["chown", "-R", "reader:reader", str(WORK)], check=False)
    r = subprocess.run(wrap(cmd), cwd=cwd, env=env(), capture_output=True, text=True, timeout=timeout)
    return clean(r.stdout + r.stderr, cwd), r.returncode


def fill(text, words):
    return re.sub(r"\{(w_\w+)\}", lambda m: words[m.group(1)], text)


class Session:
    def __init__(self, cwd):
        self.cwd, self.lines = Path(cwd), []

    def note(self, text):
        self.lines.append(f"# {text}")

    def run(self, cmd, shown=None, check=True, keep=None):
        """Runs cmd; the transcript shows `shown` (the command as the reader types it) if given.
        keep(lines) -> lines may shorten a long answer; the book says so where it does."""
        out, code = sh(cmd, self.cwd)
        if check and code:
            raise RuntimeError(f"{cmd} failed ({code}):\n{out}")
        self.lines.append("$ " + (shown or cmd))
        lines = out.split("\n") if out else []
        if keep:
            lines = keep(lines)
        self.lines.extend(lines)
        return out

    def add(self, text):
        self.lines.extend(text.rstrip("\n").split("\n"))

    def save(self, path):
        Path(path).parent.mkdir(parents=True, exist_ok=True)
        Path(path).write_text("\n".join(self.lines) + "\n")
        self.lines = []


def write(folder, files):
    for name, text in files.items():
        p = Path(folder) / name
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(text)


def shot(web_dir, png, taps="", wait=5000, query="", size="390x780"):
    """A screenshot of a Flutter web build at phone size (390 x 780, twice the pixels). taps is a list of
    "x,y" points (in the 390 x 780 page) to click first, separated by spaces."""
    subprocess.run(["node", str(B5 / "snap.cjs"), str(web_dir), str(png), taps, str(wait), query, size], check=True)


def dart_examples(here, words_by_lang, sources, errors=(), keep=None):
    """A chapter of single-file Dart examples (Chapters 2 to 4): writes every source in each language,
    formats them with dart format, runs each with `dart run` and saves what it printed as name.sh.
    sources: {path: text, or {lang: text}}. errors: files that show a mistake (a compile or runtime
    error is expected there and refused everywhere else). keep(name, lines) may shorten an output."""
    folder = here.name
    for lang, words in words_by_lang.items():
        out = here / lang
        shutil.rmtree(out, ignore_errors=True)
        work = WORK / folder / lang
        shutil.rmtree(work, ignore_errors=True)
        files = {name: fill(src if isinstance(src, str) else src[lang], words) for name, src in sources.items()}
        write(work, files)
        # Every example is formatted the standard way, as Chapter 1 asks the reader to do.
        text, code = sh("dart format .", work)
        if code:
            raise RuntimeError(text)
        files = {name: (work / name).read_text() for name in files}
        write(out, files)
        for name in files:
            s = Session(work / Path(name).parent)
            s.run(f"dart run {Path(name).name}", check=False)
            failed = any("Error" in l or "Unhandled exception" in l for l in s.lines)
            if failed != (name in errors):
                raise RuntimeError(name + "\n" + "\n".join(s.lines))
            if keep:
                s.lines = keep(name, s.lines)
            s.save(out / name.replace(".dart", ".sh"))
        print("wrote", out)


def flutter_gallery(here, words_by_lang, files, shots=(), tests=(), package="bit_app", assets=None, packages=()):
    """A chapter of small Flutter apps (Chapter 5 on), in each language:
      files   {path: text or {lang: text}}: lib/*.dart are apps (each with its own main), test/*.dart tests,
              projects/<name>.dart and answers/<name>.dart are apps too, kept in those folders here
      shots   [(png name, app path, "x,y taps"[, "WxH"])]: screenshots of release builds, at phone size
              (390x780) unless a size is given
      assets  a folder of files the apps use (images): copied to assets/ in the project, and listed in
              pubspec.yaml, as the chapter shows
      packages  packages to add with `flutter pub add`, recorded as pub-add.sh
      tests   [(transcript name, test path[, keep])]: `flutter test <path>`, recorded; with keep, the test
              is expected to fail and keep(lines) shortens what is printed
    One project per language; the apps are built for the web once, through a generated
    lib/gallery.dart that runs the app named in the address (?app=name). The reader never sees it."""
    folder = here.name
    for lang, words in words_by_lang.items():
        out = here / lang
        shutil.rmtree(out, ignore_errors=True)
        base = WORK / folder / lang
        shutil.rmtree(base, ignore_errors=True)
        base.mkdir(parents=True)
        text, code = sh(f"flutter create --empty {package}", base)
        if code:
            raise RuntimeError(text)
        project = base / package
        if assets:
            shutil.copytree(assets, project / "assets", dirs_exist_ok=True)
            pubspec = project / "pubspec.yaml"
            folders = sorted({str(p.parent.relative_to(project)) + "/" for p in (project / "assets").rglob("*") if p.is_file()})
            text = pubspec.read_text().replace("  uses-material-design: true\n",
                                               "  uses-material-design: true\n  assets:\n" + "".join(f"    - {f}\n" for f in folders))
            pubspec.write_text(text)
            write(out, {"pubspec.yaml": text})
        if packages:
            s = Session(project)
            s.run("flutter pub add " + " ".join(packages))
            s.save(out / "pub-add.sh")
            write(out, {"pubspec.yaml": (project / "pubspec.yaml").read_text()})
        (project / "test").mkdir(exist_ok=True)
        for f in (project / "test").glob("*.dart"):
            f.unlink()
        # projects/ and answers/ apps live in lib/ during the build, under their own names
        placed = {}
        for name, src in files.items():
            src = fill(src if isinstance(src, str) else src[lang], words)
            target = name if name.startswith(("lib/", "test/")) else "lib/" + name.replace("/", "_")
            placed[name] = target
            write(project, {target: src})
        # Apps are the files with a main(); other files in lib/ are code they share (a model, say).
        apps = [t for n, t in placed.items() if t.startswith("lib/") and "void main(" in (project / t).read_text()]
        imports = "\n".join(f"import '{Path(t).name}' as {Path(t).stem};" for t in apps)
        cases = "\n".join(f"    '{Path(t).stem}' => {Path(t).stem}.main," for t in apps)
        write(project, {"lib/gallery.dart": f"""// Generated for the book's screenshots: runs the app named in ?app=.
{imports}

void main() {{
  final app = Uri.base.queryParameters['app'];
  final run = switch (app) {{
{cases}
    _ => throw ArgumentError('no app $app'),
  }};
  run();
}}
"""})
        text, code = sh("dart format . && flutter analyze", project)
        if code:
            raise RuntimeError(text)
        for name, target in placed.items():
            write(out, {name: (project / target).read_text()})
        text, code = sh("flutter build web -t lib/gallery.dart --no-web-resources-cdn", project)
        if code:
            raise RuntimeError(text)
        for png, app, taps, *size in shots:
            # "lib/router.dart#/drinks/3" opens the app at that route
            app, _, route = app.partition("#")
            stem = Path(placed[app]).stem
            query = f"?app={stem}" + (f"#{route}" if route else "")
            shot(project / "build" / "web", out / "shots" / png, fill(taps, words), 6000, query, *size)
        for transcript, test, *fails in tests:
            # (transcript, test) must pass; (transcript, test, keep) is expected to fail, and keep(lines)
            # chooses the lines the book prints.
            s = Session(project)
            s.run(f"flutter test {test}", check=not fails)
            if fails:
                s.lines = fails[0](s.lines)
            s.save(out / transcript)
        print("wrote", out)
