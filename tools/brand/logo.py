"""The GLM identity (Game Legend Manager, X44): python3 tools/brand/logo.py

Draws every brand mark as SVG from geometry, so each size comes from one source and the colours
from docs/design/tokens.json (night ink, emerald, gold, ivory). No mark that the web shows as an
<img> carries text, since an SVG image can't load the game's fonts: the GLM monogram is paths.

  the crest (emblem.svg): a shield with a raised centre and swept-up shoulders in a metal gold
  rim, an emerald field lit by gold rays with the pitch's centre circle, three championship
  stars, the GLM monogram slanted forward (G and L in silver, M for Manager in gold, each
  wrapped in ink and gold), a football breaking out of its point and a gold laurel round it.

  [SEO] the crest in Arabic (emblem-ar.svg): the same, with «المدرب» over «الأسطورة» in place of the monogram,
  as paths in the game's font (tools/brand/arabic_name.py). The Arabic screens, the app icon and the invite card.

Writes brand/current/*.svg; tools/brand/render.mjs makes the PNGs and copies the web's files.
"""
import json, os

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..')
OUT = os.path.join(ROOT, 'brand', 'current')
C = json.load(open(os.path.join(ROOT, 'docs', 'design', 'tokens.json')))['color']
INK, INK_DEEP, PANEL, RAISED = C['bg'], C['bgDeep'], C['panel'], C['surfaceRaised']
GOLD, GOLD_DARK, GOLD_LIGHT = C['gold'], C['goldDark'], C['goldLight']
EMERALD, EMERALD_DARK, MINT, IVORY = C['brand'], C['brandDark'], C['brandLight'], C['text']

SANS = "Alexandria, sans-serif"

DEFS = f'''<defs>
  <linearGradient id="inkFill" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{RAISED}"/><stop offset=".55" stop-color="{INK}"/><stop offset="1" stop-color="{INK_DEEP}"/></linearGradient>
  <linearGradient id="gold" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="{GOLD_LIGHT}"/><stop offset=".5" stop-color="{GOLD}"/><stop offset="1" stop-color="{GOLD_DARK}"/></linearGradient>
  <linearGradient id="rimMetal" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#FFF1C2"/><stop offset=".3" stop-color="{GOLD_LIGHT}"/><stop offset=".5" stop-color="{GOLD}"/><stop offset=".72" stop-color="{GOLD_DARK}"/><stop offset="1" stop-color="#7A5206"/></linearGradient>
  <linearGradient id="metal" gradientUnits="userSpaceOnUse" x1="0" y1="0" x2="0" y2="110"><stop offset="0" stop-color="#FFF6D6"/><stop offset=".46" stop-color="{GOLD_LIGHT}"/><stop offset=".5" stop-color="{GOLD}"/><stop offset=".53" stop-color="{GOLD_DARK}"/><stop offset="1" stop-color="{GOLD}"/></linearGradient>
  <linearGradient id="silver" gradientUnits="userSpaceOnUse" x1="0" y1="0" x2="0" y2="110"><stop offset="0" stop-color="#FFFFFF"/><stop offset=".46" stop-color="{IVORY}"/><stop offset=".5" stop-color="#D9D2BC"/><stop offset=".53" stop-color="#B9B19A"/><stop offset="1" stop-color="{IVORY}"/></linearGradient>
  <radialGradient id="field" cx=".5" cy=".36" r=".78"><stop offset="0" stop-color="{EMERALD}"/><stop offset=".38" stop-color="{EMERALD_DARK}"/><stop offset=".78" stop-color="{INK}"/><stop offset="1" stop-color="{INK_DEEP}"/></radialGradient>
  <radialGradient id="glow" cx=".5" cy=".42" r=".6"><stop offset="0" stop-color="{EMERALD}" stop-opacity=".55"/><stop offset="1" stop-color="{EMERALD}" stop-opacity="0"/></radialGradient>
  <radialGradient id="ballSkin" cx=".35" cy=".3" r=".85"><stop offset="0" stop-color="#FFFFFF"/><stop offset=".6" stop-color="{IVORY}"/><stop offset="1" stop-color="#A9A28C"/></radialGradient>
  <clipPath id="crestIn"><path d="{{IN}}"/></clipPath>
  <filter id="sticker" x="-25%" y="-30%" width="150%" height="170%">
    <feMorphology in="SourceAlpha" operator="dilate" radius="5" result="o1"/><feFlood flood-color="{INK_DEEP}"/><feComposite in2="o1" operator="in" result="ink1"/>
    <feMorphology in="SourceAlpha" operator="dilate" radius="9" result="o2"/><feFlood flood-color="{GOLD}"/><feComposite in2="o2" operator="in" result="gold2"/>
    <feMorphology in="SourceAlpha" operator="dilate" radius="12" result="o3"/><feFlood flood-color="{INK_DEEP}"/><feComposite in2="o3" operator="in" result="ink3"/>
    <feOffset in="ink3" dy="8" result="drop"/>
    <feMerge><feMergeNode in="drop"/><feMergeNode in="ink3"/><feMergeNode in="gold2"/><feMergeNode in="ink1"/><feMergeNode in="SourceGraphic"/></feMerge>
  </filter>
</defs>'''

