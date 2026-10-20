"""The Legends emblem (الأساطير): python3 tools/brand/logo.py

Draws the logo as SVG from geometry, so every size comes from one source:
a shield with a gold rim, a crown on its top edge, a football in the middle held by
a laurel wreath, on navy. Writes brand/current/*.svg; tools/brand/render.mjs makes the PNGs.
"""
import math, os

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..')
OUT = os.path.join(ROOT, 'brand', 'current')
NAVY, NAVY_DEEP, GOLD, GOLD_DARK, GOLD_LIGHT, IVORY = '#0A1F42', '#071733', '#F5B82E', '#C08A0C', '#FFD978', '#F7F4EA'


def f(v):
    return f'{v:.1f}'.rstrip('0').rstrip('.')


def poly(points):
    return 'M' + ' L'.join(f'{f(x)} {f(y)}' for x, y in points) + ' Z'


def shield(cx=256, top=150, w=300, h=318):
    """A heater shield: flat top with rounded shoulders, sides that curve into a point."""
    l, r, b = cx - w / 2, cx + w / 2, top + h
    return (f'M{f(l + 18)} {f(top)} L{f(r - 18)} {f(top)} Q{f(r)} {f(top)} {f(r)} {f(top + 18)} '
            f'L{f(r)} {f(top + h * 0.42)} C{f(r)} {f(top + h * 0.78)} {f(cx + w * 0.2)} {f(b - 22)} {f(cx)} {f(b)} '
            f'C{f(cx - w * 0.2)} {f(b - 22)} {f(l)} {f(top + h * 0.78)} {f(l)} {f(top + h * 0.42)} '
            f'L{f(l)} {f(top + 18)} Q{f(l)} {f(top)} {f(l + 18)} {f(top)} Z')


def crown(cx=256, base=158, w=176, h=92, gold=GOLD, line=NAVY_DEEP, pearl=GOLD_LIGHT, gem=NAVY):
    """Three points with pearls; the band sits across the shield's top edge."""
    l, r = cx - w / 2, cx + w / 2
    pts = [(l, base), (l - 6, base - h * 0.78), (cx - w * 0.24, base - h * 0.42), (cx, base - h), (cx + w * 0.24, base - h * 0.42), (r + 6, base - h * 0.78), (r, base)]
    pearls = [(l - 6, base - h * 0.78), (cx, base - h), (r + 6, base - h * 0.78)]
    band = f'<rect x="{f(l)}" y="{f(base - 4)}" width="{f(w)}" height="22" rx="6" fill="{gold}" stroke="{line}" stroke-width="5"/>'
    gems = ''.join(f'<circle cx="{f(cx + dx)}" cy="{f(base + 7)}" r="5" fill="{gem}"/>' for dx in (-48, 0, 48))
    return (f'<path d="{poly(pts)}" fill="{gold}" stroke="{line}" stroke-width="5" stroke-linejoin="round"/>'
            + ''.join(f'<circle cx="{f(x)}" cy="{f(y)}" r="11" fill="{pearl}" stroke="{line}" stroke-width="5"/>' for x, y in pearls)
            + band + gems)


def ball(cx=256, cy=300, r=82, panel=NAVY, fill="url(#ballFill)", edge=NAVY_DEEP):
    """A football: the middle pentagon, five more at its corners cut by the rim, and the seams between."""
    def pent(x, y, s, rot):
        return [(x + s * math.sin(rot + i * 2 * math.pi / 5), y - s * math.cos(rot + i * 2 * math.pi / 5)) for i in range(5)]
    s = r * 0.34
    mid = pent(cx, cy, s, 0)
    outer, seams = [], []
    for i in range(5):
        a = i * 2 * math.pi / 5                       # the direction of the middle pentagon's corner
        ox, oy = cx + r * 1.0 * math.sin(a), cy - r * 1.0 * math.cos(a)
        p = pent(ox, oy, s, a + math.pi)              # one corner points back at the middle
        outer.append(p)
        seams.append(f'M{f(mid[i][0])} {f(mid[i][1])} L{f(p[0][0])} {f(p[0][1])}')
        # the seam between this outer pentagon and the next one round
        nb = a + 2 * math.pi / 5
        q = pent(cx + r * math.sin(nb), cy - r * math.cos(nb), s, nb + math.pi)
        seams.append(f'M{f(p[4][0])} {f(p[4][1])} L{f(q[1][0])} {f(q[1][1])}')
    clip = '<clipPath id="ballClip"><circle cx="{0}" cy="{1}" r="{2}"/></clipPath>'.format(f(cx), f(cy), f(r))
    return (clip
            + f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(r)}" fill="{fill}"/>'
            + f'<g clip-path="url(#ballClip)"><g fill="{panel}">' + ''.join(f'<path d="{poly(p)}"/>' for p in outer + [mid]) + '</g>'
            + f'<path d="{" ".join(seams)}" stroke="{panel}" stroke-width="{f(r * 0.05)}" stroke-linecap="round" fill="none"/></g>'
            + f'<circle cx="{f(cx)}" cy="{f(cy)}" r="{f(r)}" fill="none" stroke="{edge}" stroke-width="6"/>')


