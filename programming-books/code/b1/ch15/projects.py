"""Writes chapter 15's practice projects as real Git sessions, in English and Arabic.
Run: python3 projects.py   (the files go to en/projects/ and ar/projects/)

Names and dates are fixed, so the commit ids are the same on every build.
"""
import os
import shutil
import subprocess
import tempfile
from pathlib import Path

HERE = Path(__file__).parent

BASE_ENV = dict(os.environ, GIT_AUTHOR_NAME="Sara Khan", GIT_AUTHOR_EMAIL="sara@example.com",
                GIT_COMMITTER_NAME="Sara Khan", GIT_COMMITTER_EMAIL="sara@example.com",
                GIT_CONFIG_GLOBAL="/dev/null", GIT_CONFIG_SYSTEM="/dev/null", HOME="/tmp",
                GIT_CONFIG_COUNT="2", GIT_CONFIG_KEY_0="init.defaultBranch", GIT_CONFIG_VALUE_0="main",
                GIT_CONFIG_KEY_1="advice.mergeConflict", GIT_CONFIG_VALUE_1="false")


class Session:
    """Runs commands in a repository and records them as a terminal transcript."""

    def __init__(self, repo, day):
        self.repo, self.day, self.tick, self.lines = repo, day, 0, []

    def note(self, text):
        self.lines.append(f"# {text}")

    def edit(self, path, text, comment=None):
        if comment:
            self.note(comment)
        (self.repo / path).write_text(text + "\n")

    def run(self, cmd, comment=None):
        if comment:
            self.note(comment)
        self.tick += 1
        env = dict(BASE_ENV)
        env["GIT_AUTHOR_DATE"] = env["GIT_COMMITTER_DATE"] = f"2026-03-{self.day:02d}T10:{self.tick:02d}:00+02:00"
        r = subprocess.run(cmd, shell=True, cwd=self.repo, capture_output=True, text=True, env=env)
        text = (r.stdout + r.stderr).rstrip()
        text = "\n".join(l for l in text.splitlines() if not l.startswith("hint:") and not l.startswith(" Date:"))
        self.lines.append(f"$ {cmd}")
        if text:
            self.lines.append(text)

    def text(self):
        return "\n".join(self.lines).replace(str(self.repo), "/Users/sara/code/journal") + "\n"


T = {
    "en": dict(
        j1="# My learning journal", j2="Day 1: I wrote my first HTML page.", j3="Day 2: CSS colours and the box model.",
        c1="Start the journal", c2="Day 1", c3="Day 2",
        n_init="A new folder for your journal", n_log="Three snapshots, newest first", n_show="What exactly changed in the last commit?",
        u_bad="Day 3: I deleted everything by mistake", u_good="Day 3: functions and return values.",
        u_c3="Day 3", u_c4="Add a random quote", u_quote="Quote: copy-paste from the internet, unchecked",
        n_oops="Oops: an edit you did not mean to make", n_restore="Throw away the change in this file",
        n_commit_bad="A commit you regret, already saved", n_revert="Undo it with a new commit, keeping the history honest",
        m_title="Title: Learning journal", m_a="Title: Sara’s learning journal", m_b="Title: My road to senior",
        c_a="Personal title", c_b="Ambitious title", c_fix="Choose the final title",
        n_branch="Two branches change the same line", n_merge="Merging the second one causes a conflict",
        n_look="Git marks both versions inside the file", n_resolve="Keep the line you want, delete the markers, then:",
        m_final="Title: Sara’s road to senior",
        e1="Create journal.md with a heading, then:", e2="Add the Day 1 line, then:", e3="Add the Day 2 line, then:",
        e4="Now write Day 3 properly, then:", e5="Add a title line at the top, then:",
        e6="Change the title on this branch, then:", e7="Change the same line differently here, then:", c_t="Add a title",
    ),
    "ar": dict(
        j1="# دفتر تعلّمي", j2="اليوم 1: كتبت أول صفحة HTML.", j3="اليوم 2: ألوان CSS ونموذج الصندوق.",
        c1="بداية الدفتر", c2="اليوم 1", c3="اليوم 2",
        n_init="مجلد جديد لدفترك", n_log="ثلاث لقطات، الأحدث أولاً", n_show="ما الذي تغيّر بالضبط في آخر commit؟",
        u_bad="اليوم 3: حذفت كل شيء بالخطأ", u_good="اليوم 3: الدوال والقيم المرجعة.",
        u_c3="اليوم 3", u_c4="إضافة اقتباس عشوائي", u_quote="اقتباس: منسوخ من الإنترنت دون تحقق",
        n_oops="عذراً: تعديل لم تقصده", n_restore="تخلّص من التغيير في هذا الملف",
        n_commit_bad="commit تندم عليه، وقد حُفظ", n_revert="ألغِه بـ commit جديد، فيبقى التاريخ صادقاً",
        m_title="العنوان: دفتر التعلم", m_a="العنوان: دفتر تعلّم سارة", m_b="العنوان: طريقي إلى الاحتراف",
        c_a="عنوان شخصي", c_b="عنوان طموح", c_fix="اختيار العنوان النهائي",
        n_branch="فرعان يغيّران السطر نفسه", n_merge="دمج الثاني يسبب تعارضاً",
        n_look="Git يضع النسختين داخل الملف", n_resolve="أبقِ السطر الذي تريده، واحذف العلامات، ثم:",
        m_final="العنوان: طريق سارة إلى الاحتراف",
        e1="أنشئ journal.md بعنوان، ثم:", e2="أضف سطر اليوم 1، ثم:", e3="أضف سطر اليوم 2، ثم:",
        e4="الآن اكتب اليوم 3 كما يجب، ثم:", e5="أضف سطر عنوان في الأعلى، ثم:",
        e6="غيّر العنوان في هذا الفرع، ثم:", e7="غيّر السطر نفسه بشكل آخر هنا، ثم:", c_t="إضافة عنوان",
    ),
}


