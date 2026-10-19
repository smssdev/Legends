// @ts-nocheck
// The match feed's art (docs/MATCH_VIEW.md 4.6): broadcast motion graphics in the
// brand's navy and gold, with each team's colour as light. A night pitch in
// perspective, clean player silhouettes with numbers, light trails, flashes and
// particles; crests and line icons for the timeline. Drawing only: which scene
// plays, and with whom, comes from story.ts.

const NS = 'http://www.w3.org/2000/svg'
// The two kits of the match: { kit, ink, trim, name } per side, set by the feed.
let KITS = { home: { kit: '#E8ECF4', ink: '#0A1F42', trim: '#F5B82E', name: '' }, away: { kit: '#D3122F', ink: '#FFFFFF', trim: '#F6C343', name: '' } }
export function setKits(k) { KITS = k }
const K = (s) => KITS[s] ?? KITS.home
const other = (s) => (s === 'home' ? 'away' : 'home')
const lum = (hex) => { const n = parseInt(String(hex).slice(1), 16); return 0.3 * (n >> 16) + 0.59 * ((n >> 8) & 255) + 0.11 * (n & 255) }
const shade = (hex, p) => { const n = parseInt(hex.slice(1), 16), f = (v) => Math.max(0, Math.min(255, v + p)); return '#' + [f(n >> 16), f((n >> 8) & 255), f(n & 255)].map((v) => v.toString(16).padStart(2, '0')).join('') }
// A keeper's kit that stands apart from both teams.
const keeperKit = (side) => (side === 'home' ? '#2BB673' : '#F2994A')

let uid = 0
export const crest = ([c1, c2, t]) => {
  const id = 'cr' + ++uid
  return `<svg viewBox="0 0 64 72"><defs><linearGradient id="${id}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${c1}"/><stop offset="1" stop-color="${shade(c1, -50)}"/></linearGradient></defs><path d="M32 2 L60 10 V36 C60 54 47 65 32 70 C17 65 4 54 4 36 V10 Z" fill="url(#${id})" stroke="${c2}" stroke-width="3"/><path d="M32 9 L53 15 V35 C53 49 43 58 32 62" fill="none" stroke="rgba(255,255,255,.35)" stroke-width="2"/><text x="32" y="42" text-anchor="middle" font-family="Barlow Condensed, Alexandria, sans-serif" font-weight="800" font-size="${t.length > 2 ? 17 : 20}" fill="${lum(c1) > 150 ? '#0A1F42' : '#fff'}">${t}</text></svg>`
}

// Line icons, gold on glass, for the timeline cards.
export const ICON = {
  goal: '<svg viewBox="0 0 24 24" fill="none" stroke="#F5B82E" stroke-width="1.8" stroke-linecap="round"><path d="M3 20V6h18v14"/><path d="M3 10h18M3 14h18M7 6v14M11 6v14M15 6v14M19 6v14" stroke-opacity=".35"/><circle cx="15" cy="15" r="3.2" fill="#fff" stroke="#fff"/></svg>',
  miss: '<svg viewBox="0 0 24 24" fill="none" stroke="#93A3BF" stroke-width="1.8" stroke-linecap="round"><path d="M5 21V5h4"/><circle cx="17" cy="8" r="3" fill="#fff" stroke="#fff"/><path d="M8 18l7-8" stroke-dasharray="2 2.5"/></svg>',
  save: '<svg viewBox="0 0 24 24" fill="none" stroke="#2BB673" stroke-width="1.8" stroke-linejoin="round"><path d="M7 21c-1.6-4-1.6-9 0-13 .4-1 1.8-1 2 0l.5 5 .5-8c.2-1.2 2-1.2 2 0v8l.6-7c.2-1.2 2-1.1 2 .1l-.3 7.4 1-4.3c.3-1.1 2-.9 1.9.3L16.6 16c-.6 3.2-2.6 5-5 5z"/></svg>',
  yellow: '<svg viewBox="0 0 24 24"><rect x="7" y="3" width="10" height="16" rx="2" fill="#FFD400" transform="rotate(10 12 11)"/></svg>',
  red: '<svg viewBox="0 0 24 24"><rect x="7" y="3" width="10" height="16" rx="2" fill="#EF4444" transform="rotate(10 12 11)"/></svg>',
  whistle: '<svg viewBox="0 0 24 24" fill="none" stroke="#F5B82E" stroke-width="1.8"><rect x="3" y="10" width="12" height="9" rx="4.5"/><path d="M13 11h8v4h-6"/><circle cx="8" cy="14.5" r="1.6" fill="#F5B82E"/></svg>',
  coach: '<svg viewBox="0 0 24 24" fill="none" stroke="#F5B82E" stroke-width="1.8" stroke-linecap="round"><rect x="4" y="4" width="16" height="17" rx="2"/><path d="M8 9l3 3M11 9l-3 3M14 17c1-3 2-5 3-7M15 9.5l2 .5.4 2"/></svg>',
  sub: '<svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M8 20V6M4 10l4-4 4 4" stroke="#2BB673"/><path d="M16 4v14M12 14l4 4 4-4" stroke="#EF4444"/></svg>',
  flag: '<svg viewBox="0 0 24 24" fill="none" stroke-width="1.8"><path d="M6 22V3" stroke="#C9D2E1"/><path d="M7 4h11l-2.5 3.5L18 11H7z" fill="#EF4444" stroke="#EF4444"/></svg>',
  corner: '<svg viewBox="0 0 24 24" fill="none" stroke-width="1.8"><path d="M5 21V4" stroke="#C9D2E1"/><path d="M6 4l9 3-9 3z" fill="#F5B82E"/><path d="M5 21a8 8 0 0 1 8-8" stroke="#fff"/></svg>',
  injury: '<svg viewBox="0 0 24 24"><rect x="3" y="3" width="18" height="18" rx="5" fill="#fff"/><path d="M10 7h4v3h3v4h-3v3h-4v-3H7v-4h3z" fill="#EF4444"/></svg>',
  foul: '<svg viewBox="0 0 24 24" fill="none" stroke="#F2994A" stroke-width="1.8" stroke-linecap="round"><path d="M4 17c4 0 6-3 8-6l4 2"/><circle cx="18" cy="7" r="2.5"/><path d="M14 18l4-4M18 18l-4-4" stroke="#EF4444"/></svg>',
  penalty: '<svg viewBox="0 0 24 24" fill="none" stroke="#F5B82E" stroke-width="1.8"><path d="M3 11V4h18v7"/><circle cx="12" cy="17" r="3" fill="#fff" stroke="#fff"/></svg>',
}

