"""Inserts a chapter's practice projects before its exercises (or replaces them if already there).

  python3 tools_add_projects.py b1 1        reads projects/b1/ch01.en.html and projects/b1/ch01.ar.html

The project sections are kept in their own files under projects/, so they are easy to review,
and this script places them in the chapter source between the summary and the exercises.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).parent
START, END = "<!-- projects -->", "<!-- /projects -->"
ANCHOR = {"en": ("<h2>Exercises</h2>", "<h2>Final exercises</h2>"), "ar": ("<h2>تمارين</h2>", "<h2>تمارين أخيرة</h2>")}


def place(book, number=None):
    # Book 1 numbers its chapters (b1 3 -> ch03); shared chapters are named (b2/js).
    name = f"{book}/ch{number:02d}" if number else book
    for lang in ("en", "ar"):
        part = (ROOT / "projects" / f"{name}.{lang}.html").read_text().strip()
        block = f"{START}\n{part}\n{END}\n\n"
        src = ROOT / "src" / f"{name}.{lang}.html"
        text = src.read_text()
        if START in text:
            text = re.sub(re.escape(START) + r".*?" + re.escape(END) + r"\n\n", lambda m: block, text, flags=re.S)
        else:
            anchor = [a for a in ANCHOR[lang] if text.count(a) == 1]
            assert anchor, (src, "no single exercises heading")
            text = text.replace(anchor[0], block + anchor[0])
        src.write_text(text)
        print("placed", src.relative_to(ROOT))


if __name__ == "__main__":
    place(sys.argv[1], int(sys.argv[2]) if len(sys.argv) > 2 else None)
