"""Crowd textures for the Unity stands, cut from our stadium plates: python3 tools/unity/crowd_textures.py

The stadium plates (unity/Reference/stadiums/) cannot be the 3D stadium itself: each is one fixed camera.
Their crowd, though, is photographic and ours, so its two tiers are cut out here and made to tile
sideways: the 3D stands (ArenaBuilder.cs) wrap them round the bowl, where the camera only sees them from afar.

Writes unity/Assets/Legends/Stadiums/<stadium>/Textures/crowd-upper.png and crowd-lower.png (2048x256),
and boards.png: the LED ribbon colours between the tiers.
"""
import os
from PIL import Image, ImageFilter

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
REF = os.path.join(ROOT, 'unity', 'Reference', 'stadiums')
OUT = os.path.join(ROOT, 'unity', 'Assets', 'Legends', 'Stadiums')

# (stadium, plate, upper tier, lower tier, LED ribbon): each (left, top, right, bottom) as fractions of the
# plate, measured on it: the camera at the halfway line, the far stand across the whole width. The lower tier
# starts right of the players' tunnel.
BANDS = {
    'Arena': ('arena/night/centre.jpg', (0, 0.335, 1, 0.42), (0.2, 0.46, 1, 0.545), (0, 0.425, 1, 0.445)),
}
SIZE = (2048, 256)
SEAM = 160   # pixels blended across the wrap so the band tiles without a visible edge


def band(img, left, top, right, bottom):
    w, h = img.size
    return img.crop((int(left * w), int(top * h), int(right * w), int(bottom * h)))


def tileable(strip):
    """Stretch the strip to SIZE and cross-fade its right end into its left, so it repeats seamlessly."""
    strip = strip.resize((SIZE[0] + SEAM, SIZE[1]), Image.LANCZOS)
    body = strip.crop((0, 0, SIZE[0], SIZE[1]))
    tail = strip.crop((SIZE[0], 0, SIZE[0] + SEAM, SIZE[1]))
    head = body.crop((0, 0, SEAM, SIZE[1]))
    mask = Image.linear_gradient('L').rotate(-90, expand=True).resize((SEAM, SIZE[1]))   # 255 at the left: the tail
    body.paste(Image.composite(tail, head, mask), (0, 0))
    return body


def main():
    for name, (plate, upper, lower, boards) in BANDS.items():
        img = Image.open(os.path.join(REF, plate)).convert('RGB')
        out = os.path.join(OUT, name, 'Textures')
        os.makedirs(out, exist_ok=True)
        tileable(band(img, *upper)).save(os.path.join(out, 'crowd-upper.png'))
        tileable(band(img, *lower)).save(os.path.join(out, 'crowd-lower.png'))
        band(img, *boards).resize((1024, 16), Image.LANCZOS).filter(ImageFilter.GaussianBlur(1)).save(os.path.join(out, 'boards.png'))
        print(name, '->', os.path.relpath(out, ROOT))


if __name__ == '__main__':
    main()
