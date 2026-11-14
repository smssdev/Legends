# The promo video's assets [2026-11-15]: the screens and the match's moments (capture.mjs, capture-match.mjs), the
# broadcast's clip card cut out of its frame, and the game's own art (logo, stadium, coaches, mascot, fonts), into
# tools/promo/out/assets/ for stage.html. Run from the repository's root: python3 tools/promo/prepare.py
import shutil
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'tools/promo/out'
A = OUT / 'assets'
A.mkdir(parents=True, exist_ok=True)

# The match's moments: the clip card (the same place in every 1830x824 frame), and the line-up card.
CARD = (426, 140, 1402, 796)
for name, frame in [('attack', 13), ('goal1', 14), ('goal2', 30), ('save', 38), ('stop', 54), ('foul', 42)]:
    Image.open(OUT / f'match/m-{frame:03d}.png').convert('RGB').crop(CARD).save(A / f'clip-{name}.jpg', quality=92)
Image.open(OUT / 'match/m-000.png').convert('RGB').save(A / 'versus.jpg', quality=92)
Image.open(OUT / 'match/m-020.png').convert('RGB').save(A / 'live.jpg', quality=92)

for n in ['squad', 'lineup', 'tactics', 'market', 'training', 'stadium', 'next-match', 'league-picker', 'tournament', 'groups']:
    Image.open(OUT / f'shots/{n}.png').convert('RGB').save(A / f'{n}.jpg', quality=92)

for src, dst in [
    ('brand/current/emblem-ar.svg', 'emblem-ar.svg'),
    ('brand/current/logo-wide.svg', 'logo-wide.svg'),
    ('brand/current/coin.svg', 'coin.svg'),
    ('brand/art/stadium-blur.jpg', 'bg-stadium.jpg'),
    ('brand/states/celebrate.png', 'mascot-celebrate.png'),
    ('brand/states/welcome.png', 'mascot-welcome.png'),
    ('web/public/characters/c1-joy.webp', 'coach-joy.webp'),
    ('web/public/characters/c2-angry.webp', 'coach-angry.webp'),
    ('web/public/characters/c3-cheer.webp', 'coach-cheer.webp'),
    ('web/public/characters/c1-think.webp', 'coach-think.webp'),
    ('web/public/fonts/tajawal-700-arabic.woff2', 'tajawal-700-arabic.woff2'),
    ('web/public/fonts/tajawal-500-arabic.woff2', 'tajawal-500-arabic.woff2'),
    ('web/public/fonts/barlow-condensed-800-latin.woff2', 'barlow-800.woff2'),
    ('web/public/fonts/barlow-condensed-700-latin.woff2', 'barlow-700.woff2'),
]:
    shutil.copy(ROOT / src, A / dst)
print('assets:', len(list(A.iterdir())))
