"""Finds the page of every chapter in each rendered PDF, for the page numbers in the contents.

  python3 toc.py   -> out/<book>-<lang>-<edition>.pages.json

It reads the PDF's bookmarks (made from the headings) and matches each chapter title, so the
numbers are exact. build.py puts them into the contents; a second render prints them.
"""
import json
import re
from pathlib import Path

from pypdf import PdfReader

from build import ROOT, SERIES, TEXT, OUT


def key(title):
    """Bookmark titles lose line-break spaces, and in Arabic the bidi algorithm may reorder words
    and punctuation, so titles are compared as the sorted letters and digits they contain."""
    return "".join(sorted(re.sub(r"\W", "", title)))


def flatten(outline, reader, found):
    for item in outline:
        if isinstance(item, list):
            flatten(item, reader, found)
        else:
            title = key(item.title)
            found.setdefault(title, reader.get_destination_page_number(item) + 1)
    return found


def main():
    for book in SERIES["books"]:
        for lang in ("en", "ar"):
            for edition in ("color", "print"):
                pdf = OUT / f"{book['id']}-{lang}-{edition}.pdf"
                if not pdf.exists():
                    continue
                reader = PdfReader(str(pdf))
                found = flatten(reader.outline, reader, {})
                wanted = {"preface": TEXT[lang]["preface"], "answers": TEXT[lang]["answers"]}
                k = 0
                for part in book["parts"]:
                    for ch in part["chapters"]:
                        k += 1
                        wanted[f"ch{k:02d}"] = ch[lang]
                pages = {name: found[key(title)] for name, title in wanted.items() if key(title) in found}
                (OUT / f"{book['id']}-{lang}-{edition}.pages.json").write_text(json.dumps(pages, indent=1))
                print(pdf.name, f"{len(pages)} of {len(wanted)} found")


if __name__ == "__main__":
    main()