// ---------------------------------------------------------------- the motion kit
const el = (tag, a, p) => { const e = document.createElementNS(NS, tag); for (const k in a) e.setAttribute(k, a[k]); p && p.appendChild(e); return e }
const clamp = (v) => Math.max(0, Math.min(1, v))
const seg = (t, a, b) => clamp((t - a) / (b - a))
const ease = (f) => 1 - Math.pow(1 - f, 3)
const lerp = (a, b, f) => a + (b - a) * f
const bez = (p, f) => { const u = 1 - f; return [u * u * p[0][0] + 2 * u * f * p[1][0] + f * f * p[2][0], u * u * p[0][1] + 2 * u * f * p[1][1] + f * f * p[2][1]] }

// The stage: a night pitch in perspective, line art, floodlight haze, the team's light.
function stage(side) {
  const c = K(side).kit, id = 's' + ++uid
  const svg = el('svg', { viewBox: '0 0 640 340' })
  svg.innerHTML = `<defs>
    <linearGradient id="${id}t" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0C3A26"/><stop offset="1" stop-color="#07231A"/></linearGradient>
    <radialGradient id="${id}h" cx=".5" cy="0" r="1"><stop offset="0" stop-color="rgba(255,255,255,.22)"/><stop offset=".6" stop-color="rgba(255,255,255,0)"/></radialGradient>
    <radialGradient id="${id}c" cx=".5" cy=".55" r=".6"><stop offset="0" stop-color="${c}" stop-opacity=".28"/><stop offset="1" stop-color="${c}" stop-opacity="0"/></radialGradient>
    <linearGradient id="gold${id}" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#C08A0C"/><stop offset=".5" stop-color="#FFD36B"/><stop offset="1" stop-color="#C08A0C"/></linearGradient>
    <filter id="glow${id}" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="4" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter>
    <filter id="soft${id}"><feGaussianBlur stdDeviation="10"/></filter>
  </defs>
  <rect width="640" height="340" fill="#040B1C"/>
  <rect width="640" height="150" fill="url(#${id}h)"/>
  <g opacity=".5">${Array.from({ length: 90 }, (_, i) => `<circle cx="${(i * 71) % 640}" cy="${30 + ((i * 37) % 95)}" r="${1 + (i % 3) * 0.6}" fill="${['#2B4F8C', '#3D63A8', c, '#F5B82E'][i % 4]}" opacity="${0.25 + (i % 5) * 0.1}"/>`).join('')}</g>
  <path d="M-40 340 L150 150 L490 150 L680 340 Z" fill="url(#${id}t)"/>
  ${Array.from({ length: 6 }, (_, i) => { const y0 = 150 + Math.pow(i / 6, 1.5) * 190, y1 = 150 + Math.pow((i + 0.5) / 6, 1.5) * 190; return `<path d="M${150 - (y0 - 150)} ${y0} L${490 + (y0 - 150)} ${y0} L${490 + (y1 - 150)} ${y1} L${150 - (y1 - 150)} ${y1} Z" fill="rgba(255,255,255,.025)"/>` }).join('')}
  <g fill="none" stroke="rgba(255,255,255,.55)" stroke-width="1.6"><path d="M150 150 H490"/><path d="M205 150 L170 222 H470 L435 150"/><path d="M262 150 L252 176 H388 L378 150"/><path d="M262 222 Q320 252 378 222"/></g>
  <rect width="640" height="340" fill="url(#${id}c)"/>`
  svg.dataset.id = id
  return svg
}
const ref = (svg, name) => `url(#${name}${svg.dataset.id})`
function goalFrame(svg) {
  const g = el('g', {}, svg), net = el('g', { opacity: 0.55 }, g)
  for (let i = 0; i <= 14; i++) el('path', { d: `M${246 + i * 10.6} 72 L${252 + i * 9.7} 60`, stroke: '#9FB0CF', 'stroke-width': 0.7 }, net)
  for (let i = 0; i <= 14; i++) el('line', { x1: 246 + i * 10.6, y1: 72, x2: 246 + i * 10.6, y2: 150, stroke: '#9FB0CF', 'stroke-width': 0.7 }, net)
  for (let j = 0; j <= 7; j++) el('line', { x1: 246, y1: 72 + j * 11, x2: 394, y2: 72 + j * 11, stroke: '#9FB0CF', 'stroke-width': 0.7 }, net)
  el('path', { d: 'M246 150 V72 H394 V150', fill: 'none', stroke: '#fff', 'stroke-width': 5, 'stroke-linejoin': 'round', filter: ref(svg, 'glow') }, g)
  return { g, net }
}
// A player as a clean silhouette in the kit colour with the shirt number.
function player(svg, kit, no, s = 1) {
  const light = lum(kit) > 150
  const g = el('g', {}, svg)
  g.innerHTML = `<ellipse cx="0" cy="58" rx="20" ry="5" fill="rgba(0,0,0,.45)"/>
    <path d="M-9 24 L-12 54 L-5 55 L0 30 L5 55 L12 54 L9 24 Z" fill="${light ? '#1C2B48' : '#111827'}"/>
    <path d="M-16 -6 Q0 -14 16 -6 L18 26 L-18 26 Z" fill="${kit}"/>
    <path d="M-16 -6 L-24 14 L-18 16 L-12 4 Z M16 -6 L24 14 L18 16 L12 4 Z" fill="${kit}"/>
    <text x="0" y="16" text-anchor="middle" font-family="Barlow Condensed, Alexandria, sans-serif" font-weight="800" font-size="20" fill="${light ? '#0A1F42' : '#fff'}">${no ?? ''}</text>
    <circle cx="0" cy="-20" r="10" fill="#C99A78"/><path d="M-10 -22 Q0 -35 10 -22 Q4 -27 -10 -22 Z" fill="#1B1410"/>`
  return { g, at: (x, y, r = 0, k = s) => g.setAttribute('transform', `translate(${x} ${y}) rotate(${r}) scale(${k})`) }
}
function ball(svg) { const g = el('g', { filter: ref(svg, 'glow') }, svg); g.innerHTML = '<circle r="6.5" fill="#fff"/><path d="M0 -3 L3 -1 L2 3 L-2 3 L-3 -1 Z" fill="#0A1F42"/>'; return g }
function trail(svg, color = '#FFD36B') { return el('path', { d: '', fill: 'none', stroke: color, 'stroke-width': 4, 'stroke-linecap': 'round', opacity: 0.85, filter: ref(svg, 'glow') }, svg) }
const drawTrail = (tr, path, f, op) => { const pts = Array.from({ length: 14 }, (_, i) => bez(path, (f * i) / 13)); tr.setAttribute('d', 'M' + pts.map((q) => q.join(' ')).join(' L')); tr.setAttribute('opacity', op) }
// The headline: a dark band with gold rules sliding in, the word over it.
function title(svg, text, color) {
  const band = el('rect', { x: 0, y: 128, width: 640, height: 84, fill: 'rgba(4,11,28,.72)', opacity: 0 }, svg)
  const r1 = el('rect', { x: 0, y: 128, width: 640, height: 2, fill: ref(svg, 'gold'), opacity: 0 }, svg), r2 = el('rect', { x: 0, y: 210, width: 640, height: 2, fill: ref(svg, 'gold'), opacity: 0 }, svg)
  const t = el('text', { x: 320, y: 172, 'text-anchor': 'middle', 'dominant-baseline': 'middle', 'font-family': 'Alexandria, sans-serif', 'font-weight': 900, 'font-size': 64, fill: color ?? ref(svg, 'gold'), opacity: 0 }, svg)
  t.textContent = text
  return (f) => { const e = ease(f); band.setAttribute('opacity', f); r1.setAttribute('opacity', f); r2.setAttribute('opacity', f); r1.setAttribute('transform', `translate(${(1 - e) * -640} 0)`); r2.setAttribute('transform', `translate(${(1 - e) * 640} 0)`); t.setAttribute('opacity', f); t.setAttribute('transform', `translate(320 172) scale(${0.8 + 0.2 * e}) translate(-320 -172)`) }
}
function bigNumber(svg, no, kit) {
  const t = el('text', { x: 520, y: 300, 'text-anchor': 'middle', 'font-family': 'Barlow Condensed, Alexandria, sans-serif', 'font-weight': 800, 'font-style': 'italic', 'font-size': 260, fill: 'none', stroke: kit, 'stroke-width': 2, opacity: 0 }, svg)
  t.textContent = no ?? ''
  return (f) => { t.setAttribute('opacity', f * 0.35); t.setAttribute('transform', `translate(${(1 - ease(f)) * 60} 0)`) }
}
function flash(svg) { const r = el('rect', { width: 640, height: 340, fill: '#FFF6DA', opacity: 0 }, svg); return (f) => r.setAttribute('opacity', f) }
function sparks(svg, n) { return Array.from({ length: n }, (_, i) => ({ e: el('circle', { r: 1.5 + (i % 3), fill: i % 3 ? '#FFD36B' : '#fff', opacity: 0 }, svg), a: (i / n) * 6.28 + (i % 4) * 0.3, v: 80 + (i % 7) * 30 })) }
const burst = (ps, x, y, f) => ps.forEach((p) => { p.e.setAttribute('cx', x + Math.cos(p.a) * p.v * f); p.e.setAttribute('cy', y + Math.sin(p.a) * p.v * f * 0.7 + f * f * 40); p.e.setAttribute('opacity', f > 0 && f < 1 ? 1 - f : 0) })
const run = (t, a, b) => Math.sin(t * 12) * 4 * (t > a && t < b ? 1 : 0)