def laurel(cx=256, cy=304, r=112, side=1, n=8):
    """One branch of the wreath, from under the ball up one side; leaves alternate out and in along it."""
    out = []
    pts = []
    for i in range(n + 1):
        t = math.radians(18 + i * 15)                 # measured from straight below the ball, up its side
        pts.append((cx + side * r * math.sin(t), cy + r * math.cos(t)))
    stem = 'M' + ' L'.join(f'{f(x)} {f(y)}' for x, y in pts)
    out.append(f'<path d="{stem}" fill="none" stroke="{GOLD_DARK}" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/>')
    for i in range(1, n + 1):
        (x0, y0), (x1, y1) = pts[i - 1], pts[i]
        along = math.degrees(math.atan2(y1 - y0, x1 - x0))
        size = 22 - i * 1.1
        for k, turn in enumerate((-38, 38)):
            ang = along + turn
            out.append(f'<ellipse cx="{f(x1)}" cy="{f(y1)}" rx="{f(size)}" ry="{f(size * 0.4)}" fill="{GOLD}" stroke="{NAVY_DEEP}" stroke-width="2.5" '
                       f'transform="rotate({f(ang)} {f(x1)} {f(y1)}) translate({f(-size * 0.75)} 0)"/>')
    return ''.join(out)


DEFS = f'''<defs>
  <linearGradient id="shieldFill" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#16376F"/><stop offset="1" stop-color="{NAVY_DEEP}"/></linearGradient>
  <linearGradient id="rim" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="{GOLD_LIGHT}"/><stop offset=".5" stop-color="{GOLD}"/><stop offset="1" stop-color="{GOLD_DARK}"/></linearGradient>
  <radialGradient id="ballFill" cx=".38" cy=".32" r=".8"><stop offset="0" stop-color="#FFFFFF"/><stop offset=".55" stop-color="{IVORY}"/><stop offset="1" stop-color="#D9D2BC"/></radialGradient>
</defs>'''


def emblem(simple=False):
    """The emblem alone in a 512 box. simple=True drops the wreath for tiny sizes (favicons)."""
    parts = [f'<path d="{shield()}" fill="url(#shieldFill)" stroke="url(#rim)" stroke-width="18" stroke-linejoin="round"/>',
             f'<path d="{shield(top=172, w=262, h=280)}" fill="none" stroke="{GOLD}" stroke-opacity=".35" stroke-width="3"/>']
    if not simple:
        parts += [laurel(side=1), laurel(side=-1)]
    parts += [ball(r=86 if simple else 76, cy=304), crown()]
    return ''.join(parts)


def svg(body, w=512, h=512, bg=None, rx=0):
    back = f'<rect width="{w}" height="{h}" rx="{rx}" fill="{bg}"/>' if bg else ''
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}">{DEFS}{back}{body}</svg>\n'


def coin():
    """الكوينز, the premium currency: a gold coin with the ball and the crown struck in it."""
    return (f'<circle cx="256" cy="256" r="236" fill="{GOLD_DARK}"/>'
            f'<circle cx="256" cy="248" r="226" fill="url(#rim)"/>'
            f'<circle cx="256" cy="248" r="184" fill="{GOLD}" stroke="{GOLD_DARK}" stroke-width="10"/>'
            + ball(cy=290, r=88, panel=GOLD_DARK, fill=GOLD_LIGHT, edge=GOLD_DARK)
            + crown(base=196, w=150, h=78, gold=GOLD_LIGHT, line=GOLD_DARK, pearl=GOLD_LIGHT, gem=GOLD_DARK)
            + '<ellipse cx="170" cy="130" rx="64" ry="22" fill="#FFFFFF" opacity=".28" transform="rotate(-32 170 130)"/>')


FILES = {
    'coin.svg': svg(coin()),
    # the emblem on a clear background, for anything already dark
    'emblem.svg': svg(emblem()),
    # the app icon: the emblem on navy, with a safe margin for round (maskable) masks
    'icon.svg': svg(f'<g transform="translate(51 46) scale(.8)">{emblem()}</g>', bg=NAVY),
    # browser tab: no wreath, so it still reads at 16 pixels
    'favicon.svg': svg(f'<g transform="translate(-8 -22) scale(1.03)">{emblem(simple=True)}</g>'),
    # the full logo: emblem, LEGENDS and the Arabic name
    'logo.svg': svg(
        f'<g transform="translate(128 10) scale(1.5)">{emblem()}</g>'
        f'<text x="512" y="860" text-anchor="middle" font-family="Alexandria, sans-serif" font-weight="800" font-size="150" letter-spacing="18" fill="{GOLD}">LEGENDS</text>'
        f'<text x="512" y="985" text-anchor="middle" font-family="Alexandria, sans-serif" font-weight="700" font-size="96" fill="{IVORY}" direction="rtl">الأساطير</text>',
        w=1024, h=1060, bg=NAVY),
}

if __name__ == '__main__':
    for name, text in FILES.items():
        open(os.path.join(OUT, name), 'w').write(text)
    print('wrote', ', '.join(FILES))
