"""Sprint 06 (owner, 2026-11-05: "a real ball, not a robot's"): the Legends ball's texture for Unity's round sphere.

  python tools/unity/art/ball_texture.py

The classic ball's 32 panels (12 pentagons, 20 hexagons: the truncated icosahedron, as tools/unity/art/ball.py),
drawn on the sphere itself so its outline stays perfectly round: each texel belongs to the panel whose centre is
nearest (the 12 corners of an icosahedron and its 20 faces' centres), with a thin dark seam where two panels meet
and the stitching a little shaded. Written as an equirectangular map (u the longitude, v the latitude), which is how
Unity's sphere is unwrapped, to unity/Assets/Legends/Art/Ball/ball_panels.png. Our own colours: ivory hexagons,
navy pentagons.
"""
import os

import numpy as np
from PIL import Image

OUT = os.path.join(os.path.dirname(__file__), '..', '..', '..', 'unity', 'Assets', 'Legends', 'Art', 'Ball', 'ball_panels.png')
W, H = 2048, 1024
IVORY = np.array([0.96, 0.95, 0.92])
NAVY = np.array([0.07, 0.12, 0.24])
SEAM = np.array([0.16, 0.16, 0.17])


def centres():
    """The 12 pentagons' centres (an icosahedron's corners) and the 20 hexagons' (its faces' centres), unit length."""
    t = (1 + 5 ** 0.5) / 2
    ico = []
    for a in (-1, 1):
        for b in (-t, t):
            ico += [(0, a, b), (a, b, 0), (b, 0, a)]
    ico = np.array(ico, dtype=np.float64)
    ico /= np.linalg.norm(ico, axis=1, keepdims=True)
    edge = np.min([np.linalg.norm(ico[0] - p) for p in ico[1:]])
    faces = []
    n = len(ico)
    for i in range(n):
        for j in range(i + 1, n):
            for k in range(j + 1, n):
                if all(abs(np.linalg.norm(ico[x] - ico[y]) - edge) < 1e-6 for x, y in ((i, j), (j, k), (i, k))):
                    c = ico[i] + ico[j] + ico[k]
                    faces.append(c / np.linalg.norm(c))
    assert len(faces) == 20
    return ico, np.array(faces)


def main():
    pents, hexes = centres()
    allc = np.vstack([pents, hexes])
    u = (np.arange(W) + 0.5) / W
    v = (np.arange(H) + 0.5) / H
    lon, lat = np.meshgrid(u * 2 * np.pi, (v - 0.5) * np.pi)
    d = np.stack([np.cos(lat) * np.cos(lon), np.sin(lat), np.cos(lat) * np.sin(lon)], axis=-1)
    dots = d @ allc.T                                  # cosine to every panel centre
    order = np.argsort(-dots, axis=-1)
    first = np.take_along_axis(dots, order[..., :1], -1)[..., 0]
    second = np.take_along_axis(dots, order[..., 1:2], -1)[..., 0]
    angle = np.arccos(np.clip(second, -1, 1)) - np.arccos(np.clip(first, -1, 1))   # 0 on a seam
    pent = order[..., 0] < len(pents)
    colour = np.where(pent[..., None], NAVY, IVORY)
    seam_w, shade_w = 0.010, 0.045                     # radians: the seam, and the stitching's soft shade beside it
    shade = np.clip(angle / shade_w, 0, 1) ** 0.5
    colour = colour * (0.82 + 0.18 * shade[..., None])
    s = np.clip((angle - seam_w) / 0.004, 0, 1)[..., None]
    colour = SEAM * (1 - s) + colour * s
    img = (np.clip(colour, 0, 1) ** (1 / 1.0) * 255).astype(np.uint8)
    # row 0 of a PNG is its top: v = 1 in Unity
    Image.fromarray(img[::-1]).save(OUT, optimize=True)
    print('Legends: wrote', os.path.normpath(OUT), os.path.getsize(OUT) // 1024, 'KB')


if __name__ == '__main__':
    main()