# The crest's outline: a shield with a raised centre and swept-up shoulders, and its inner field.
CREST = 'M256 44 L318 74 L404 62 L422 96 L408 262 C398 352 336 404 256 452 C176 404 114 352 104 262 L90 96 L108 62 L194 74 Z'
CREST_IN = 'M256 68 L314 95 L388 86 L399 108 L387 258 C379 338 326 383 256 424 C186 383 133 338 125 258 L113 108 L124 86 L198 95 Z'
DEFS = DEFS.replace('{IN}', CREST_IN)


def monogram(x, y, scale=1.0, letters='url(#silver)', m='url(#metal)', sw=26, slant=-10, outline=True):
    """GLM in a 272x110 box at (x, y), slanted forward: a chamfered G and an L drawn as heavy strokes, the M
    one solid shape. outline=True wraps it in the sticker filter (ink, gold, ink, and a drop under it)."""
    body = (f'<g transform="translate({x} {y}) scale({scale}) translate(136 55) skewX({slant}) translate(-136 -55)">'
            f'<path d="M80 13 H32 L13 32 V78 L32 97 H67 V58 H42" fill="none" stroke="{letters}" stroke-width="{sw}" stroke-linejoin="miter"/>'
            f'<path d="M107 0 V97 H156" fill="none" stroke="{letters}" stroke-width="{sw}" stroke-linejoin="miter"/>'
            f'<path d="M170 110 V0 H198 L221 40 L244 0 H272 V110 H246 V52 L229 82 H213 L196 52 V110 Z" fill="{m}"/>'
            '</g>')
    return f'<g filter="url(#sticker)">{body}</g>' if outline else body


def star(cx, cy, r, fill='url(#gold)', line=INK_DEEP):
    import math
    pts = [(cx + (r if i % 2 == 0 else r * .45) * math.sin(math.radians(i * 36)), cy - (r if i % 2 == 0 else r * .45) * math.cos(math.radians(i * 36))) for i in range(10)]
    return f'<path d="M' + ' L'.join(f'{x:.1f} {y:.1f}' for x, y in pts) + f' Z" fill="{fill}" stroke="{line}" stroke-width="3" stroke-linejoin="round"/>'


def ball(cx, cy, r, uid='b'):
    """A real-looking football: the middle pentagon, five more cut by the edge, the seams, shading."""
    import math
    def pent(px, py, s, rot):
        return [(px + s * math.sin(rot + k * 2 * math.pi / 5), py - s * math.cos(rot + k * 2 * math.pi / 5)) for k in range(5)]
    d = lambda p: 'M' + ' L'.join(f'{x:.1f} {y:.1f}' for x, y in p) + ' Z'
    mid = pent(cx, cy, r * .36, 0)
    outer = [pent(cx + r * .96 * math.sin(a), cy - r * .96 * math.cos(a), r * .38, a + math.pi) for a in (k * 2 * math.pi / 5 for k in range(5))]
    edges = [((mid[k][0] + mid[(k + 1) % 5][0]) / 2, (mid[k][1] + mid[(k + 1) % 5][1]) / 2) for k in range(5)]
    seams = ' '.join(f'M{cx + (x - cx) * 3.05:.1f} {cy + (y - cy) * 3.05:.1f} L{cx + (x - cx) * 3.6:.1f} {cy + (y - cy) * 3.6:.1f}' for x, y in edges) + ' ' + ' '.join(f'M{x:.1f} {y:.1f} L{cx + (x - cx) * 1.6:.1f} {cy + (y - cy) * 1.6:.1f}' for x, y in mid)
    return (f'<clipPath id="{uid}"><circle cx="{cx}" cy="{cy}" r="{r}"/></clipPath>'
            f'<circle cx="{cx}" cy="{cy + 6}" r="{r + 8}" fill="{INK_DEEP}" opacity=".55"/>'
            f'<circle cx="{cx}" cy="{cy}" r="{r + 7}" fill="url(#rimMetal)"/>'
            f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="url(#ballSkin)"/>'
            f'<g clip-path="url(#{uid})" fill="{INK}"><path d="{d(mid)}"/>' + ''.join(f'<path d="{d(p)}"/>' for p in outer)
            + f'<path d="{seams}" stroke="{INK}" stroke-width="{r * .07:.1f}" stroke-linecap="round"/></g>'
            f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="none" stroke="{INK_DEEP}" stroke-width="3"/>'
            '')