def make(lang):
    t = T[lang]
    out = HERE / lang / "projects"
    out.mkdir(parents=True, exist_ok=True)
    work = Path(tempfile.mkdtemp())

    # 15.1 a journal with three commits
    repo = work / "journal"
    repo.mkdir()
    s = Session(repo, 2)
    s.run("git init", t["n_init"])
    s.edit("journal.md", t["j1"], t["e1"])
    s.run("git add journal.md")
    s.run(f'git commit -q -m "{t["c1"]}"')
    s.edit("journal.md", f'{t["j1"]}\n\n{t["j2"]}', t["e2"])
    s.run(f'git commit -q -am "{t["c2"]}"')
    s.edit("journal.md", f'{t["j1"]}\n\n{t["j2"]}\n{t["j3"]}', t["e3"])
    s.run(f'git commit -q -am "{t["c3"]}"')
    s.run("git log --oneline", t["n_log"])
    s.run("git show --stat --format=%s HEAD", t["n_show"])
    (out / "journal.sh").write_text(s.text())

    # 15.2 undo: restore an edit, revert a commit
    s = Session(repo, 3)
    base = f'{t["j1"]}\n\n{t["j2"]}\n{t["j3"]}'
    s.edit("journal.md", t["u_bad"], t["n_oops"])
    s.run("git status --short")
    s.run("git restore journal.md", t["n_restore"])
    s.run("git status --short")
    s.edit("journal.md", f'{base}\n{t["u_good"]}', t["e4"])
    s.run(f'git commit -q -am "{t["u_c3"]}"')
    s.edit("quote.md", t["u_quote"], t["n_commit_bad"])
    s.run("git add quote.md")
    s.run(f'git commit -q -m "{t["u_c4"]}"')
    s.run("git revert --no-edit HEAD", t["n_revert"])
    s.run("git log --oneline")
    (out / "undo.sh").write_text(s.text())

    # 15.3 a merge conflict and its resolution
    s = Session(repo, 4)
    body = f'{base}\n{t["u_good"]}'
    s.edit("journal.md", f'{t["m_title"]}\n\n{body}', t["e5"])
    s.run(f'git commit -q -am "{t["c_t"]}"')
    s.run("git switch -q -c personal", t["n_branch"])
    s.edit("journal.md", f'{t["m_a"]}\n\n{body}', t["e6"])
    s.run(f'git commit -q -am "{t["c_a"]}"')
    s.run("git switch -q main")
    s.run("git switch -q -c ambitious")
    s.edit("journal.md", f'{t["m_b"]}\n\n{body}', t["e7"])
    s.run(f'git commit -q -am "{t["c_b"]}"')
    s.run("git switch -q main")
    s.run("git merge personal")
    s.run("git merge ambitious", t["n_merge"])
    s.run("head -5 journal.md", t["n_look"])
    s.edit("journal.md", f'{t["m_final"]}\n\n{body}', t["n_resolve"])
    s.run("git add journal.md")
    s.run(f'git commit -q -m "{t["c_fix"]}"')
    s.run("git log --oneline --graph -4")
    (out / "conflict.sh").write_text(s.text())

    shutil.rmtree(work)


for lang in T:
    make(lang)
print("ok")
