"""[Sprint 61 F2] The frames of render_spins.cjs joined into one strip a model, side by side in turning order, as
WebP with its clear ground: mobile/assets/models/<model>_spin_512.webp and _256.webp (GlmModelSpin picks one by the
size it is drawn at).

    python3 tools/models/spins.py
"""

import pathlib

from PIL import Image

HERE = pathlib.Path(__file__).resolve().parent
OUT = HERE.parents[1] / 'mobile' / 'assets' / 'models'

for model in sorted(p for p in (HERE / 'frames').iterdir() if p.is_dir()):
    frames = [Image.open(f).convert('RGBA') for f in sorted(model.glob('*.png'))]
    for size in (512, 256):
        strip = Image.new('RGBA', (size * len(frames), size))
        for i, f in enumerate(frames):
            strip.paste(f.resize((size, size), Image.LANCZOS), (i * size, 0))
        target = OUT / f'{model.name}_spin_{size}.webp'
        strip.save(target, 'WEBP', quality=82, method=6)
        print(f'{target.name}: {len(frames)} frames, {target.stat().st_size // 1024} KB')