def laurel(side, cx=256, cy=262, r=208, n=9):
    """One branch of the wreath round the shield, from beside the ball up to its shoulder."""
    import math
    pts = [(cx + side * r * math.sin(math.radians(t)), cy + r * math.cos(math.radians(t))) for t in (34 + i * 11 for i in range(n + 1))]
    out = [f'<path d="M' + ' L'.join(f'{x:.1f} {y:.1f}' for x, y in pts) + f'" fill="none" stroke="{GOLD_DARK}" stroke-width="6" stroke-linecap="round" stroke-linejoin="round"/>']
    for i in range(1, n + 1):
        (x0, y0), (x1, y1) = pts[i - 1], pts[i]
        along = math.degrees(math.atan2(y1 - y0, x1 - x0))
        size = 25 - i * 1.2
        for turn in (-40, 40):
            out.append(f'<ellipse cx="{x1:.1f}" cy="{y1:.1f}" rx="{size:.1f}" ry="{size * .38:.1f}" fill="url(#gold)" stroke="{INK_DEEP}" stroke-width="2.5" '
                       f'transform="rotate({along + turn:.1f} {x1:.1f} {y1:.1f}) translate({-size * .8:.1f} 0)"/>')
    return ''.join(out)


def rays(cx=256, cy=236, n=18):
    import math
    out = []
    for k in range(n):
        a, b = math.radians(k * 360 / n - 4), math.radians(k * 360 / n + 4)
        out.append(f'M{cx} {cy} L{cx + 400 * math.sin(a):.0f} {cy - 400 * math.cos(a):.0f} L{cx + 400 * math.sin(b):.0f} {cy - 400 * math.cos(b):.0f} Z')
    return f'<path d="{" ".join(out)}" fill="{GOLD_LIGHT}" opacity=".055"/>'


def crest(wreath=True):
    """The emblem alone in a 512 box (clear background)."""
    return ((laurel(1) + laurel(-1) if wreath else '')
            # the outer ink line, then the metal rim, lit from the upper left
            + f'<path d="{CREST}" fill="{INK_DEEP}" stroke="{INK_DEEP}" stroke-width="14" stroke-linejoin="round"/>'
            + f'<path d="{CREST}" fill="url(#rimMetal)"/>'
            + f'<path d="{CREST_IN}" fill="url(#field)" stroke="{INK_DEEP}" stroke-width="5" stroke-linejoin="round"/>'
            + f'<g clip-path="url(#crestIn)">{rays()}'
            # the pitch's halfway line and centre circle, faint under the letters
            + f'<path d="M100 300 H412" stroke="{MINT}" stroke-opacity=".22" stroke-width="3"/><circle cx="256" cy="300" r="58" fill="none" stroke="{MINT}" stroke-opacity=".22" stroke-width="3"/>'
            + f'<path d="M100 330 L256 380 L412 330 V460 H100 Z" fill="{INK_DEEP}" opacity=".45"/></g>'
            + f'<path d="M124 86 L198 95 L256 68" fill="none" stroke="#FFFFFF" stroke-opacity=".35" stroke-width="2"/>'
            + star(256, 128, 26) + star(198, 140, 15) + star(314, 140, 15)
            + monogram(130, 186, scale=.93)
            + ball(256, 418, 40, uid='crestBall'))


# [SEO] The Arabic name, «المدرب» over «الأسطورة», as paths in the game's font (tools/brand/arabic_name.py).
NAME_AR = json.load(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'name-ar.json'), encoding='utf-8'))


AR_DEFS = (f'<defs><linearGradient id="silverBox" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFFFFF"/>'
           f'<stop offset=".46" stop-color="{IVORY}"/><stop offset=".5" stop-color="#D9D2BC"/><stop offset=".53" stop-color="#B9B19A"/>'
           f'<stop offset="1" stop-color="{IVORY}"/></linearGradient></defs>')


