"""Helpers for the React chapters of Book 2.

  page(dir, name, lang, title, css)   writes name.html, which loads name.js with the shared React
                                     from /vendor through an import map (see vendor/make.mjs)
  browser(tsx, js)                   bundles one example for the browser, React left outside
  node(tsx, mjs)                     bundles one example for Node, so the book can run it and show
                                     what it prints (for example the HTML a component renders)

Everything is real: the listings in the book are the .tsx files, and the screenshots and outputs
come from running them.
"""
import subprocess
from pathlib import Path

ROOT = Path(__file__).parent
ESBUILD = ROOT / "node_modules" / ".bin" / "esbuild"
REACT = ["react", "react-dom", "react-dom/client", "react/jsx-runtime"]

IMPORT_MAP = """    <script type="importmap">
      {
        "imports": {
          "react": "/vendor/react.js",
          "react-dom": "/vendor/react-dom.js",
          "react-dom/client": "/vendor/react-dom-client.js",
          "react/jsx-runtime": "/vendor/jsx-runtime.js"
        }
      }
    </script>"""

BASE_CSS = """*, *::before, *::after { box-sizing: border-box; }
body { margin: 0; padding: 20px; font-family: system-ui, "Segoe UI", Tahoma, sans-serif; color: #1e1b2e; background: #f5f5fb; line-height: 1.5; }
h1, h2, h3 { color: #4338ca; margin: 0 0 8px; }
button { font: inherit; cursor: pointer; border: 0; border-radius: 999px; padding: 6px 16px; background: #4338ca; color: white; }
button.secondary { background: #e0e7ff; color: #312e81; }
:focus-visible { outline: 3px solid #db2777; outline-offset: 2px; }
"""


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
{BASE_CSS}{css}    </style>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="./{name}.js"></script>
  </body>
</html>
""")


def _esbuild(args):
    r = subprocess.run([str(ESBUILD), *args, "--log-level=warning"], capture_output=True, text=True)
    if r.returncode:
        raise SystemExit(r.stderr)


def browser(tsx, js):
    _esbuild([str(tsx), "--bundle", "--format=esm", "--jsx=automatic", f"--outfile={js}",
              *[f"--external:{p}" for p in REACT]])


def node(tsx, mjs):
    _esbuild([str(tsx), "--bundle", "--format=esm", "--platform=node", "--jsx=automatic",
              "--packages=external", f"--outfile={mjs}"])
