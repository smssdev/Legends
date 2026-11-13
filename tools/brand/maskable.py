"""[Sprint 63 G6] The web app's maskable icon: the emblem (web/public/icon-512.png) at 60% of the side, so a 20% margin
all round keeps it inside any mask a phone cuts (a circle, a squircle, a rounded square), on the icon's own night teal
drawn again to the edges (a radial light from the middle, as the icon has). Writes icon-maskable-512.png and -192.

    python3 tools/brand/maskable.py
"""

import pathlib

from PIL import Image, ImageDraw, ImageFilter

PUBLIC = pathlib.Path(__file__).resolve().parents[2] / 'web' / 'public'
SIZE = 512
LIGHT, DARK = (24, 78, 84), (16, 36, 56)  # the icon's teal at its middle and at its corners

ground = Image.new('RGBA', (SIZE, SIZE))
draw = ImageDraw.Draw(ground)
for r in range(int(SIZE * 0.75), 0, -2):
    t = r / (SIZE * 0.75)
    draw.ellipse([SIZE / 2 - r, SIZE / 2 - r, SIZE / 2 + r, SIZE / 2 + r], fill=tuple(round(a + (b - a) * t) for a, b in zip(LIGHT, DARK)) + (255,))
ground = ground.filter(ImageFilter.GaussianBlur(6))

emblem = Image.open(PUBLIC / 'icon-512.png').convert('RGBA')
side = round(SIZE * 0.6)
small = emblem.resize((side, side), Image.LANCZOS)
# The icon's own ground fades out towards its square's edge, so only the emblem shows on the new ground.
mask = Image.new('L', (side, side), 0)
ImageDraw.Draw(mask).ellipse([side * 0.02, side * 0.02, side * 0.98, side * 0.98], fill=255)
mask = mask.filter(ImageFilter.GaussianBlur(side * 0.04))
ground.paste(small, ((SIZE - side) // 2, (SIZE - side) // 2), mask)

for px in (512, 192):
    ground.resize((px, px), Image.LANCZOS).convert('RGB').save(PUBLIC / f'icon-maskable-{px}.png', optimize=True)
print('maskable: icon-maskable-512.png, icon-maskable-192.png')
