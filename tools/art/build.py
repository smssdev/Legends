"""Turn art/raw/ into the game's match art (W14): python3 tools/art/build.py

One command, run from anywhere. Needs Python 3 with Pillow, numpy and scipy
(`pip install pillow numpy scipy`). For every board in art/raw/ it:

1. keys out the flat background (chroma green, magenta, or black for light effects),
   with soft edges and the green spill taken off the figure;
2. cuts the board into exactly the frames its README names ("الإطارات a إلى b من N");
3. marks the white kit in a separate mask, so the game tints it with any club's colours;
4. brings every board to the standard canvas height first (Gemini's 3:2 is 1264x848, but a
   downloaded copy can be 1024x687 or 2528x1696), so a smaller file never makes a smaller player;
5. scales every character by its reference card; in a cycle (run, walk, dribble) a board drawn smaller
   or bigger is brought to the size of the sequence's first board, and every board keeps its own ground
   line (its lowest foot), so a frame in the air stays in the air;
6. packs the frames into atlases at two sizes (hd for computers, sd for phones)
   with a manifest the scene engine reads.

Stadium plates become webp at the same two sizes. Output: web/public/match-art/.
The build is deterministic: the same art/raw/ gives the same files.
"""
import json, os, re, sys
import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))
RAW = os.path.join(ROOT, 'art', 'raw')
OUT = os.path.join(ROOT, 'web', 'public', 'match-art')
SIZES = {'hd': 384, 'sd': 192}         # a standing player's height in pixels at each size
PLATE_W = {'hd': 1376, 'sd': 688}
ATLAS_W = 2048
FPS = 12                              # animation frames a second (MATCH_VIEW 4.7)
BOARD_H = 848                         # the standard board height (3:2 at 1264x848): every board is resized to it
CYCLE = re.compile(r'/(run|walk|sprint|jog|backpedal|dribble)')   # sequences whose figures are the same height on every board
RANGE = re.compile(r'(?:الإطارات )?(\d+) إلى (\d+) من (\d+)')


# ---------------------------------------------------------------- keying
def background(a):
    """The flat background colour: the median of the four image borders."""
    edge = np.concatenate([a[:4].reshape(-1, 3), a[-4:].reshape(-1, 3), a[:, :4].reshape(-1, 3), a[:, -4:].reshape(-1, 3)])
    r, g, b = np.median(edge, axis=0)
    if g > 120 and g > r + 50 and g > b + 50: return 'green'
    if r > 150 and b > 150 and g < 100: return 'magenta'
    if max(r, g, b) < 40: return 'black'
    return 'green'


