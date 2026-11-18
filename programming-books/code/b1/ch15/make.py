"""Writes the chapter 15 terminal sessions by running real Git commands in a temporary folder.
Run: python3 make.py

Dates and names are fixed so the commit ids in the book are the same on every build.
The sessions are shown in the book, not run during the build.
"""
import os
import shutil
import subprocess
import tempfile
from pathlib import Path

HERE = Path(__file__).parent

ENV = dict(os.environ, GIT_AUTHOR_NAME="Sara Khan", GIT_AUTHOR_EMAIL="sara@example.com",
           GIT_COMMITTER_NAME="Sara Khan", GIT_COMMITTER_EMAIL="sara@example.com",
           GIT_AUTHOR_DATE="2026-03-01T10:00:00+02:00", GIT_COMMITTER_DATE="2026-03-01T10:00:00+02:00",
           GIT_CONFIG_GLOBAL="/dev/null", GIT_CONFIG_SYSTEM="/dev/null", HOME="/tmp",
           GIT_CONFIG_COUNT="1", GIT_CONFIG_KEY_0="init.defaultBranch", GIT_CONFIG_VALUE_0="main")

TEXT = {
    "en": {"h1": "Sara Khan", "about": "Beginner web developer", "about2": "Beginner web developer from Alexandria",
           "c_first": "Add profile page", "c_tag": "Add tagline", "c_contact": "Add contact section",
           "contact": "<section id=\"contact\">Write to me</section>"},
    "ar": {"h1": "سارة خان", "about": "مطورة ويب مبتدئة", "about2": "مطورة ويب مبتدئة من الإسكندرية",
           "c_first": "إضافة الصفحة التعريفية", "c_tag": "إضافة الوصف", "c_contact": "إضافة قسم التواصل",
           "contact": "<section id=\"contact\">راسلني</section>"},
}


def session(steps, cwd, date_step):
    """Runs each command and returns a transcript: '$ command' followed by its output."""
    out = []
    for i, (cmd, comment) in enumerate(steps):
        if comment:
            out.append(f"# {comment}")
        if cmd.startswith("!"):  # a file change made by the reader in the editor, not a command
            path, text = cmd[1:].split("=", 1)
            (cwd / path).write_text(text + "\n")
            continue
        env = dict(ENV)
        stamp = f"2026-03-01T1{date_step + i % 9}:00:00+02:00"
        env["GIT_AUTHOR_DATE"] = env["GIT_COMMITTER_DATE"] = stamp
        r = subprocess.run(cmd, shell=True, cwd=cwd, capture_output=True, text=True, env=env)
        out.append(f"$ {cmd}")
        text = (r.stdout + r.stderr).rstrip()
        text = "\n".join(l for l in text.splitlines() if "hint:" not in l)
        if text:
            out.append(text)
    return "\n".join(out) + "\n"


def make(lang):
    t = TEXT[lang]
    en = lang == "en"
    d = HERE / lang
    d.mkdir(exist_ok=True)
    work = Path(tempfile.mkdtemp())
    repo = work / "profile"
    repo.mkdir()
    (repo / "index.html").write_text(f"<h1>{t['h1']}</h1>\n")
    (repo / "style.css").write_text("h1 { color: #4338ca; }\n")

    (d / "config.sh").write_text(
        f"# {'Tell Git who you are (once per computer)' if en else 'عرّف Git بنفسك (مرة واحدة لكل حاسوب)'}\n"
        '$ git config --global user.name "Sara Khan"\n'
        '$ git config --global user.email "sara@example.com"\n'
        "$ git config --global init.defaultBranch main\n")

    (d / "first-commit.sh").write_text(session([
        ("git init", "Start tracking this folder" if en else "ابدأ تتبّع هذا المجلد"),
        ("git status --short", None),
        ("git add index.html style.css", "Choose what goes into the next snapshot" if en else "اختر ما يدخل اللقطة التالية"),
        ("git status --short", None),
        (f'git commit -m "{t["c_first"]}"', "Save the snapshot with a message" if en else "احفظ اللقطة مع رسالة"),
    ], repo, 0).replace(str(repo), "/Users/sara/code-from-zero/profile"))

    (d / "history.sh").write_text(session([
        (f"!index.html=<h1>{t['h1']}</h1>\n<p>{t['about']}</p>", "Edit index.html in VS Code, then:" if en else "عدّل index.html في VS Code، ثم:"),
        ("git diff", "What changed since the last commit?" if en else "ما الذي تغيّر منذ آخر commit؟"),
        (f'git commit -am "{t["c_tag"]}"', None),
        ("git log --oneline", "The history, newest first" if en else "التاريخ، الأحدث أولاً"),
    ], repo, 1))

    (d / "branch.sh").write_text(session([
        ("git switch -c contact", "A new branch for a new feature" if en else "فرع جديد لميزة جديدة"),
        (f"!contact.html={t['contact']}", "Create contact.html, then:" if en else "أنشئ contact.html، ثم:"),
        ("git add contact.html", None),
        (f'git commit -m "{t["c_contact"]}"', None),
        ("git switch main", "Back to the main branch: contact.html disappears from the folder" if en else "العودة إلى الفرع الرئيسي: يختفي contact.html من المجلد"),
        ("git merge contact", "Bring the feature in" if en else "ادمج الميزة"),
        ("git log --oneline --graph", None),
    ], repo, 3))

    (d / "github.sh").write_text(
        f"# {'Connect the folder to an empty repository you created on github.com' if en else 'اربط المجلد بمستودع فارغ أنشأته على github.com'}\n"
        "$ git remote add origin https://github.com/sara-khan/profile.git\n"
        "$ git push -u origin main\n"
        "Enumerating objects: 11, done.\n"
        "Writing objects: 100% (11/11), 1.02 KiB | 1.02 MiB/s, done.\n"
        "To https://github.com/sara-khan/profile.git\n"
        " * [new branch]      main -> main\n"
        "branch 'main' set up to track 'origin/main'.\n"
        f"# {'Later, on any computer:' if en else 'لاحقاً، على أي حاسوب:'}\n"
        "$ git clone https://github.com/sara-khan/profile.git\n"
        "$ git pull\n")

    (d / ".gitignore-example.txt").write_text(
        f"# {'Files Git should never track' if en else 'ملفات لا يتتبعها Git أبداً'}\n"
        "node_modules/\n.env\n.DS_Store\n*.log\n")
    shutil.rmtree(work)


for lang in TEXT:
    make(lang)
print("ok")
