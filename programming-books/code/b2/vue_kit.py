"""Helpers for the Vue chapters of Book 2 (the twin of react_kit.py).

  page(dir, name, lang, title, css)   writes name.html, which loads name.js with the shared Vue
                                     from /vendor through an import map (see vendor/make-vue.mjs)
  browser(ts, js)                    bundles one example for the browser, compiling its .vue files
  node(ts, mjs)                      bundles one example for Node, so the book can run it and show what
                                     it prints (for example the HTML that renderToString makes)

Everything is real: the listings in the book are the .vue and .ts files, and the screenshots and outputs
come from running them.
"""
import subprocess
from pathlib import Path

import react_kit

ROOT = Path(__file__).parent
BUNDLE = ROOT / "vue" / "bundle.mjs"

IMPORT_MAP = """    <script type="importmap">
      {
        "imports": {
          "vue": "/vendor/vue.js",
          "vue-router": "/vendor/vue-router.js",
          "pinia": "/vendor/pinia.js",
          "@tanstack/vue-query": "/vendor/vue-query.js",
          "vee-validate": "/vendor/vee-validate.js",
          "@vueuse/core": "/vendor/vueuse.js",
          "zod": "/vendor/zod.js"
        }
      }
    </script>"""

fill = react_kit.fill


def page(folder, name, lang, title, css=""):
    folder = Path(folder)
    folder.mkdir(parents=True, exist_ok=True)
    attrs = 'lang="ar" dir="rtl"' if lang == "ar" else 'lang="en"'
    (folder / f"{name}.html").write_text(f"""<!doctype html>
<html {attrs}>
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{title}</title>
{IMPORT_MAP}
    <style>
{react_kit.BASE_CSS}{css}    </style>
  </head>
  <body>
    <div id="app"></div>
    <script type="module" src="./{name}.js"></script>
  </body>
</html>
""")


def _bundle(entry, out, target):
    r = subprocess.run(["node", str(BUNDLE), str(entry), str(out), target], capture_output=True, text=True, cwd=ROOT)
    if r.returncode:
        raise SystemExit(f"{entry}:\n{r.stdout}{r.stderr}")


def browser(ts, js):
    _bundle(ts, js, "browser")


def node(ts, mjs):
    _bundle(ts, mjs, "node")


def generate(here, langs, plain=None, node_files=None, browser_files=None, title_key="w_title"):
    """Writes every example of a chapter for each language. plain: name -> source (.vue files and
    helpers, written as is); node_files: name -> source (also bundled to .mjs for the book to run);
    browser_files: name -> (source, css) (also bundled, with an .html page for screenshots)."""
    here = Path(here)
    for lang, words in langs.items():
        out = here / lang
        for name, src in (plain or {}).items():
            path = out / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(fill(src, words))
        for name, src in (node_files or {}).items():
            path = out / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(fill(src, words))
        for name, (src, css) in (browser_files or {}).items():
            path = out / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(fill(src, words))
        # Bundled after every file is written, since an entry may import any of them
        for name in node_files or {}:
            node(out / name, (out / name).with_suffix(".mjs"))
        for name in browser_files or {}:
            path = out / name
            browser(path, path.with_suffix(".js"))
            page(path.parent, path.stem, lang, words.get(title_key, path.stem), (browser_files or {})[name][1])
        print("ok", lang)