// A shot at goal: the run-up, the strike, the flight with its light trail; the keeper dives.
function shot(svg, e, target, { dive = 1, keyT = 1.75, from = [300, 300], ctrl = [250, 170] } = {}) {
  const kp = player(svg, keeperKit(other(e.side)), 1, 0.85), sh = player(svg, K(e.side).kit, e.no ?? e.shooterNo, 1.25), b = ball(svg), tr = trail(svg)
  const path = [from, ctrl, target], t0 = keyT - 0.6
  return (t) => {
    sh.at(lerp(250, from[0], ease(seg(t, 0, t0))), 268, t > t0 ? -8 : run(t, 0, t0))
    const f = ease(seg(t, t0, keyT))
    const p = t < t0 ? [lerp(270, from[0], seg(t, 0, t0)), 318] : bez(path, f)
    b.setAttribute('transform', `translate(${p[0]} ${p[1]}) scale(${1 - f * 0.3})`)
    if (t > t0) drawTrail(tr, path, f, 0.9 * (1 - seg(t, keyT + 0.15, keyT + 0.9)))
    const dv = ease(seg(t, t0 + 0.2, keyT + 0.05))
    kp.at(lerp(320, 320 - 38 * dive, dv), lerp(146, 138, dv), -70 * dive * dv)
    return { b, p }
  }
}

