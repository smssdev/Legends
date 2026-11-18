"""Writes the module project of this chapter (projects/modules), in English and Arabic.
Run: python3 projects.py   (the book runs projects/modules/app.mjs and shows its output)
"""
import re
from pathlib import Path

HERE = Path(__file__).parent

FILES = {
    "text.mjs": '''export function slugify(title) {
  return title
    .toLowerCase()
    .trim()
    .replace(/[^\\p{L}\\p{N}]+/gu, "-")
    .replace(/^-|-$/g, "");
}

export function truncate(text, max) {
  return text.length <= max ? text : text.slice(0, max - 1).trimEnd() + "…";
}
''',
    "numbers.mjs": '''export function clamp(value, min, max) {
  return Math.min(Math.max(value, min), max);
}

export function percent(part, whole) {
  return whole === 0 ? 0 : Math.round((part / whole) * 100);
}
''',
    "internal.mjs": '''// {c_internal}
export function countWords(text) {
  return text.split(/\\s+/).filter(Boolean).length;
}
''',
    "index.mjs": '''// {c_public}
export { slugify, truncate } from "./text.mjs";
export { clamp, percent } from "./numbers.mjs";
''',
    "app.mjs": '''import { slugify, truncate, clamp, percent } from "./index.mjs";

const title = "{title}";
console.log(slugify(title));
console.log(truncate(title.trim(), 18));
console.log(clamp(140, 0, 100), clamp(-5, 0, 100));
console.log(percent(7, 20) + "%");
''',
}

T = {
    "en": {"c_internal": "Used inside the folder only: index.mjs does not export it",
           "c_public": "The folder's public face: other code imports from here only",
           "title": "  Modern JavaScript in Depth!  "},
    "ar": {"c_internal": "يُستخدم داخل المجلد فقط: لا يصدّره index.mjs",
           "c_public": "واجهة المجلد العامة: الكود الآخر يستورد من هنا فقط",
           "title": "  جافاسكربت الحديثة بعمق!  "},
}

for lang, t in T.items():
    d = HERE / lang / "projects" / "modules"
    d.mkdir(parents=True, exist_ok=True)
    for name, text in FILES.items():
        (d / name).write_text(re.sub(r"(?<!\$)\{(\w+)\}", lambda m: t.get(m.group(1), m.group(0)), text))
print("ok")
