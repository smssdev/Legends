"""[Sprint 63 G8] The site's heavy pictures made light. The coaches' 3D pictures: from the renders (docs/design/legends-ui/characters,
made by tools/unity/art/characters.py in Blender) to web/public/characters, each mood's loop in 6 frames (the
renders have 10), WebP quality 70 with its edges (alpha) at 40, at the renders' size (340x442: the coach-reaction
clip shows them at up to about 230 CSS px wide). The 27 together under 1 MB (they were 3 MB).

    python3 tools/brand/web_images.py
"""

import pathlib

from PIL import Image, ImageSequence

ROOT = pathlib.Path(__file__).resolve().parents[2]
SRC = ROOT / 'docs' / 'design' / 'legends-ui' / 'characters'
OUT = ROOT / 'web' / 'public' / 'characters'
KEEP, QUALITY, ALPHA = 6, 70, 40

total = 0
for f in sorted(SRC.glob('*.webp')):
    im = Image.open(f)
    frames = [x.convert('RGBA') for x in ImageSequence.Iterator(im)]
    n = len(frames)
    pick = [frames[round(i * n / KEEP)] for i in range(min(KEEP, n))]
    loop = im.info.get('duration', 100) * n
    target = OUT / f.name
    pick[0].save(target, 'WEBP', save_all=True, append_images=pick[1:], duration=round(loop / len(pick)), loop=0,
                 quality=QUALITY, alpha_quality=ALPHA, method=6, minimize_size=True, allow_mixed=True)
    total += target.stat().st_size
print(f'characters: {len(list(SRC.glob("*.webp")))} pictures, {total // 1024} KB')

og = ROOT / 'web' / 'public' / 'brand' / 'og-invite.png'
src = ROOT / 'brand' / 'current' / 'og-invite.png'
Image.open(src).convert('RGB').quantize(colors=256, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.FLOYDSTEINBERG).save(
    og, 'PNG', optimize=True)
print(f'og-invite: {og.stat().st_size // 1024} KB')
