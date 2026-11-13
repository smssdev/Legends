"""[Sprint 63 G9] The mascot's state pictures (brand/states/*.png, from states.cjs) for the app: WebP, 192 px high
(twice the 96 they show at), into mobile/assets/states.

    python3 tools/brand/states.py
"""

import pathlib

from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / 'mobile' / 'assets' / 'states'
OUT.mkdir(parents=True, exist_ok=True)
for f in sorted((ROOT / 'brand' / 'states').glob('*.png')):
    im = Image.open(f).convert('RGBA')
    im = im.crop(im.getbbox())
    h = 192
    im = im.resize((round(im.width * h / im.height), h), Image.LANCZOS)
    target = OUT / f'{f.stem}.webp'
    im.save(target, 'WEBP', quality=85, alpha_quality=90, method=6)
    print(f'{target.name}: {im.width}x{h}, {target.stat().st_size // 1024} KB')
