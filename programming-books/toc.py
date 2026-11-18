"""Finds the page of every chapter in each rendered PDF, for the page numbers in the contents.

  python3 toc.py   -> out/<book>-<lang>-<edition>.pages.json

It reads the PDF's bookmarks (made from the headings) and matches each chapter title, so the
numbers are exact. build.py puts them into the contents; a second render prints them.
"""
import json
from pathlib import Path

from pypdf import PdfReader

from build import ROOT, SERIES, TEXT, OUT


def flatten(outline, reader, found):
    for item in outline:
        if isinstance(item, list):
            flatten(item, reader, found)
        else:
            title = "".join(item.title.split())
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
                pages = {key: found["".join(title.split())] for key, title in wanted.items()
                         if "".join(title.split()) in found}
                (OUT / f"{book['id']}-{lang}-{edition}.pages.json").write_text(json.dumps(pages, indent=1))
                print(pdf.name, f"{len(pages)} of {len(wanted)} found")


if __name__ == "__main__":
    main()
