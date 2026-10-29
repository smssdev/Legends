"""The game's Arabic name as paths for the crest [SEO]: python3 tools/brand/arabic_name.py

An SVG the web shows as an <img> can't load fonts, so «المدرب» and «الأسطورة» are shaped with HarfBuzz in the game's
own font (Amin Bold, web/public/fonts) and written as path data to tools/brand/name-ar.json, which logo.py reads.
Needs: pip install fonttools brotli uharfbuzz (only to run this; logo.py needs nothing).
"""
import io, json, os
import uharfbuzz as hb
from fontTools.pens.boundsPen import BoundsPen
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
from fontTools.ttLib import TTFont

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..')
FONT = os.path.join(ROOT, 'web', 'public', 'fonts', 'amin-bold.woff2')

font = TTFont(FONT)
buf = io.BytesIO()
font.flavor = None
font.save(buf)
face = hb.Face(buf.getvalue())
hbfont = hb.Font(face)
glyphs = font.getGlyphSet()
order = font.getGlyphOrder()
upem = font['head'].unitsPerEm
ascent, descent = font['hhea'].ascent, font['hhea'].descent


def shape(text):
    """The word as one path in font units, y down from the baseline: (d, its ink box [x0, y0, x1, y1])."""
    b = hb.Buffer()
    b.add_str(text)
    b.guess_segment_properties()
    hb.shape(hbfont, b)
    pen, box = SVGPathPen(glyphs), BoundsPen(glyphs)
    x = 0
    # HarfBuzz gives right-to-left words in visual order, left to right.
    for info, pos in zip(b.glyph_infos, b.glyph_positions):
        for p in (pen, box):
            glyphs[order[info.codepoint]].draw(TransformPen(p, (1, 0, 0, -1, x + pos.x_offset, -pos.y_offset)))
        x += pos.x_advance
    return pen.getCommands(), [round(v) for v in box.bounds]


out = {'upem': upem, 'ascent': ascent, 'descent': descent}
for key, word in (('coach', 'المدرب'), ('legend', 'الأسطورة')):
    d, box = shape(word)
    out[key] = {'text': word, 'd': d, 'box': box}
json.dump(out, open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'name-ar.json'), 'w'), ensure_ascii=False, indent=1)
print('name-ar.json:', ', '.join(f"{out[k]['text']} {out[k]['box']}" for k in ('coach', 'legend')), f'(upem {upem}, ascent {ascent}, descent {descent})')
