"""Writes the chapter 3 examples in English and Arabic. Run: python3 make.py

Terminal sessions (.sh) are shown, not run: they depend on the reader's computer.
"""
from pathlib import Path

HERE = Path(__file__).parent

FILES = {
    "check.js": ('''console.log("{ok}");
console.log(`2 + 2 = ${2 + 2}`);
''', {"en": {"ok": "Node.js is working!"}, "ar": {"ok": "Node.js يعمل!"}}),
    "versions.sh": ('''$ node --version
v22.12.0
$ npm --version
10.9.0
''', {"en": {}, "ar": {}}),
    "first-project.sh": ('''# {c1}
$ mkdir code-from-zero
$ cd code-from-zero
$ code .
''', {"en": {"c1": "Make a folder for the book, go into it, and open it in VS Code"},
      "ar": {"c1": "أنشئ مجلداً للكتاب، وادخل إليه، وافتحه في VS Code"}}),
    "run.sh": ('''$ node check.js
{ok}
2 + 2 = 4
''', {"en": {"ok": "Node.js is working!"}, "ar": {"ok": "Node.js يعمل!"}}),
    "navigate.sh": ('''$ pwd
/Users/sara
$ ls
Desktop    Documents    Downloads    code-from-zero
$ cd code-from-zero
$ pwd
/Users/sara/code-from-zero
$ cd ..
''', {"en": {}, "ar": {}}),
    "settings.json": ('''{
  "editor.fontSize": 16,
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "files.autoSave": "onFocusChange",
  "editor.wordWrap": "on"
}
''', {"en": {}, "ar": {}}),
}

for name, (tpl, langs) in FILES.items():
    for lang, vals in langs.items():
        s = tpl
        for k, v in vals.items():
            s = s.replace("{" + k + "}", v)
        (HERE / lang).mkdir(exist_ok=True)
        (HERE / lang / name).write_text(s)
print("ok")
