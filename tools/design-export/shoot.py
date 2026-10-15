"""Screenshots the static design pages produced by render.mjs.

Usage: python3 tools/design-export/shoot.py <canvas.json> <html-dir> <png-dir> [fontsource-dir]

If Google Fonts is unreachable (offline or a restricted network), pass the
node_modules/@fontsource directory of an install of @fontsource/alexandria,
@fontsource/ibm-plex-sans-arabic and @fontsource/barlow-condensed; the Google
Fonts stylesheet is then served from those local files.

Fixed artboards are captured at their exact size; pages marked "expand: fill"
are captured at their width with the full scrolling height. Mobile artboards
use a 2x pixel ratio so text stays sharp.
"""
import json
import pathlib
import re
import sys

from playwright.sync_api import sync_playwright

canvas_path, html_dir, png_dir = map(pathlib.Path, sys.argv[1:4])
fontsource = pathlib.Path(sys.argv[4]) if len(sys.argv) > 4 else None
FAMILIES = {"Alexandria": "alexandria", "IBM Plex Sans Arabic": "ibm-plex-sans-arabic", "Barlow Condensed": "barlow-condensed"}


def local_fonts_css(url):
    """Builds the requested Google Fonts CSS from local @fontsource files."""
    css = []
    for fam, weights in re.findall(r"family=([^:&]+):wght@([0-9;]+)", url):
        pkg = FAMILIES.get(fam.replace("+", " "))
        if not pkg:
            continue
        for w in weights.split(";"):
            sheet = fontsource / pkg / f"{w}.css"
            if sheet.exists():
                css.append(re.sub(r"url\(\./files/([^)]+)\)", rf"url(https://fonts.local/{pkg}/\1)", sheet.read_text()))
    return "\n".join(css)


def serve_font(route):
    pkg, name = route.request.url.split("https://fonts.local/")[1].split("/", 1)
    route.fulfill(body=(fontsource / pkg / "files" / name).read_bytes(), content_type="font/woff2",
                  headers={"Access-Control-Allow-Origin": "*"})


boards = json.loads(canvas_path.read_text(encoding="utf-8"))["boards"]
png_dir.mkdir(parents=True, exist_ok=True)

with sync_playwright() as p:
    browser = p.chromium.launch()
    for file, frame in boards.items():
        name = file.removesuffix(".dc.html")
        page_file = html_dir / f"{name}.html"
        if not page_file.exists():
            continue
        is_page = frame.get("expand") == "fill"
        scale = 2 if frame["w"] <= 500 else 1
        page = browser.new_page(viewport={"width": frame["w"], "height": frame["h"]}, device_scale_factor=scale)
        if fontsource:
            page.route("https://fonts.googleapis.com/css2*", lambda r: r.fulfill(body=local_fonts_css(r.request.url), content_type="text/css"))
            page.route("https://fonts.local/**", serve_font)
        page.goto(page_file.resolve().as_uri())
        page.wait_for_load_state("networkidle")
        page.evaluate("document.fonts.ready")
        page.wait_for_timeout(400)
        page.screenshot(path=str(png_dir / f"{name}.png"), full_page=is_page)
        page.close()
        print("shot", name)
    browser.close()
