"""Original line-art characters for the workbook, drawn in a 100x100 box.

Every function returns an SVG <g>. `s` is the scale (px per unit) so the
outline keeps the same thick weight at any size. `c` is an optional colour
dict for the cover; the interior always uses white fills.
"""

INK = "#1a1a1a"
W_MAIN = 5.2   # main outline, page px (~3.9pt)
W_DET = 3.6    # inner details


def _g(body, x, y, s, flip=False):
    if flip:
        return f'<g transform="translate({x + 100 * s},{y}) scale({-s},{s})">{body}</g>'
    return f'<g transform="translate({x},{y}) scale({s})">{body}</g>'


def _st(s, w=W_MAIN):
    if w == W_DET:
        w = w * max(0.62, min(1, s))
    return f'stroke="{INK}" stroke-width="{w / s:.3f}" stroke-linejoin="round" stroke-linecap="round"'


def eye(cx, cy, r, s):
    return (f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{INK}"/>'
            f'<circle cx="{cx + r * 0.35}" cy="{cy - r * 0.38}" r="{r * 0.36}" fill="#fff"/>')


def duck(x, y, s, c=None, flip=False):
    c = c or {}
    b, k = c.get("body", "#fff"), c.get("beak", "#fff")
    M, D = _st(s), _st(s, W_DET)
    body = f"""
    <path d="M70,62 Q92,40 96,50 Q96,64 84,72 Z" fill="{b}" {M}/>
    <path d="M40,96 L40,88 M58,96 L58,88" fill="none" {M}/>
    <path d="M33,97 Q40,92 47,97 Z M51,97 Q58,92 65,97 Z" fill="{k}" {D}/>
    <ellipse cx="54" cy="70" rx="32" ry="20" fill="{b}" {M}/>
    <path d="M4,44 Q2,36 12,36 L22,38 L22,48 L12,50 Q4,50 4,44 Z" fill="{k}" {M}/>
    <circle cx="34" cy="38" r="19" fill="{b}" {M}/>
    <path d="M50,66 Q64,54 76,64 Q66,80 50,66 Z" fill="{b}" {D}/>
    {eye(30, 35, 3.6, s)}
    {'<ellipse cx="24" cy="48" rx="4.5" ry="2.6" fill="%s"/>' % c['blush'] if c.get('blush') else ''}
    <path d="M34,20 Q36,12 42,14" fill="none" {D}/>
    """
    return _g(body, x, y, s, flip)


def fish(x, y, s, c=None, flip=False):
    c = c or {}
    b, f2 = c.get("body", "#fff"), c.get("fin", "#fff")
    M, D = _st(s), _st(s, W_DET)
    body = f"""
    <path d="M70,50 L95,32 Q90,50 95,68 Z" fill="{f2}" {M}/>
    <path d="M36,33 Q48,14 64,34 Z" fill="{f2}" {M}/>
    <ellipse cx="45" cy="50" rx="31" ry="21" fill="{b}" {M}/>
    <path d="M37,38 Q32,50 37,62" fill="none" {D}/>
    <path d="M50,42 Q56,48 50,54 M60,40 Q66,48 60,56 M50,54 Q56,60 50,64" fill="none" {D}/>
    {eye(25, 46, 4, s)}
    <path d="M17,56 Q21,60 26,57" fill="none" {D}/>
    """
    return _g(body, x, y, s, flip)


def butterfly(x, y, s, c=None):
    c = c or {}
    w1, w2, b = c.get("wing", "#fff"), c.get("wing2", "#fff"), c.get("body", "#fff")
    M, D = _st(s), _st(s, W_DET)
    body = f"""
    <path d="M46,18 Q40,6 32,6 M54,18 Q60,6 68,6" fill="none" {D}/>
    <circle cx="31" cy="6" r="3" fill="{INK}"/><circle cx="69" cy="6" r="3" fill="{INK}"/>
    <ellipse cx="31" cy="38" rx="21" ry="17" transform="rotate(-25 31 38)" fill="{w1}" {M}/>
    <ellipse cx="69" cy="38" rx="21" ry="17" transform="rotate(25 69 38)" fill="{w1}" {M}/>
    <ellipse cx="35" cy="68" rx="15" ry="13" transform="rotate(25 35 68)" fill="{w2}" {M}/>
    <ellipse cx="65" cy="68" rx="15" ry="13" transform="rotate(-25 65 68)" fill="{w2}" {M}/>
    <circle cx="27" cy="36" r="7" fill="{w2}" {D}/><circle cx="73" cy="36" r="7" fill="{w2}" {D}/>
    <circle cx="33" cy="70" r="4.5" fill="{w1}" {D}/><circle cx="67" cy="70" r="4.5" fill="{w1}" {D}/>
    <ellipse cx="50" cy="56" rx="6.5" ry="26" fill="{b}" {M}/>
    <circle cx="50" cy="24" r="10" fill="{b}" {M}/>
    {eye(46.5, 23, 2.2, s)}{eye(53.5, 23, 2.2, s)}
    <path d="M47,28 Q50,31 53,28" fill="none" {D}/>
    """
    return _g(body, x, y, s)