def name_ar(cx, top, width, gap=4, outline=True):
    """«المدرب» in silver over «الأسطورة» in gold, centred on cx from top, the longer line width wide; returns
    (svg, bottom). outline=True wraps it in the sticker filter, as the monogram."""
    coach, legend = NAME_AR['coach'], NAME_AR['legend']
    k = width / (legend['box'][2] - legend['box'][0])
    body, y = '', top
    for word, fill in ((coach, 'url(#silverBox)'), (legend, 'url(#gold)')):
        x0, y0, x1, y1 = word['box']
        body += (f'<path transform="translate({cx - (x0 + x1) / 2 * k:.2f} {y - y0 * k:.2f}) scale({k:.5f})" '
                 f'd="{word["d"]}" fill="{fill}"/>')
        y += (y1 - y0) * k + gap
    return (f'<g filter="url(#sticker)">{body}</g>' if outline else body), y - gap


def crest_ar(wreath=True):
    """The crest with the Arabic name in place of the monogram: the game's mark in Arabic [SEO]."""
    return crest(wreath).replace(monogram(130, 186, scale=.93), name_ar(256, 180, 236)[0])


def svg(body, w=512, h=512, extra=''):
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}">{DEFS}{extra}{body}</svg>\n'


def tile(rx=0):
    """Night ink with the emerald glow, the ground of every square mark."""
    return f'<rect width="512" height="512" rx="{rx}" fill="url(#inkFill)"/><rect width="512" height="512" rx="{rx}" fill="url(#glow)"/>'


def coin():
    """الكوينز: a gold coin with the crest's three stars struck in it over GLM."""
    ticks = ''.join(f'<rect x="253" y="30" width="6" height="18" rx="2" fill="{GOLD_DARK}" opacity=".55" transform="rotate({a} 256 256)"/>' for a in range(0, 360, 15))
    return (f'<circle cx="256" cy="262" r="234" fill="{GOLD_DARK}"/>'
            f'<circle cx="256" cy="252" r="226" fill="url(#gold)"/>' + ticks +
            f'<circle cx="256" cy="252" r="176" fill="{GOLD}" stroke="{GOLD_DARK}" stroke-width="10"/>'
            + star(256, 150, 48, fill=GOLD_LIGHT, line=GOLD_DARK) + star(170, 182, 28, fill=GOLD_LIGHT, line=GOLD_DARK) + star(342, 182, 28, fill=GOLD_LIGHT, line=GOLD_DARK)
            + monogram(146, 232, scale=.81, letters=GOLD_DARK, m=GOLD_DARK, sw=26, outline=False)
            + '<ellipse cx="168" cy="132" rx="64" ry="20" fill="#FFFFFF" opacity=".3" transform="rotate(-32 168 132)"/>')


def loader(mark=crest):
    """The splash mark (spec 1): the crest rises in, then a gold arc orbits it while the game checks the
    connection. CSS inside the SVG, so it runs as a plain <img>; still for reduced motion."""
    style = ('<style>'
             '.inside{transform-origin:256px 260px;opacity:0;transform:scale(.86);animation:rise .9s cubic-bezier(.2,.8,.2,1) forwards}'
             '.orbit{transform-origin:256px 260px;animation:spin 1.8s linear infinite}'
             '@keyframes rise{to{opacity:1;transform:scale(1)}}@keyframes spin{to{transform:rotate(360deg)}}'
             '@media (prefers-reduced-motion:reduce){.inside{animation:none;opacity:1;transform:none}.orbit{animation:none}}'
             '</style>')
    return (style
            + f'<g class="inside"><g transform="translate(256 260) scale(.82) translate(-256 -262)">{mark()}</g></g>'
            + f'<g class="orbit"><circle cx="256" cy="260" r="246" fill="none" stroke="{GOLD}" stroke-opacity=".15" stroke-width="6"/>'
            + f'<path d="M256 14 A246 246 0 0 1 469 137" fill="none" stroke="url(#gold)" stroke-width="8" stroke-linecap="round"/></g>')


def rule(x1, x2, y):
    return f'<rect x="{x1}" y="{y}" width="{x2 - x1}" height="4" rx="2" fill="{GOLD}" opacity=".7"/>'