// ---------------------------------------------------------------- scenes: one per kind of moment
export const SCENES = {
  goal(e) {
    const svg = stage(e.side), G = goalFrame(svg), num = bigNumber(svg, e.no, K(e.side).kit)
    const go = shot(svg, e, [372, 92]), fl = flash(svg), tt = title(svg, 'هدف!'), ps = sparks(svg, 40)
    return { dur: 5.2, svg, update(t) {
      num(seg(t, 2.3, 3)); go(t)
      const bl = seg(t, 1.75, 1.95) * (1 - seg(t, 2.1, 2.8)); G.net.setAttribute('transform', `translate(${bl * 6} ${-bl * 8})`)
      fl(seg(t, 1.74, 1.8) * (1 - seg(t, 1.8, 2.1)) * 0.8); burst(ps, 372, 92, seg(t, 1.78, 3)); tt(seg(t, 1.9, 2.3))
    } }
  },
  save(e) {
    const svg = stage(e.side), G = goalFrame(svg)
    const go = shot(svg, e, [282, 104], { dive: 0.9, keyT: 1.6 })
    const ring = el('circle', { r: 30, fill: 'none', stroke: '#2BB673', 'stroke-width': 3, opacity: 0, filter: ref(svg, 'glow') }, svg)
    const tt = title(svg, 'تصدٍّ رائع', '#2BB673')
    return { dur: 4.6, svg, update(t) {
      const { b } = go(Math.min(t, 1.6))
      if (t > 1.6) { const k = ease(seg(t, 1.6, 2.4)); b.setAttribute('transform', `translate(${282 - k * 140} ${104 - k * 30 + k * k * 120})`) }
      const s = seg(t, 1.58, 2.2); ring.setAttribute('transform', `translate(282 104) scale(${0.4 + s * 1.6})`); ring.setAttribute('opacity', s > 0 ? 1 - s : 0)
      tt(seg(t, 1.8, 2.2))
    } }
  },
  miss(e) {
    // Wide of the post, over the bar, or off the woodwork (e.how).
    const svg = stage(e.side), G = goalFrame(svg)
    const end = e.how === 'post' ? [394, 100] : e.how === 'over' ? [330, 46] : [430, 120]
    const go = shot(svg, e, end, { dive: 0.4, keyT: 1.75 })
    const tt = title(svg, e.how === 'post' ? 'القائم!' : e.how === 'over' ? 'فوق العارضة' : 'بجانب القائم', '#C9D2E1')
    return { dur: 4.2, svg, update(t) {
      const { b } = go(Math.min(t, 1.75))
      if (t > 1.75) { const k = ease(seg(t, 1.75, 2.5)); b.setAttribute('transform', e.how === 'post' ? `translate(${394 - k * 90} ${100 + k * 150})` : `translate(${end[0] + k * 60} ${end[1] - k * 20})`) }
      if (e.how === 'post') G.g.setAttribute('transform', `translate(${Math.sin(t * 60) * 2 * seg(t, 1.72, 1.8) * (1 - seg(t, 1.85, 2.2))} 0)`)
      tt(seg(t, 1.9, 2.3))
    } }
  },
  blocked(e) {
    const svg = stage(e.side), G = goalFrame(svg)
    const d = player(svg, K(other(e.side)).kit, e.defNo, 1.15), sh = player(svg, K(e.side).kit, e.no, 1.25), b = ball(svg)
    const ring = el('circle', { r: 26, fill: 'none', stroke: '#7FB4FF', 'stroke-width': 3, opacity: 0, filter: ref(svg, 'glow') }, svg)
    const tt = title(svg, 'صدّها الدفاع', '#7FB4FF')
    return { dur: 4, svg, update(t) {
      sh.at(lerp(250, 300, ease(seg(t, 0, 1.1))), 268, t > 1.1 ? -8 : run(t, 0, 1.1))
      const sl = ease(seg(t, 0.9, 1.3)); d.at(lerp(380, 322, sl), lerp(230, 236, sl), -55 * sl)
      const p = t < 1.15 ? [lerp(270, 300, seg(t, 0, 1.1)), 318] : t < 1.35 ? [lerp(300, 322, seg(t, 1.15, 1.35)), lerp(300, 250, seg(t, 1.15, 1.35))] : bez([[322, 250], [250, 170], [150, 260]], ease(seg(t, 1.35, 2.2)))
      b.setAttribute('transform', `translate(${p[0]} ${p[1]})`)
      const s = seg(t, 1.32, 1.9); ring.setAttribute('transform', `translate(322 250) scale(${0.4 + s * 1.5})`); ring.setAttribute('opacity', s > 0 ? 1 - s : 0)
      tt(seg(t, 1.5, 1.9))
    } }
  },
  penalty(e) {
    const svg = stage(e.side), G = goalFrame(svg)
    el('ellipse', { cx: 320, cy: 250, rx: 9, ry: 3, fill: '#fff', opacity: 0.8 }, svg)
    const kp = player(svg, keeperKit(other(e.side)), 1, 0.85), tk = player(svg, K(e.side).kit, e.no, 1.35), b = ball(svg), tr = trail(svg)
    const aim = el('g', { opacity: 0 }, svg); aim.innerHTML = '<circle r="18" fill="none" stroke="#FFD36B" stroke-width="2"/><circle r="4" fill="#FFD36B"/><path d="M-26 0H-12M12 0H26M0 -26V-12M0 12V26" stroke="#FFD36B" stroke-width="2"/>'
    const hush = el('text', { x: 320, y: 44, 'text-anchor': 'middle', 'font-family': 'IBM Plex Sans Arabic, sans-serif', 'font-weight': 600, 'font-size': 16, fill: '#C9D2E1', opacity: 0 }, svg); hush.textContent = 'صمت في المدرجات...'
    const tt = title(svg, e.scored ? 'هدف!' : 'تصدٍّ!', e.scored ? undefined : '#2BB673'), ps = sparks(svg, 30), fl = flash(svg)
    const target = e.scored ? [268, 92] : [282, 112], path = [[320, 248], [300, 170], target]
    return { dur: 5.6, svg, update(t) {
      hush.setAttribute('opacity', seg(t, 0.2, 0.6) * (1 - seg(t, 2, 2.3)))
      aim.setAttribute('opacity', seg(t, 0.8, 1.2) * (1 - seg(t, 2.3, 2.5))); aim.setAttribute('transform', `translate(${268 + Math.sin(t * 2.2) * 40} ${100 + Math.cos(t * 1.7) * 18})`)
      tk.at(lerp(372, 332, ease(seg(t, 1.4, 2.4))), 290, t > 2.4 ? -10 : 0)
      const f = ease(seg(t, 2.45, 2.85))
      let p = t < 2.45 ? [320, 248] : bez(path, f)
      if (t > 2.85 && !e.scored) { const k = seg(t, 2.85, 3.6); p = [target[0] - k * 120, target[1] + k * 120] }
      b.setAttribute('transform', `translate(${p[0]} ${p[1]}) scale(${1 - f * 0.3})`)
      if (t > 2.45) drawTrail(tr, path, f, 0.9 * (1 - seg(t, 3, 3.6)))
      const dv = ease(seg(t, 2.5, 2.95)), dir = e.scored ? 1 : -1.2
      kp.at(320 + Math.sin(t * 5) * 4 * (1 - seg(t, 2.4, 2.5)) + dir * 30 * dv, lerp(146, 134, dv), (e.scored ? 70 : -70) * dv)
      if (e.scored) { const bl = seg(t, 2.85, 3) * (1 - seg(t, 3.1, 3.7)); G.net.setAttribute('transform', `translate(${-bl * 6} ${-bl * 8})`); fl(seg(t, 2.84, 2.9) * (1 - seg(t, 2.9, 3.2)) * 0.8) }
      burst(ps, target[0], target[1], seg(t, 2.85, 4)); tt(seg(t, 3, 3.4))
    } }
  },
  freekick(e) {
    const svg = stage(e.side), G = goalFrame(svg)
    const wall = [0, 1, 2, 3].map(() => player(svg, K(other(e.side)).kit, '', 0.95))
    const kp = player(svg, keeperKit(other(e.side)), 1, 0.85), tk = player(svg, K(e.side).kit, e.no, 1.3), b = ball(svg), tr = trail(svg)
    const target = e.scored ? [384, 86] : e.saved ? [374, 96] : [404, 52], path = [[250, 290], [300, 40], target]
    const tt = title(svg, e.scored ? 'هدف!' : e.saved ? 'تصدٍّ!' : 'فوق العارضة', e.scored ? undefined : e.saved ? '#2BB673' : '#C9D2E1'), ps = sparks(svg, 30), fl = flash(svg)
    return { dur: 5.2, svg, update(t) {
      wall.forEach((w, i) => w.at(290 + i * 22, 210 - (t > 1.9 && t < 2.4 ? 10 : 0), 0, 0.95))
      tk.at(lerp(200, 240, ease(seg(t, 0.6, 1.8))), 290, t > 1.8 ? -10 : run(t, 0.6, 1.8))
      const f = ease(seg(t, 1.85, 2.65))
      let p = t < 1.85 ? [250, 292] : bez(path, f)
      if (t > 2.65 && !e.scored) { const k = seg(t, 2.65, 3.3); p = [target[0] + k * 40, target[1] + (e.saved ? k * 120 : -k * 20)] }
      b.setAttribute('transform', `translate(${p[0]} ${p[1]}) scale(${1 - f * 0.35})`)
      if (t > 1.85) drawTrail(tr, path, f, 0.9 * (1 - seg(t, 2.8, 3.4)))
      const dv = ease(seg(t, 2.1, 2.65)); kp.at(lerp(320, 360, dv), lerp(146, 130, dv), 70 * dv)
      if (e.scored) { const bl = seg(t, 2.65, 2.8) * (1 - seg(t, 2.9, 3.5)); G.net.setAttribute('transform', `translate(${bl * 6} ${-bl * 8})`); fl(seg(t, 2.64, 2.7) * (1 - seg(t, 2.7, 3)) * 0.8); burst(ps, target[0], target[1], seg(t, 2.66, 3.8)) }
      tt(seg(t, 2.8, 3.2))
    } }
  },
  card(e) {
    const svg = stage(e.side), red = e.type === 'red', col = red ? '#EF4444' : '#FFD400'
    const pl = player(svg, K(e.side).kit, e.no, 1.6)
    const glow = el('circle', { cx: 430, cy: 150, r: 90, fill: col, opacity: 0, filter: ref(svg, 'soft') }, svg)
    const card = el('g', {}, svg); card.innerHTML = `<rect x="-38" y="-54" width="76" height="108" rx="8" fill="${col}"/><path d="M-30 -46 L30 -46" stroke="rgba(255,255,255,.5)" stroke-width="3"/>`
    const tt = title(svg, red ? 'طرد!' : 'إنذار', col)
    return { dur: 4.4, svg, update(t) {
      pl.at(230, 250, t > 1.4 ? -6 : 0)
      const f = ease(seg(t, 0.4, 1.1))
      card.setAttribute('transform', `translate(430 ${lerp(360, 150, f)}) rotate(${lerp(-35, 8, f)}) scale(${Math.max(0.05, Math.cos((1 - f) * 1.4))} 1)`)
      glow.setAttribute('opacity', 0.45 * seg(t, 1, 1.4))
      tt(seg(t, 1.3, 1.7))
    } }
  },
  offside(e) {
    const svg = stage(e.side)
    const defs = [0, 1, 2, 3].map(() => player(svg, K(other(e.side)).kit, '', 0.9)), rn = player(svg, K(e.side).kit, e.no, 1.1)
    const line = el('line', { x1: 120, y1: 214, x2: 520, y2: 214, stroke: '#EF4444', 'stroke-width': 3, 'stroke-dasharray': '10 7', opacity: 0, filter: ref(svg, 'glow') }, svg)
    const fr = el('rect', { width: 640, height: 340, fill: 'rgba(30,70,160,.18)', opacity: 0 }, svg)
    const flag = el('g', { opacity: 0 }, svg); flag.innerHTML = '<rect x="-1.5" y="0" width="3" height="46" fill="#DDE3F0"/><path d="M1.5 2 H30 L24 12 L30 22 H1.5 Z" fill="#EF4444"/>'
    const tt = title(svg, 'تسلل', '#EF4444')
    return { dur: 4.2, svg, update(t) {
      const fz = t > 1.5 && t < 2.6
      defs.forEach((d, i) => d.at(200 + i * 80, 220, 0, 0.9))
      rn.at(lerp(330, 300, ease(seg(t, 0, 1.4))), lerp(260, 196, ease(seg(t, 0, 1.4))), 0, 1.1)
      line.setAttribute('opacity', seg(t, 1.4, 1.7)); fr.setAttribute('opacity', fz ? 1 : 0)
      flag.setAttribute('opacity', seg(t, 1.2, 1.4)); flag.setAttribute('transform', `translate(560 ${lerp(250, 170, ease(seg(t, 1.2, 1.5)))}) rotate(${Math.sin(t * 9) * 8})`)
      tt(seg(t, 2.4, 2.8))
    } }
  },
  corner(e) {
    const svg = stage(e.side), G = goalFrame(svg)
    el('path', { d: 'M600 300 V250', stroke: '#DDE3F0', 'stroke-width': 3 }, svg); el('path', { d: 'M601 250 L624 257 L601 264 Z', fill: '#F5B82E' }, svg)
    const df = player(svg, K(other(e.side)).kit, '', 1), hd = player(svg, K(e.side).kit, e.no, 1.15), kp = player(svg, keeperKit(other(e.side)), 1, 0.85), b = ball(svg), tr = trail(svg)
    const path = [[590, 296], [500, 40], [330, 160]]
    const tt = title(svg, e.claim ? 'الحارس يمسكها' : 'رأسية!', e.claim ? '#2BB673' : '#C9D2E1')
    return { dur: 4.6, svg, update(t) {
      const f = ease(seg(t, 0.6, 1.7)), jump = Math.sin(clamp(seg(t, 1.4, 2.1)) * Math.PI)
      hd.at(330, 186 - jump * 22, 0, 1.15); df.at(352, 190 - jump * 12, 0, 1)
      const kj = e.claim ? Math.sin(clamp(seg(t, 1.4, 2)) * Math.PI) : 0; kp.at(lerp(320, 332, kj), 146 - kj * 26, 0, 0.85)
      const p = t < 0.6 ? [590, 296] : t < 1.7 ? bez(path, f) : e.claim ? [332, 120] : bez([[330, 160], [330, 60], [330, 40]], ease(seg(t, 1.7, 2.3)))
      b.setAttribute('transform', `translate(${p[0]} ${p[1]})`)
      if (t > 0.6) drawTrail(tr, path, f, 0.8 * (1 - seg(t, 1.9, 2.5)))
      tt(seg(t, 2.2, 2.6))
    } }
  },
  sub(e) {
    const svg = stage(e.side), k = K(e.side).kit
    const out = player(svg, k, e.outNo, 1.5), inn = player(svg, k, e.inNo, 1.5)
    const board = el('g', {}, svg)
    board.innerHTML = `<rect x="-62" y="-44" width="124" height="88" rx="10" fill="#071733" stroke="rgba(245,184,46,.6)" stroke-width="2"/><text x="-26" y="-2" text-anchor="middle" font-family="Barlow Condensed, sans-serif" font-weight="800" font-size="36" fill="#EF4444">${e.outNo ?? ''}</text><text x="26" y="-2" text-anchor="middle" font-family="Barlow Condensed, sans-serif" font-weight="800" font-size="36" fill="#2BB673">${e.inNo ?? ''}</text><path d="M-26 12 V32 M-32 26 L-26 34 L-20 26" stroke="#EF4444" stroke-width="3" fill="none"/><path d="M26 34 V14 M20 20 L26 12 L32 20" stroke="#2BB673" stroke-width="3" fill="none"/>`
    return { dur: 4.2, svg, update(t) {
      board.setAttribute('transform', `translate(320 ${lerp(400, 110, ease(seg(t, 0, 0.6)))})`)
      const w = Math.sin(t * 10) * 3
      out.at(lerp(250, 60, ease(seg(t, 0.8, 3))), 270, w); inn.at(lerp(600, 400, ease(seg(t, 0.8, 3))), 270, -w)
    } }
  },
  injury(e) {
    const svg = stage(e.side), pl = player(svg, K(e.side).kit, e.no, 1.4)
    const med = el('g', {}, svg); med.innerHTML = '<rect x="-30" y="-30" width="60" height="60" rx="14" fill="#fff"/><path d="M-9 -20 H9 V-9 H20 V9 H9 V20 H-9 V9 H-20 V-9 H-9 Z" fill="#EF4444"/>'
    const halo = el('circle', { cx: 440, cy: 120, r: 50, fill: '#EF4444', opacity: 0.2, filter: ref(svg, 'soft') }, svg)
    return { dur: 3.8, svg, update(t) {
      pl.at(300, 270, 82)
      med.setAttribute('transform', `translate(440 120) scale(${0.9 + 0.1 * Math.sin(t * 6)})`); halo.setAttribute('opacity', 0.15 + 0.1 * Math.sin(t * 6))
    } }
  },
  coach(e) {
    // The touchline tablet: the shape and the instruction's arrows, drawn live.
    const svg = stage(e.side), kit = K(e.side).kit
    const tab = el('g', {}, svg)
    tab.innerHTML = `<rect x="-150" y="-100" width="300" height="200" rx="16" fill="#071733" stroke="rgba(245,184,46,.6)" stroke-width="2"/><rect x="-136" y="-86" width="272" height="172" rx="8" fill="#0C3A26"/><g stroke="rgba(255,255,255,.45)" fill="none" stroke-width="1.3"><path d="M0 -86 V86"/><circle r="24"/><rect x="-136" y="-40" width="40" height="80"/><rect x="96" y="-40" width="40" height="80"/></g>`
    const dots = [[-110, 0], [-70, -50], [-70, -17], [-70, 17], [-70, 50], [-20, -35], [-20, 0], [-20, 35], [35, -50], [45, 0], [35, 50]].map(([x, y]) => { const d = el('circle', { r: 8, fill: kit, stroke: '#071733', 'stroke-width': 2 }, tab); d.dataset.x = x; d.dataset.y = y; return d })
    const ar = el('g', { fill: 'none', stroke: '#FFD36B', 'stroke-width': 3, 'stroke-linecap': 'round', filter: ref(svg, 'glow') }, tab)
    const A = [[-20, -35, 30, -60], [-20, 35, 30, 60], [-70, -50, -30, -75], [-70, 50, -30, 75]].map(([a, b, c, d]) => el('path', { d: `M${a} ${b} L${c} ${d}`, 'stroke-dasharray': 80, 'stroke-dashoffset': 80 }, ar))
    const chip = el('g', { opacity: 0 }, svg); chip.innerHTML = `<rect x="-150" y="-20" width="300" height="40" rx="20" fill="${ref(svg, 'gold')}"/><text y="7" text-anchor="middle" font-family="Alexandria, sans-serif" font-weight="800" font-size="18" fill="#071733">${e.tactic ?? ''}</text>`
    return { dur: 4.6, svg, update(t) {
      tab.setAttribute('transform', `translate(320 ${lerp(380, 158, ease(seg(t, 0, 0.6)))}) scale(.9)`)
      const push = ease(seg(t, 1, 2)); dots.forEach((d) => { d.setAttribute('cx', +d.dataset.x + (+d.dataset.x > -100 ? push * 26 : 0)); d.setAttribute('cy', d.dataset.y) })
      A.forEach((a, i) => a.setAttribute('stroke-dashoffset', 80 * (1 - ease(seg(t, 0.9 + i * 0.15, 1.6 + i * 0.15)))))
      chip.setAttribute('opacity', seg(t, 1.6, 2)); chip.setAttribute('transform', `translate(320 306) scale(${0.85 + 0.15 * ease(seg(t, 1.6, 2))})`)
    } }
  },
  whistle(e) {
    // Half time and full time: the score and the numbers of the match so far.
    const svg = stage('home'), g = el('g', {}, svg)
    el('rect', { x: 110, y: 26, width: 420, height: 296, rx: 18, fill: 'rgba(4,11,28,.9)', stroke: 'rgba(245,184,46,.35)' }, g)
    el('text', { x: 320, y: 66, 'text-anchor': 'middle', 'font-family': 'Alexandria, sans-serif', 'font-weight': 900, 'font-size': 28, fill: ref(svg, 'gold') }, g).textContent = e.big ?? ''
    el('text', { x: 320, y: 108, 'text-anchor': 'middle', 'font-family': 'Barlow Condensed, sans-serif', 'font-weight': 800, 'font-size': 42, fill: '#fff', direction: 'ltr' }, g).textContent = e.score ?? ''
    const rows = (e.stats ?? []).slice(0, 4)
    const bars = rows.map(([label, h, a], i) => {
      const y = 146 + i * 44
      el('text', { x: 320, y: y - 6, 'text-anchor': 'middle', 'font-family': 'IBM Plex Sans Arabic, sans-serif', 'font-size': 13, fill: '#93A3BF' }, g).textContent = label
      el('text', { x: 500, y: y + 12, 'text-anchor': 'middle', 'font-family': 'Barlow Condensed, sans-serif', 'font-weight': 700, 'font-size': 22, fill: '#fff' }, g).textContent = h
      el('text', { x: 140, y: y + 12, 'text-anchor': 'middle', 'font-family': 'Barlow Condensed, sans-serif', 'font-weight': 700, 'font-size': 22, fill: '#fff' }, g).textContent = a
      el('rect', { x: 170, y: y + 3, width: 300, height: 8, rx: 4, fill: 'rgba(255,255,255,.08)' }, g)
      return { hb: el('rect', { x: 320, y: y + 3, width: 0, height: 8, rx: 4, fill: K('home').kit }, g), ab: el('rect', { x: 320, y: y + 3, width: 0, height: 8, rx: 4, fill: K('away').kit }, g), h, a }
    })
    return { dur: 3.6, svg, update(t) {
      g.setAttribute('opacity', seg(t, 0, 0.4))
      // Home on the right, as on the scoreboard.
      bars.forEach((b, i) => { const f = ease(seg(t, 0.4 + i * 0.15, 1.2 + i * 0.15)), tot = b.h + b.a || 1, wh = (150 * b.h / tot) * f, wa = (150 * b.a / tot) * f; b.hb.setAttribute('width', wh); b.ab.setAttribute('x', 320 - wa); b.ab.setAttribute('width', wa) })
    } }
  },
  board(e) {
    const svg = stage('home'), bd = el('g', {}, svg)
    bd.innerHTML = `<rect x="-90" y="-56" width="180" height="112" rx="14" fill="#071733" stroke="rgba(245,184,46,.6)" stroke-width="2"/><text y="-22" text-anchor="middle" font-family="IBM Plex Sans Arabic, sans-serif" font-size="15" fill="#93A3BF">الوقت بدل الضائع</text><text y="34" text-anchor="middle" font-family="Barlow Condensed, sans-serif" font-weight="800" font-size="60" fill="#2BB673">+${e.plus ?? ''}</text>`
    return { dur: 3, svg, update(t) { bd.setAttribute('transform', `translate(320 ${lerp(400, 170, ease(seg(t, 0.1, 0.7)))}) scale(${1 + 0.03 * Math.sin(t * 8)})`) } }
  },
}