def owl(x, y, s, c=None, numbers=False):
    """Owl on a branch. Regions: 1 body+branch, 2 belly+wings, 3 eyes+feet, 4 leaves."""
    c = c or {}
    o1, o2, o3, o4 = (c.get(k, "#fff") for k in ("body", "belly", "eyes", "leaf"))
    M, D = _st(s), _st(s, W_DET)
    n = ""
    if numbers:
        def t(cx, cy, v, size=7):
            return (f'<text x="{cx}" y="{cy}" font-family="Fredoka" font-weight="600" '
                    f'font-size="{size}" text-anchor="middle" dominant-baseline="central" fill="{INK}">{v}</text>')
        n = (t(27, 15, 1, 6) + t(73, 15, 1, 6) + t(50, 69, 2) + t(13, 64, 2) + t(87, 64, 2) + t(30, 33, 3, 5.5) + t(70, 33, 3, 5.5)
             + t(14, 95, 1, 6) + t(86, 95, 1, 6) + t(5, 82, 4, 5.5) + t(95, 82, 4, 5.5) + t(39, 89, 3, 4.5) + t(61, 89, 3, 4.5))
    body = f"""
    <path d="M-2,79 Q-6,72 4,70 Q12,76 10,86 Q2,88 -2,79 Z" fill="{o4}" {D}/>
    <path d="M102,79 Q106,72 96,70 Q88,76 90,86 Q98,88 102,79 Z" fill="{o4}" {D}/>
    <path d="M18,24 L22,2 L36,16 Q50,12 64,16 L78,2 L82,24 Q94,54 84,78 Q70,92 50,92 Q30,92 16,78 Q6,54 18,24 Z" fill="{o1}" {M}/>
    <path d="M18,46 Q4,60 12,82 Q24,74 24,56 Q23,50 18,46 Z" fill="{o2}" {M}/>
    <path d="M82,46 Q96,60 88,82 Q76,74 76,56 Q77,50 82,46 Z" fill="{o2}" {M}/>
    <ellipse cx="50" cy="68" rx="20" ry="20" fill="{o2}" {M}/>
    <path d="M42,62 l4,4 l4,-4 l4,4 l4,-4 M44,74 l3,3 l3,-3 l3,3 l3,-3" fill="none" {D}/>
    <circle cx="35" cy="38" r="13" fill="{o3}" {M}/>
    <circle cx="65" cy="38" r="13" fill="{o3}" {M}/>
    {eye(38 if numbers else 35, 43 if numbers else 39, 4 if numbers else 5, s)}{eye(62 if numbers else 65, 43 if numbers else 39, 4 if numbers else 5, s)}
    <path d="M45,48 L55,48 L50,57 Z" fill="{INK}" {D}/>
    <rect x="0" y="86" width="100" height="12" rx="6" fill="{o1}" {M}/>
    <path d="M32,92 Q34,84 39,85 Q44,84 46,92 Z M54,92 Q56,84 61,85 Q66,84 68,92 Z" fill="{o3}" {D}/>
    {n}
    """
    return _g(body, x, y, s)


def flower(x, y, s, c=None):
    c = c or {}
    p, m = c.get("petal", "#fff"), c.get("mid", "#fff")
    M, D = _st(s), _st(s, W_DET)
    import math
    petals = "".join(
        f'<circle cx="{50 + 15 * math.cos(a * math.pi / 3):.1f}" cy="{32 + 15 * math.sin(a * math.pi / 3):.1f}" r="11" fill="{p}" {M}/>'
        for a in range(6))
    body = f"""
    <path d="M50,44 L50,98" fill="none" {M}/>
    <path d="M50,80 Q34,64 26,74 Q36,88 50,80 Z" fill="{c.get('leaf', '#fff')}" {D}/>
    {petals}
    <circle cx="50" cy="32" r="10" fill="{m}" {M}/>
    """
    return _g(body, x, y, s)
