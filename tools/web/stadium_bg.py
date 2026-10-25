"""Legends' blurred stadium behind every screen [X32], drawn for the game (no outside image).

    python3 tools/web/stadium_bg.py

Draws the night stadium (stands full of crowd, four floodlights, a striped pitch in perspective) as SVG, renders it
in the bundled Chromium (Playwright), then blurs and darkens it with Pillow into web/public/art/stadium-blur.jpg
(1920x1080) and stadium-blur-m.jpg (phones). Blurred here once, so no phone ever blurs it live.
"""
import os
import random
import subprocess
import tempfile

from PIL import Image, ImageEnhance, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, 'web', 'public', 'art')
W, H = 1920, 1080


def svg() -> str:
    random.seed(7)
    o = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">', '''<defs>
<linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#050c1f"/><stop offset="1" stop-color="#0d2552"/></linearGradient>
<linearGradient id="stand" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#14306a"/><stop offset="1" stop-color="#0b1d44"/></linearGradient>
<linearGradient id="grass" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#1f7a3e"/><stop offset="1" stop-color="#2fae55"/></linearGradient>
<radialGradient id="glow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#fff6d8" stop-opacity="0.95"/><stop offset="0.35" stop-color="#ffe7a0" stop-opacity="0.35"/><stop offset="1" stop-color="#ffe7a0" stop-opacity="0"/></radialGradient>
<radialGradient id="pitchlight" cx="0.5" cy="0.6" r="0.6"><stop offset="0" stop-color="#ffffff" stop-opacity="0.22"/><stop offset="1" stop-color="#ffffff" stop-opacity="0"/></radialGradient>
</defs>''', f'<rect width="{W}" height="{H}" fill="url(#sky)"/>',
         '<path d="M0 260 Q960 150 1920 260 L1920 640 L0 640 Z" fill="url(#stand)"/>']
    cols = ['#2b4f8c', '#3d63a8', '#c9d2e1', '#f5b82e', '#d3122f', '#e8ecf4', '#1e9e4a', '#2f6fdb', '#6b84b8']
    for _ in range(5200):
        x = random.uniform(0, W)
        top = 260 - 110 * (1 - ((x - 960) / 960) ** 2)
        y = random.uniform(top + 8, 630)
        o.append(f'<circle cx="{x:.0f}" cy="{y:.0f}" r="{random.uniform(1.6, 3.2):.1f}" fill="{random.choice(cols)}" opacity="{random.uniform(.35, .85):.2f}"/>')
    o.append('<path d="M0 450 Q960 380 1920 450" stroke="#0a1838" stroke-width="14" fill="none" opacity=".7"/>')
    o.append('<rect x="0" y="628" width="1920" height="34" fill="#0d2a5e"/><rect x="0" y="628" width="1920" height="3" fill="#f5b82e" opacity=".8"/>')
    o += [f'<rect x="{x}" y="636" width="180" height="18" rx="3" fill="#1b4a9a"/>' for x in range(40, 1920, 260)]
    o.append('<path d="M-200 1080 L420 662 L1500 662 L2120 1080 Z" fill="url(#grass)"/>')
    xl = lambda y: 420 - (y - 662) / (1080 - 662) * 620
    xr = lambda y: 1500 + (y - 662) / (1080 - 662) * 620
    for k in range(10):
        y0, y1 = 662 + 418 * (k / 10) ** 1.4, 662 + 418 * ((k + 0.5) / 10) ** 1.4
        o.append(f'<path d="M{xl(y0):.0f} {y0:.0f} L{xr(y0):.0f} {y0:.0f} L{xr(y1):.0f} {y1:.0f} L{xl(y1):.0f} {y1:.0f} Z" fill="#ffffff" opacity=".06"/>')
    o.append('<g stroke="#ffffff" stroke-opacity=".55" stroke-width="3" fill="none"><path d="M330 724 H1590"/><ellipse cx="960" cy="860" rx="190" ry="60"/><path d="M960 724 V1080"/><path d="M700 724 L660 800 H1260 L1220 724"/></g>')
    o.append(f'<rect width="{W}" height="{H}" fill="url(#pitchlight)"/>')
    for cx in [240, 700, 1220, 1680]:
        o.append(f'<circle cx="{cx}" cy="120" r="230" fill="url(#glow)"/><rect x="{cx - 50}" y="100" width="100" height="40" rx="6" fill="#fffbe9" opacity=".9"/>')
    o.append('</svg>')
    return '\n'.join(o)


def main() -> None:
    tmp = tempfile.mkdtemp()
    src, png = os.path.join(tmp, 'stadium.svg'), os.path.join(tmp, 'stadium.png')
    with open(src, 'w') as f:
        f.write(svg())
    js = ("const { chromium } = require('playwright');(async () => { const b = await chromium.launch();"
          f" const p = await b.newPage({{ viewport: {{ width: {W}, height: {H} }} }}); await p.goto('file://{src}');"
          f" await p.waitForTimeout(800); await p.screenshot({{ path: '{png}' }}); await b.close(); }})();")
    subprocess.run(['node', '-e', js], check=True)
    im = ImageEnhance.Brightness(Image.open(png).convert('RGB').filter(ImageFilter.GaussianBlur(9))).enhance(0.72)
    im.save(os.path.join(OUT, 'stadium-blur.jpg'), quality=78, optimize=True, progressive=True)
    im.resize((900, 506)).save(os.path.join(OUT, 'stadium-blur-m.jpg'), quality=75, optimize=True, progressive=True)


if __name__ == '__main__':
    main()