def key(img):
    """RGBA with the background removed, soft edges and no green spill."""
    a = np.asarray(img.convert('RGB')).astype(np.int32)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    kind = background(a)
    if kind == 'black':                                   # light effects: brightness is the alpha
        alpha = a.max(-1)
        return np.dstack([a, alpha]).astype(np.uint8), kind
    if kind == 'green':
        excess = g - np.maximum(r, b)                     # how much greener than it should be
        fixed = np.where(excess > 0, np.maximum(r, b), g)  # despill: green no higher than red or blue
        rgb = np.dstack([r, fixed, b])
    else:
        excess = np.minimum(r, b) - g
        fixed_r = np.where(excess > 0, np.minimum(r, g + 20), r); fixed_b = np.where(excess > 0, np.minimum(b, g + 20), b)
        rgb = np.dstack([fixed_r, g, fixed_b])
    alpha = np.clip(255 - (excess - 25) * 255 // 45, 0, 255)  # fully keyed above 70, fully kept below 25
    return np.dstack([rgb, alpha]).astype(np.uint8), kind


# ---------------------------------------------------------------- cutting
def figures(rgba, n, owned=False):
    """Exactly n figures, left to right, as (x0, y0, x1, y1) boxes on the board.
    With owned=True, also each figure's own pixels, so a neighbour's boot inside the box is left out."""
    solid = rgba[..., 3] > 128
    blobs, count = ndimage.label(ndimage.binary_dilation(solid, iterations=6))
    boxes = []
    for i, sl in enumerate(ndimage.find_objects(blobs), 1):
        area = int((blobs[sl] == i).sum())
        if area > solid.size * 0.004:                     # drop specks and stray marks
            boxes.append([sl[1].start, sl[0].start, sl[1].stop, sl[0].stop, area])
    boxes.sort(key=lambda b: b[0])
    while len(boxes) > n:                                 # a detached hand or ball: join it to its nearest neighbour
        k = min(range(len(boxes)), key=lambda i: boxes[i][4])
        small = boxes.pop(k)
        cx = (small[0] + small[2]) / 2
        j = min(range(len(boxes)), key=lambda i: abs((boxes[i][0] + boxes[i][2]) / 2 - cx))
        o = boxes[j]
        boxes[j] = [min(o[0], small[0]), min(o[1], small[1]), max(o[2], small[2]), max(o[3], small[3]), o[4] + small[4]]
    while len(boxes) < n and boxes:                       # two figures touching: split the widest at its thinnest column
        k = max(range(len(boxes)), key=lambda i: boxes[i][2] - boxes[i][0])
        x0, y0, x1, y1, area = boxes.pop(k)
        cols = solid[y0:y1, x0:x1].sum(0)
        q = (x1 - x0) // 4
        m = x0 + q + int(np.argmin(cols[q:len(cols) - q]))
        for a, b in ((x0, m), (m, x1)):
            ys = np.nonzero(solid[y0:y1, a:b].any(1))[0]
            boxes.append([a, y0 + ys[0], b, y0 + ys[-1] + 1, area // 2])
        boxes.sort(key=lambda b: b[0])
    out = [tuple(b[:4]) for b in boxes]
    if not owned: return out
    centre = {i: (sl[1].start + sl[1].stop) / 2 for i, sl in enumerate(ndimage.find_objects(blobs), 1)}
    spans = {i: sum(1 for x0, _, x1, _ in out if x0 < sl[1].stop and x1 > sl[1].start) for i, sl in enumerate(ndimage.find_objects(blobs), 1)}
    owners = [np.array([0] + [spans[i] == 1 and x0 <= centre[i] < x1 for i in range(1, count + 1)], bool)[blobs] & solid for x0, _, x1, _ in out]
    shared = np.array([0] + [spans[i] > 1 for i in range(1, count + 1)], bool)[blobs] & solid
    if shared.any():   # touching figures: grow each one from its middle through the shared pixels, like a flood
        seeds = []
        for x0, y0, x1, y1 in out:
            cx, h = (x0 + x1) // 2, y1 - y0
            seed = np.zeros_like(solid); seed[y0 + h * 3 // 10:y0 + h * 7 // 10, max(x0, cx - 12):min(x1, cx + 12)] = True
            seeds.append(seed & shared)
        ys, xs = np.nonzero(shared); win = (slice(ys.min(), ys.max() + 1), slice(xs.min(), xs.max() + 1))  # flood only where it matters
        part, grow = shared[win], [sd[win] for sd in seeds]
        taken = np.any(grow, axis=0)
        while True:
            grown = False
            for k, seed in enumerate(grow):
                new = ndimage.binary_dilation(seed, iterations=3) & part & ~taken
                if new.any(): grow[k] = seed | new; taken |= new; grown = True
            if not grown: break
        for k, sd in enumerate(seeds): sd[win] = grow[k]
        owners = [o | sd for o, sd in zip(owners, seeds)]
    return out, owners


def kit_mask(rgba):
    """255 where the pixel is white kit (bright, unsaturated), for club colours."""
    rgb = rgba[..., :3].astype(np.int32)
    r, b = rgb[..., 0], rgb[..., 2]
    bright, spread = rgb.max(-1), rgb.max(-1) - rgb.min(-1)
    # white and its shadows under the cool floodlights: blue at least as strong as red. Skin is warm (red above blue)
    g = rgb[..., 1]
    rim = (b >= g) & (g >= r) & (((b > 170)) | ((bright > 70) & (spread < 75)))  # bluish rim light and cool shadows on the kit
    m = (((bright > 95) & (spread < 40)) | rim) & (b >= r - 4) & (rgba[..., 3] > 128)
    m = ndimage.binary_opening(m, iterations=1)           # no single white pixels in eyes or boots
    m = ndimage.binary_fill_holes(ndimage.binary_closing(m, iterations=2)) & (rgba[..., 3] > 128)
    return (m * 255).astype(np.uint8)


def torso_x(rgba):
    """The middle of the shirt in the upper half: the anchor that keeps the body still between frames."""
    h = rgba.shape[0]
    m = kit_mask(rgba[: h // 2])
    xs = np.nonzero(m)[1]
    return float(xs.mean()) if len(xs) else rgba.shape[1] / 2


# ---------------------------------------------------------------- boards
def boards():
    """Every animation board named in a README: (character, sequence name, file, first, last, total)."""
    found = []
    for d, _, files in os.walk(RAW):
        if 'README.md' not in files or os.sep + 'stadiums' in d: continue
        for line in open(os.path.join(d, 'README.md'), encoding='utf-8'):
            m = re.match(r'\| `([^`]+\.png)` \| ([^|]*) \|', line)
            if not m: continue
            r = RANGE.search(m.group(2))
            path = os.path.join(d, m.group(1))
            if not r or not os.path.exists(path): continue
            folder = os.path.relpath(d, RAW).replace(os.sep, '/')
            char = folder                                # the character: the nearest folder up with a reference card
            while '/' in char and not os.path.exists(os.path.join(RAW, char, 'ref.png')): char = char.rsplit('/', 1)[0]
            seq = folder + '/' + re.sub(r'-\d+\.png$', '', m.group(1))   # e.g. striker/run/run-side, balls/classic/spin
            found.append((char, seq, path, int(r.group(1)), int(r.group(2)), int(r.group(3))))
    return sorted(found)


def board(path):
    """A board at the standard height, and a warning when it is not the 3:2 the prompts ask for:
    figures on another shape are drawn at another scale, and the board needs making again."""
    im = Image.open(path)
    w, h = im.size
    if abs(w / h - 1.5) > 0.06:
        print(f'! {os.path.relpath(path, ROOT)}: {w}x{h} is not 3:2, so its figures are not at the standard scale', file=sys.stderr)
    return im if h == BOARD_H else im.resize((round(w * BOARD_H / h), BOARD_H), Image.LANCZOS)


def ref_height(char):
    """A character's standing height on the reference card, the scale for all its boards."""
    path = os.path.join(RAW, char, 'ref.png')
    if not os.path.exists(path): return None
    rgba, _ = key(board(path))
    hs = [y1 - y0 for x0, y0, x1, y1 in figures(rgba, 4)]
    return float(np.median(hs))


# ---------------------------------------------------------------- packing
class Atlas:
    """Shelf packing into pages ATLAS_W wide; colour and kit mask share the same layout."""
    def __init__(self, name):
        self.name, self.pages, self.cur, self.x, self.y, self.row = name, [], None, 0, 0, 0

    def add(self, rgba, mask):
        h, w = rgba.shape[:2]
        if self.cur is None or self.x + w > ATLAS_W:
            self.x, self.y, self.row = 0, self.y + self.row + 2, 0
        if self.cur is None or self.y + h > ATLAS_W:
            self.cur = [np.zeros((ATLAS_W, ATLAS_W, 4), np.uint8), np.zeros((ATLAS_W, ATLAS_W), np.uint8)]
            self.pages.append(self.cur); self.x = self.y = self.row = 0
        self.cur[0][self.y:self.y + h, self.x:self.x + w] = rgba
        self.cur[1][self.y:self.y + h, self.x:self.x + w] = mask
        spot = (len(self.pages) - 1, self.x, self.y)
        self.x += w + 2; self.row = max(self.row, h)
        return spot

    def save(self, folder):
        names = []
        for i, (rgba, mask) in enumerate(self.pages):
            used = max(1, int(np.nonzero(rgba[..., 3].any(1))[0].max()) + 1) if rgba[..., 3].any() else 1
            base = f'{self.name}-{i}'
            Image.fromarray(rgba[:used]).save(os.path.join(folder, base + '.png'), optimize=True)
            Image.fromarray(mask[:used]).save(os.path.join(folder, base + '-kit.png'), optimize=True)
            names.append(base)
        return names


# ---------------------------------------------------------------- build
def build():
    cut = {}                                               # (char, seq) -> list of frames
    scales = {}
    seq_height = {}                                        # (char, seq) -> median figure height of its first board
    for char, seq, path, first, last, total in boards():
        if char not in scales: scales[char] = ref_height(char)
        im = board(path)
        rgba, kind = key(im)
        n = last - first + 1
        boxes, owners = figures(rgba, n, owned=True)
        if len(boxes) != n:
            print(f'! {os.path.relpath(path, ROOT)}: found {len(boxes)} figures, expected {n}', file=sys.stderr); continue
        # A cycle (run, walk, dribble...) has the same height on every board: one drawn smaller is brought to the first one's size.
        med = float(np.median([y1 - y0 for x0, y0, x1, y1 in boxes]))
        if CYCLE.search(seq) and (char, seq) in seq_height and abs(seq_height[(char, seq)] / med - 1) > 0.03:
            r = seq_height[(char, seq)] / med
            rgba, kind = key(im.resize((round(im.size[0] * r), round(im.size[1] * r)), Image.LANCZOS))
            if r > 1.1:                                    # enlarging widens the green fringe: trim the edge back
                rgba = rgba.copy(); rgba[..., 3] = ndimage.grey_erosion(rgba[..., 3], size=(1 + round(r), 1 + round(r)))
            boxes, owners = figures(rgba, n, owned=True)
        seq_height.setdefault((char, seq), med)
        ground = max(y1 for x0, y0, x1, y1 in boxes)           # every board has its own ground line: its lowest foot
        for i, (x0, y0, x1, y1) in enumerate(boxes):
            fr = rgba[y0:y1, x0:x1].copy()
            fr[..., 3] = np.where(owners[i][y0:y1, x0:x1], fr[..., 3], 0)
            cut.setdefault((char, seq), {'total': total, 'frames': {}, 'kind': kind})['frames'][first + i] = (fr, ground - y1, torso_x(fr))
    manifest = {'fps': FPS, 'sizes': {}, 'sequences': {}, 'plates': {}}
    for size, H in SIZES.items():
        folder = os.path.join(OUT, size); os.makedirs(folder, exist_ok=True)
        atlas = Atlas('sprites')
        for (char, seq), s in sorted(cut.items()):
            ref = scales.get(char) or max(f[0].shape[0] for f in s['frames'].values())
            k = H / ref
            frames = []
            for idx in sorted(s['frames']):
                fr, lift, ax = s['frames'][idx]                   # lift: how far its feet are above its board's ground
                w, h = max(1, round(fr.shape[1] * k)), max(1, round(fr.shape[0] * k))
                img = np.asarray(Image.fromarray(fr).resize((w, h), Image.LANCZOS))
                page, x, y = atlas.add(img, kit_mask(img))
                frames.append({'i': idx, 'page': page, 'x': x, 'y': y, 'w': w, 'h': h,
                               'ax': round(ax * k, 1),               # anchor x: the torso
                               'ay': round(h + lift * k, 1)})            # anchor y: the ground line, so a frame in the air stays in the air
            name = seq
            missing = [i for i in range(1, s['total'] + 1) if i not in s['frames']]
            manifest['sequences'].setdefault(name, {'total': s['total'], 'missing': missing, 'frames': {}})['frames'][size] = frames
        manifest['sizes'][size] = {'player': H, 'pages': atlas.save(folder)}
        for d, _, files in os.walk(os.path.join(RAW, 'stadiums')):
            for f in sorted(files):
                if not f.endswith('.jpg'): continue
                rel = os.path.relpath(os.path.join(d, f), os.path.join(RAW, 'stadiums')).replace(os.sep, '/')[:-4]
                im = Image.open(os.path.join(d, f)).convert('RGB')
                w = PLATE_W[size]; im = im.resize((w, round(im.size[1] * w / im.size[0])), Image.LANCZOS)
                dest = os.path.join(folder, 'plates', rel + '.webp'); os.makedirs(os.path.dirname(dest), exist_ok=True)
                im.save(dest, quality=82, method=6)
                manifest['plates'].setdefault(rel, {})[size] = [im.size[0], im.size[1]]
    json.dump(manifest, open(os.path.join(OUT, 'manifest.json'), 'w'), ensure_ascii=False, indent=1, sort_keys=True)
    seqs = manifest['sequences']
    print(f'{len(seqs)} sequences, {sum(len(v["frames"]["hd"]) for v in seqs.values())} frames, {len(manifest["plates"])} plates -> {os.path.relpath(OUT, ROOT)}')


if __name__ == '__main__':
    build()
