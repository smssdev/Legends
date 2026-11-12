// @ts-nocheck
// [Sprint 57 W4] The cartoon effects (Sprint 42): shakes, speed lines, confetti, the boom, the dust, the tackle.
import { ball, player } from './figures'
import { SMOOTH, ease, el, esc, lerp, officialKit, sa, seg } from './kit'
import { persp, ref } from './stage'

// ---------------------------------------------------------------- [Sprint 42] cartoon effects
// The owner's (2026-11-03): the clock stops and a cartoon tells the moment, with a screen that shakes, flashes of colour
// for its feeling (red anger or danger, yellow a warning, blue shock), speed lines, dust, stars and comic bursts.
// The whole picture shakes (a goal, the woodwork, a fight): the svg itself, so its titles shake with it. Half on a weak phone.
export function shakeIt(svg, amt, t) { const k = SMOOTH ? amt * 0.5 : amt; const v = k > 0.05 ? `translate(${(Math.sin(t * 91) * k).toFixed(1)}px, ${(Math.cos(t * 77) * k * 0.7).toFixed(1)}px)` : ''; if (svg._shk !== v) { svg._shk = v; svg.style.transform = v } }
// A flash of colour over the whole screen (made before the title, so the title stays on top).
export function tint(svg, color) { const r = el('rect', { width: 640, height: 340, fill: color, opacity: 0, 'pointer-events': 'none' }, svg); return (f) => sa(r, 'opacity', Math.max(0, f)) }
// Speed lines behind a runner going (dx, dy) at (x, y), streaming back as he runs; f fades them in and out.
export function speedLines(svg, p = svg.world, n = 7, color = '#FFFFFF') {
  const g = el('g', { stroke: color, 'stroke-linecap': 'round', opacity: 0 }, p)
  const ls = Array.from({ length: n }, (_, i) => el('line', { 'stroke-width': 1.2 + (i % 3) * 0.7 }, g))
  return (x, y, dx, dy, f, t) => {
    sa(g, 'opacity', Math.max(0, f))
    if (f <= 0) return
    const L = Math.hypot(dx, dy) || 1, ux = dx / L, uy = dy / L, nx = -uy, ny = ux
    ls.forEach((l, i) => {
      const off = (i - (n - 1) / 2) * 6, ph = (t * 5 + i * 0.37) % 1, len = 24 + (i % 3) * 12, back = 12 + ph * 34
      const x1 = x - ux * back + nx * off, y1 = y - uy * back + ny * off
      sa(l, 'x1', x1.toFixed(1)); sa(l, 'y1', y1.toFixed(1)); sa(l, 'x2', (x1 - ux * len).toFixed(1)); sa(l, 'y2', (y1 - uy * len).toFixed(1)); sa(l, 'opacity', (1 - ph).toFixed(2))
    })
  }
}
// Paper confetti raining down after a goal; a: seconds since it started (0 or less: none).
export function confetti(svg, n = 46) {
  const cols = ['#F5B82E', '#EF4444', '#2BB673', '#3B82F6', '#E85D9A', '#FFFFFF']
  const ps = Array.from({ length: SMOOTH ? Math.floor(n / 2) : n }, (_, i) => el('rect', { width: 5, height: 9, rx: 1, fill: cols[i % 6], opacity: 0 }, svg))
  return (a) => ps.forEach((r, i) => {
    if (a <= 0) { sa(r, 'opacity', 0); return }
    const x = ((i * 97.3) % 660) - 10 + Math.sin(a * 3 + i) * 18, y = -20 - ((i * 53) % 140) + a * (90 + ((i * 37) % 60))
    sa(r, 'opacity', y > 350 ? 0 : 1); sa(r, 'transform', `translate(${x.toFixed(1)} ${y.toFixed(1)}) rotate(${Math.round(a * 300 + i * 40)})`)
  })
}
// A comic burst (a jagged star with a word): the keeper's fingertips, the ball on the bar.
export function boom(svg, p = svg.world, word = 'POW!', fill = '#FFD400', ink = '#B91C1C') {
  const g = el('g', { opacity: 0 }, p)
  const pts = Array.from({ length: 18 }, (_, i) => { const r = i % 2 ? 15 : 31, a = (i * Math.PI) / 9; return `${(Math.cos(a) * r).toFixed(1)},${(Math.sin(a) * r).toFixed(1)}` }).join(' ')
  g.innerHTML = `<polygon points="${pts}" fill="${fill}" stroke="#E2531F" stroke-width="3" stroke-linejoin="round"/><text y="5" text-anchor="middle" font-family="Barlow Condensed, sans-serif" font-weight="900" font-style="italic" font-size="15" fill="${ink}">${esc(word)}</text>`
  return (x, y, f) => { const on = f > 0 && f < 1; sa(g, 'opacity', on ? 1 - seg(f, 0.6, 1) : 0); if (on) sa(g, 'transform', `translate(${x.toFixed(1)} ${y.toFixed(1)}) scale(${(0.3 + ease(Math.min(1, f * 2.2)) * 0.9).toFixed(2)}) rotate(${Math.round(f * 20)})`) }
}
// A puff of dust on the grass (a slide, a fall, the medics' sprint).
export function dust(svg, p = svg.world, n = 8, color = '#D9C9A8') {
  const ps = Array.from({ length: n }, (_, i) => el('circle', { fill: Array.isArray(color) ? color[i % color.length] : color, opacity: 0 }, p))
  return (x, y, f) => ps.forEach((c, i) => {
    const on = f > 0 && f < 1, a = (i / n) * Math.PI * 2, d = 8 + ease(f) * 28
    sa(c, 'opacity', on ? (0.75 * (1 - f)).toFixed(2) : 0)
    if (on) { sa(c, 'cx', (x + Math.cos(a) * d * 1.4).toFixed(1)); sa(c, 'cy', (y + Math.sin(a) * d * 0.4 - ease(f) * 8).toFixed(1)); sa(c, 'r', (4 + f * 8).toFixed(1)) }
  })
}
// Stars and little birds circling a dazed player's head.
export function dizzy(svg, p = svg.world) {
  const g = el('g', { opacity: 0 }, p)
  const items = Array.from({ length: 5 }, (_, i) => { const e = el('g', {}, g); e.innerHTML = i % 2 ? '<path d="M-5 0 Q-2.5 -4 0 0 Q2.5 -4 5 0" fill="none" stroke="#fff" stroke-width="1.7" stroke-linecap="round"/>' : '<polygon points="0,-5 1.5,-1.5 5,-1.5 2.2,1 3.2,4.8 0,2.6 -3.2,4.8 -2.2,1 -5,-1.5 -1.5,-1.5" fill="#FFD400"/>'; return e })
  return (x, y, t, on) => { sa(g, 'opacity', on ? 1 : 0); if (on) items.forEach((e, i) => { const a = t * 5 + (i * Math.PI * 2) / items.length; sa(e, 'transform', `translate(${(x + Math.cos(a) * 20).toFixed(1)} ${(y + Math.sin(a) * 6).toFixed(1)})`) }) }
}
// [Sprint 42 F] The classic cartoon shock: the eyes pop out of the head on stalks, looking dir (-1 left, 1 right).
export function popEyes(svg, p = svg.world) {
  const g = el('g', { opacity: 0 }, p)
  g.innerHTML = [-6, 6].map((dx) => `<path d="M${dx * 0.4} 6 Q${dx} -4 ${dx * 1.6} -14" stroke="#C99A78" stroke-width="2" fill="none"/><g transform="translate(${dx * 1.6} -18)"><circle r="7" fill="#fff" stroke="#111" stroke-width="1.4"/><circle data-pupil="1" r="3.2" fill="#111"/></g>`).join('')
  const pupils = [...g.querySelectorAll('[data-pupil]')]
  return (x, y, f, dir = 1) => { sa(g, 'opacity', f > 0 ? 1 : 0); if (f > 0) { sa(g, 'transform', `translate(${x.toFixed(1)} ${y.toFixed(1)}) scale(${(0.4 + 0.8 * ease(Math.min(1, f))).toFixed(2)})`); pupils.forEach((pu) => sa(pu, 'cx', dir * 3)) } }
}
// A speech bubble of comic swearing (or a scream); k scales it.
export function bubbleOf(svg, p = svg.world, text = '#@!%&!', ink = '#D21F1F') {
  const g = el('g', { opacity: 0 }, p)
  g.innerHTML = `<path d="M-32 -14 Q-32 -27 -18 -27 H18 Q32 -27 32 -14 V-3 Q32 8 18 8 H-2 L-12 19 L-9 8 H-18 Q-32 8 -32 -3 Z" fill="#fff" stroke="#0A1F42" stroke-width="2"/><text y="-4" text-anchor="middle" font-family="Barlow Condensed, sans-serif" font-weight="900" font-size="16" fill="${ink}">${esc(text)}</text>`
  return (x, y, f, k = 1, wob = 0) => { sa(g, 'opacity', Math.max(0, f)); if (f > 0) sa(g, 'transform', `translate(${(x + wob).toFixed(1)} ${y.toFixed(1)}) scale(${(k * (0.7 + 0.3 * ease(Math.min(1, f)))).toFixed(2)})`) }
}
// The anger mark over a head, throbbing.
export function vein(svg, p = svg.world) {
  const g = el('path', { d: 'M-7 -2 Q-2 -2 -2 -7 M2 -7 Q2 -2 7 -2 M7 2 Q2 2 2 7 M-2 7 Q-2 2 -7 2', fill: 'none', stroke: '#E11D2E', 'stroke-width': 2.4, 'stroke-linecap': 'round', opacity: 0 }, p)
  return (x, y, f, t = 0) => { sa(g, 'opacity', Math.max(0, f)); if (f > 0) sa(g, 'transform', `translate(${x.toFixed(1)} ${y.toFixed(1)}) scale(${(1 + 0.25 * Math.sin(t * 14)).toFixed(2)})`) }
}
// Short lines bursting out of a point: a whistle blown, a hand slapped, a ring off the bar.
export function burst(svg, p = svg.world, color = '#FFFFFF', n = 8) {
  const g = el('g', { stroke: color, 'stroke-width': 2.2, 'stroke-linecap': 'round', opacity: 0 }, p)
  const ls = Array.from({ length: n }, () => el('line', {}, g))
  return (x, y, f, r0 = 8) => {
    const on = f > 0 && f < 1
    sa(g, 'opacity', on ? 1 - f : 0)
    if (on) ls.forEach((l, i) => { const a = (i / n) * Math.PI * 2 + 0.2, d0 = r0 + f * 10, d1 = d0 + 7; sa(l, 'x1', (x + Math.cos(a) * d0).toFixed(1)); sa(l, 'y1', (y + Math.sin(a) * d0).toFixed(1)); sa(l, 'x2', (x + Math.cos(a) * d1).toFixed(1)); sa(l, 'y2', (y + Math.sin(a) * d1).toFixed(1)) })
  }
}
export const referee = (w, k = 1.4) => player(w, officialKit(), '', k, { look: 9, shorts: '#111827', socks: '#111827', trim: '#F5B82E' })
// Where a standing figure's head is, drawn with at(x, y, 0, k).
export const headOf = (x, y, k) => [x, y - 21 * k]
// The flame round the ball: a shot like a fireball.
export function flame(svg, p = svg.world) {
  const g = el('g', { opacity: 0 }, p)
  g.innerHTML = `<circle r="13" fill="#FF7A1A" opacity=".55" filter="${ref(svg, 'glow')}"/><path d="M-9 0 Q-30 -6 -44 0 Q-30 6 -9 0 Z" fill="#FFB23F" opacity=".85"/><path d="M-8 -3 Q-24 -12 -36 -8 Q-22 -2 -8 3 Z" fill="#FF5A1F" opacity=".75"/>`
  return (x, y, dx, dy, on) => { sa(g, 'opacity', on ? 1 : 0); if (on) sa(g, 'transform', `translate(${x.toFixed(1)} ${y.toFixed(1)}) rotate(${Math.round((Math.atan2(dy, dx) * 180) / Math.PI)})`) }
}
// A water bottle by the touchline (the sent-off player kicks it).
export function bottle(p) { const g = el('g', {}, p); g.innerHTML = '<rect x="-4" y="-16" width="8" height="16" rx="2.5" fill="#7FC8FF" opacity=".85" stroke="#2D6FA8" stroke-width="1"/><rect x="-2.5" y="-20" width="5" height="4" rx="1" fill="#1F4E8C"/>'; return g }
// [Sprint 42 D1] The foul itself: the victim runs with the ball, the defender slides in feet first (contact at c), the
// victim flies in a flip, lands in a puff of dust and rolls holding his leg (until getUp). Both drawn with at(.., k).
export function tackle(svg, t, c, pl, vi, k, fx, getUp = Infinity, quiet = Infinity) {
  fx.slide(0, 0, 0)
  if (t < c) { vi.face?.('side', 1); vi.mood('focus'); vi.at(lerp(150, 330, seg(t, c - 0.8, c)), 200, 0, k); vi.run(t * 14, 1) }
  else if (t < c + 0.45) { const f = seg(t, c, c + 0.45); vi.face?.('side', 1); vi.mood('shock'); vi.at(lerp(330, 430, f), lerp(200, 268, f) - Math.sin(Math.PI * f) * 64, f * 450, k); vi.pose(50, 20, -150, -150, 0.5, 0.5) }
  else if (t < getUp) { const r = Math.sin(t * 9); vi.face?.('front'); vi.mood('angry'); vi.at(430 + r * 3, 268, 90 + r * 12, k); vi.pose(55, -8, 70, -55, 0.4, 0) }
  fx.dust(430, 283, seg(t, c + 0.42, c + 1.1))
  const hurt = Math.min(getUp, quiet, c + 2.6)
  fx.ouch(462, 228, seg(t, c + 0.5, c + 0.65) * (1 - seg(t, hurt, hurt + 0.2)), 0.85, Math.sin(t * 40) * 1.5)
  if (t < c - 0.3) { pl.face?.('side', 1); pl.mood('angry'); pl.at(lerp(20, 250, seg(t, c - 0.9, c - 0.3)), 206, 0, k); pl.run(t * 15, 1) }
  else if (t < c + 0.5) { const f = ease(seg(t, c - 0.3, c + 0.5)), x = lerp(250, 345, f); pl.face?.('side', 1); pl.mood('angry'); pl.at(x, 244, -70, k); pl.pose(6, -6, -30, -120); fx.slide(x + 46, 284, ((t - c + 0.3) % 0.3) / 0.3) }
  else { const f = ease(seg(t, c + 0.5, c + 0.9)); pl.face?.('front'); pl.mood('focus'); pl.at(lerp(345, 300, f), lerp(244, 200, f), lerp(-70, 0, f), k); pl.pose(3, -3, 14, -14) }
  shakeIt(svg, 4 * seg(t, c + 0.42, c + 0.46) * (1 - seg(t, c + 0.5, c + 0.85)), t)
}
// [Sprint 42 D1] The cartoon fight: a churning cloud of dust with fists, boots and stars flying out of it.
export function brawlCloud(svg, p = svg.world) {
  const g = el('g', { opacity: 0 }, p)
  const puffs = Array.from({ length: 11 }, (_, i) => el('circle', { fill: i % 2 ? '#CFC6B4' : '#E8E1D2', stroke: '#8E8572', 'stroke-width': 1.5 }, g))
  const pop = (html) => { const e = el('g', { opacity: 0 }, g); e.innerHTML = html; return e }
  const fist = '<circle r="8" fill="#D9A982" stroke="#5A3524" stroke-width="1.5"/><path d="M-3 -6 V2 M1 -7 V2 M5 -5 V2" stroke="#5A3524" stroke-width="1.2"/>'
  const boot = '<path d="M-6 -10 H4 V2 H12 Q14 2 14 7 V9 H-6 Z" fill="#0B0F1A" stroke="#fff" stroke-width="1"/>'
  const star = '<polygon points="0,-7 2,-2 7,-2 3,1 5,6 0,3 -5,6 -3,1 -7,-2 -2,-2" fill="#FFD400"/>'
  const items = [pop(fist), pop(boot), pop(fist), pop(star), pop(boot), pop(star)]
  return (x, y, t, f) => {
    sa(g, 'opacity', Math.max(0, f)); if (f <= 0) return
    puffs.forEach((c, i) => { const a = i * 0.57 * Math.PI + t * (i % 2 ? 3 : -2.4); sa(c, 'cx', (x + Math.cos(a) * 36).toFixed(1)); sa(c, 'cy', (y + Math.sin(a) * 18).toFixed(1)); sa(c, 'r', (22 + 6 * Math.sin(t * 7 + i)).toFixed(1)) })
    items.forEach((e, i) => { const u = t * 2.6 + i / items.length, ph = u % 1, a = i * 1.9 + Math.floor(u) * 2.3, d = 34 + ph * 26; sa(e, 'opacity', ph < 0.6 ? 1 : 0); sa(e, 'transform', `translate(${(x + Math.cos(a) * d * 1.4).toFixed(1)} ${(y + Math.sin(a) * d * 0.7).toFixed(1)}) rotate(${Math.round(a * 57)})`) })
  }
}
// A dangerous attack (the owner's): a red flash as it starts, then speed lines behind the runner.
export function danger(svg) {
  const red = tint(svg, '#FF2D2D'), sl = speedLines(svg)
  return (t, r) => {
    red(0.24 * seg(t, 0.02, 0.1) * (1 - seg(t, 0.18, 0.5)))
    if (!r?.tS) return
    const on = seg(t, 0.35, 0.6) * (1 - seg(t, r.tS - 0.25, r.tS)), s = persp(r.sy)
    sl(r.sx, r.sy - 40 * s, r.dir[0], r.dir[1], on, t)
  }
}

/**
 * Open play (goal, save, miss, blocked): the move that leads to the shot, from the engine's
 * own description of the attack (e.lane: left, center, right; e.quality: big = one on one,
 * normal = edge of the box, half = a tight chance among defenders, long = from distance,
 * header = a cross). The ball reaches the goal at KT; what happens then is the outcome.
 */