FILES = {
    'emblem.svg': svg(crest()),
    # [SEO] The crest in Arabic, for the Arabic screens, the installed app and the link previews.
    'emblem-ar.svg': svg(crest_ar(), extra=AR_DEFS),
    # the app icon: full bleed for round (maskable) masks, the crest inside the safe circle
    # [SEO] in Arabic, the game's language (the manifest's name is «المدرب الأسطورة»)
    'icon.svg': svg(tile() + f'<g transform="translate(46 40) scale(.82)">{crest_ar()}</g>', extra=AR_DEFS),
    # browser tab: the monogram big on a rounded tile, so it reads at 16 pixels
    'favicon.svg': svg(tile(rx=112)
                       + '<g clip-path="url(#favClip)">' + rays(256, 256) + '<path d="M0 410 L256 460 L512 410 V512 H0 Z" fill="%s"/><path d="M0 410 L256 460 L512 410" fill="none" stroke="%s" stroke-width="12"/></g>' % (EMERALD_DARK, GOLD)
                       + monogram(52, 150, scale=1.5, sw=30),
                       extra='<defs><clipPath id="favClip"><rect width="512" height="512" rx="112"/></clipPath></defs>'),
    'coin.svg': svg(coin()),
    'emblem-loader.svg': svg(loader(), h=520),
    'emblem-loader-ar.svg': svg(loader(crest_ar), h=520, extra=AR_DEFS),
    # the full logo: the crest, the name under it and the line under that
    'logo.svg': svg(
        f'<rect width="1024" height="1060" fill="url(#inkFill)"/><rect width="1024" height="1060" fill="url(#glow)"/>'
        f'<g transform="translate(160 20) scale(1.375)">{crest()}</g>'
        + rule(437, 587, 760) +
        f'<text x="512" y="836" text-anchor="middle" font-family="{SANS}" font-weight="800" font-size="62" letter-spacing="10" fill="{IVORY}">GAME LEGEND</text>'
        f'<text x="512" y="926" text-anchor="middle" font-family="{SANS}" font-weight="800" font-size="62" letter-spacing="26" fill="{GOLD}">MANAGER</text>'
        f'<text x="512" y="1008" text-anchor="middle" font-family="{SANS}" font-weight="700" font-size="46" fill="{IVORY}" opacity=".85" direction="rtl">لعبة المدرب الأسطورة</text>',
        w=1024, h=1060),
    # the logo across, for headers, the site's footer and documents: GLM centred over the full name
    'logo-wide.svg': svg(
        f'<g transform="translate(-40 0)">{crest()}</g>'
        + monogram(679, 110, scale=1.55, sw=24)
        + f'<text x="893" y="372" text-anchor="middle" font-family="{SANS}" font-weight="800" font-size="44" letter-spacing="7" fill="{IVORY}">GAME LEGEND <tspan fill="{GOLD}">MANAGER</tspan></text>'
        + f'<rect x="740" y="400" width="300" height="4" rx="2" fill="{EMERALD}"/>',
        w=1300, h=512),
    # the invite card for WhatsApp and other link previews (1200x630): the crest on the left, the
    # invitation in Arabic on the right (with direction=rtl, "start" is the right edge). The league's
    # own name and owner are the preview's text (og:title, og:description, from InviteController).
    'og-invite.svg': svg(
        f'<rect width="1200" height="630" fill="url(#inkFill)"/>'
        f'<circle cx="330" cy="315" r="300" fill="url(#glow)"/>'
        f'<g transform="translate(90 70) scale(.94)">{crest_ar()}</g>'
        f'<rect x="660" y="120" width="6" height="390" rx="3" fill="{GOLD}" opacity=".5"/>'
        f'<text x="1110" y="215" text-anchor="start" font-family="{SANS}" font-weight="800" font-size="72" fill="{IVORY}" direction="rtl">دعوة لدوري</text>'
        f'<text x="1110" y="305" text-anchor="start" font-family="{SANS}" font-weight="800" font-size="72" fill="{GOLD}" direction="rtl">مع أصحابك</text>'
        f'<text x="1110" y="385" text-anchor="start" font-family="{SANS}" font-weight="700" font-size="34" fill="{IVORY}" opacity=".8" direction="rtl">اختر ناديك وأدِره ضدهم</text>'
        + f'<text x="1110" y="490" text-anchor="start" font-family="{SANS}" font-weight="800" font-size="44" fill="{IVORY}" direction="rtl">المدرب <tspan fill="{GOLD}">الأسطورة</tspan></text>'
        + f'<text x="1110" y="535" text-anchor="start" font-family="{SANS}" font-weight="700" font-size="24" fill="{IVORY}" opacity=".65" direction="rtl">لعبة إدارة كرة القدم مع أصحابك</text>',
        w=1200, h=630, extra=AR_DEFS),
}

if __name__ == '__main__':
    for name, text in FILES.items():
        open(os.path.join(OUT, name), 'w').write(text)
    print('wrote', ', '.join(FILES))
