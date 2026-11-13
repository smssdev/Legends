// [Sprint 57 W4] Who is in a scene: the players and the keepers, the ball and its trail, the headline and the flashes.
import { KITS, type SvgNode, type Side, type Svg, VARIANT, bez, clamp, ease, el, esc, inout, keeperKit, lerp, lum, nextId, sa, shade } from './kit'
import { persp, ref } from './stage'

export const SKINS = ['#C99A78', '#8D5A3B', '#E2B48F', '#6B4027', '#B07B57', '#D9A982', '#5A3524']
export const HAIR = ['#1B1410', '#2A1A10', '#5A3A1E', '#0E0E0E', '#B8893E', '#3B2414']
// [X76] The club's kit pattern on a scene's player, in its trim colour: the side is the one whose shirt this is.
/** A figure's own looks: the face (look), the shorts, socks, trim and a keeper's gloves. */
export type Looks = { look?: number; shorts?: string; socks?: string; trim?: string; gloves?: string }
/** A drawn player (or referee, or coach): his parts and how he moves. */
export type Figure = ReturnType<typeof player>

export function kitPatternSvg(kit: string, o: Looks) {
  const side = kit === KITS.home?.kit ? 'home' : kit === KITS.away?.kit ? 'away' : null, p = side && !o.gloves ? KITS[side].pattern : null
  if (!p) return ''
  const id = 'kp' + nextId(), c = o.trim ?? KITS[side!].trim ?? '#fff'
  const shapes = p === 'stripes' ? [-12, -4, 4, 12].map((x) => `<rect x="${x - 2}" y="-16" width="4" height="42"/>`).join('')
    : p === 'hoops' ? [-8, 1, 10, 19].map((y) => `<rect x="-16" y="${y - 2.2}" width="32" height="4.4"/>`).join('')
    : p === 'halves' ? '<rect x="0" y="-16" width="16" height="42"/>'
    : p === 'sash' ? '<path d="M-16 -6 L-9 -16 L16 16 L16 25 Z"/>' : ''
  return `<clipPath id="${id}"><path d="M-15 -9 Q0 -15 15 -9 L14.5 21 Q0 24 -14.5 21 Z"/></clipPath><g clip-path="url(#${id})" fill="${c}">${shapes}</g>`
}
// [Sprint 37 N4] The brows (left, right, profile) and the mouth (front, profile) for each feeling.
/** A feeling's brows, mouth and eyes. */
type Face = { bl: string; br: string; bs: string; mf: string; ms: string; open?: boolean; eye?: number[]; eyeR?: number[] }
export const FACES: Record<string, Face> = {
  idle: { bl: 'M-5.6 -24.6 L-1.6 -24.9', br: 'M1.6 -24.9 L5.6 -24.6', bs: 'M2.4 -24.9 L6.8 -24.6', mf: 'M-2.6 -16.2 Q0 -15 2.6 -16.2', ms: 'M6.4 -16.4 L8.8 -16.1' },
  joy: { bl: 'M-5.6 -25.6 Q-3.6 -26.8 -1.6 -25.8', br: 'M1.6 -25.8 Q3.6 -26.8 5.6 -25.6', bs: 'M2.4 -25.8 Q4.6 -26.8 6.8 -25.6', mf: 'M-3.4 -16.8 Q0 -11.4 3.4 -16.8 Z', ms: 'M5.8 -17.2 Q8 -13.2 9.2 -16.8 Z', open: true },
  angry: { bl: 'M-5.8 -26 L-1.4 -23.8', br: 'M1.4 -23.8 L5.8 -26', bs: 'M2.4 -25.8 L6.8 -23.6', mf: 'M-3 -14.6 Q0 -17.4 3 -14.6 Q0 -15.6 -3 -14.6 Z', ms: 'M6.2 -15.6 Q7.8 -17 9.2 -15.8', open: true },
  sad: { bl: 'M-5.8 -23.8 L-1.4 -25.8', br: 'M1.4 -25.8 L5.8 -23.8', bs: 'M2.4 -25.6 L6.8 -24', mf: 'M-2.6 -15 Q0 -16.8 2.6 -15', ms: 'M6.4 -15.6 Q7.6 -16.6 8.8 -15.8' },
  focus: { bl: 'M-5.6 -24.2 L-1.4 -23.6', br: 'M1.4 -23.6 L5.6 -24.2', bs: 'M2.4 -24 L6.8 -23.4', mf: 'M-2.4 -15.8 L2.4 -15.8', ms: 'M6.4 -16 L8.8 -16' },
  // [Sprint 42] The cartoon's faces: shock (eyes wide, the mouth an O) and the diver's peek (one eye open).
  shock: { bl: 'M-5.6 -27.4 Q-3.6 -28.8 -1.6 -27.6', br: 'M1.6 -27.6 Q3.6 -28.8 5.6 -27.4', bs: 'M2.4 -27.6 Q4.6 -28.8 6.8 -27.4', mf: 'M-1.8 -15.6 A1.8 2.4 0 1 0 1.8 -15.6 A1.8 2.4 0 1 0 -1.8 -15.6 Z', ms: 'M6.6 -16.4 A1.2 1.6 0 1 0 8.6 -16.4 A1.2 1.6 0 1 0 6.6 -16.4 Z', open: true, eye: [2, 2.4], eyeR: [2, 2.4] },
  // [Sprint 42 H1] A commentator talking: the mouth open in a small O (it alternates with idle).
  talk: { bl: 'M-5.6 -25 L-1.6 -25.3', br: 'M1.6 -25.3 L5.6 -25', bs: 'M2.4 -25.3 L6.8 -25', mf: 'M-2 -16.4 Q0 -13.4 2 -16.4 Q0 -17.2 -2 -16.4 Z', ms: 'M6.4 -16.6 Q7.6 -14.6 8.8 -16.4 Z', open: true },
  peek: { bl: 'M-5.6 -23.4 L-1.4 -23.2', br: 'M1.4 -25.2 Q3.6 -26.4 5.6 -25.4', bs: 'M2.4 -25.4 Q4.6 -26.4 6.8 -25.2', mf: 'M-1.6 -15.8 L1.6 -15.8', ms: 'M6.6 -16 L8.6 -16', eye: [1.5, 0.25], eyeR: [1.6, 1.7] },
}
export function player(p: SvgNode, kit: string, no: number | string | null | undefined, s = 1, o: Looks = {}) {
  if (p.world) p = p.world
  const light = lum(kit) > 150, ink = light ? '#0A1F42' : '#fff', look = o.look ?? 0
  const skin = SKINS[look % SKINS.length], hair = HAIR[Math.floor(look / 7) % HAIR.length], shorts = o.shorts ?? (light ? '#1C2B48' : shade(kit, -80))
  const g = el('g', {}, p)
  el('ellipse', { cx: 0, cy: 58, rx: 17, ry: 4.5, fill: 'rgba(0,0,0,.42)' }, g)
  const fig = el('g', {}, g)
  const part = (x: number, y: number, html: string) => { const e = el('g', {}, fig); e.innerHTML = html; return { e, x, y } }
  const leg = `<rect x="-4.5" y="0" width="9" height="15" rx="3.5" fill="${skin}"/><rect x="-4.6" y="12" width="9.2" height="16" rx="3.5" fill="${o.socks ?? (light ? kit : shade(kit, 25))}"/><path d="M-5.5 27 h10 q4.5 0 4.5 3.2 v1.6 h-14.5 z" fill="#0B0F1A"/>`
  const legs = [part(-6, 25, leg), part(6, 25, leg)]
  const body = el('g', {}, fig)
  body.innerHTML = `<path d="M-13.5 17 H13.5 L15 31 H1.5 L0 27 L-1.5 31 H-15 Z" fill="${shorts}"/>
    <path d="M-15 -9 Q0 -15 15 -9 L14.5 21 Q0 24 -14.5 21 Z" fill="${kit}"/>${kitPatternSvg(kit, o)}
    <path d="M-6 21 Q0 -2 6 21" fill="rgba(0,0,0,.08)"/>
    <path d="M-15 -9 Q0 -15 15 -9" fill="none" stroke="${o.trim ?? shade(kit, light ? -45 : 45)}" stroke-width="2"/>
    <text data-back="1" x="0" y="12" text-anchor="middle" font-family="Barlow Condensed, Tajawal, sans-serif" font-weight="800" font-size="18" fill="${ink}">${esc(no)}</text>
    <text data-front="1" x="6" y="4" text-anchor="middle" font-family="Barlow Condensed, Tajawal, sans-serif" font-weight="800" font-size="8" fill="${ink}" display="none">${esc(no)}</text>`
  const back = body.querySelector<SvgNode>('[data-back]')!, chest = body.querySelector<SvgNode>('[data-front]')!
  const arm = `<rect x="-4" y="0" width="8" height="12" rx="3.5" fill="${kit}"/><rect x="-3.4" y="10" width="6.8" height="13" rx="3.4" fill="${o.gloves ? kit : skin}"/>${o.gloves ? `<rect x="-5" y="20" width="10" height="9" rx="3.5" fill="${o.gloves}" stroke="rgba(0,0,0,.35)" stroke-width=".8"/>` : ''}`
  // [Sprint 35 C2] The right hand can hold a card up (the referee's).
  const arms = [part(-14.5, -7, arm), part(14.5, -7, arm + '<rect data-card="1" x="-4.5" y="20" width="9" height="13" rx="1.5" stroke="rgba(0,0,0,.35)" stroke-width=".8" display="none"/>')]
  const cardEl = arms[1].e.querySelector<SvgNode>('[data-card]')!
  // The head from behind (hair over it), from the front (a face) and from the side (a profile looking right).
  const head = part(0, 0, `<rect x="-3.4" y="-15" width="6.8" height="7" fill="${skin}"/><circle cx="0" cy="-21" r="9.4" fill="${skin}"/>
    <g data-h="back"><path d="M-9.6 -21 Q-10 -32 0 -32.5 Q10 -32 9.6 -21 Q7 -24 3 -24.5 Q-4 -25 -9.6 -21 Z" fill="${hair}"/></g>
    <g data-h="front" display="none"><circle cx="-9.4" cy="-20.5" r="2" fill="${shade(skin, -18)}"/><circle cx="9.4" cy="-20.5" r="2" fill="${shade(skin, -18)}"/><path d="M-9.6 -22 Q-10 -32 0 -32.5 Q10 -32 9.6 -22 Q6 -28 0 -28 Q-6 -28 -9.6 -22 Z" fill="${hair}"/><path data-brow="l" fill="none" stroke="${hair}" stroke-width="1.3" stroke-linecap="round"/><path data-brow="r" fill="none" stroke="${hair}" stroke-width="1.3" stroke-linecap="round"/><ellipse data-eye="l" cx="-3.4" cy="-21" rx="1.3" ry="1.3" fill="#141414"/><ellipse data-eye="r" cx="3.4" cy="-21" rx="1.3" ry="1.3" fill="#141414"/><path d="M0.2 -20.4 L-1 -17.8 L0.9 -17.6" fill="none" stroke="${shade(skin, -45)}" stroke-width=".8" stroke-linejoin="round"/><path data-mouth="f" stroke="rgba(60,20,10,.7)" stroke-width="1" stroke-linecap="round"/></g>
    <g data-h="side" display="none"><path d="M-9.6 -19 Q-11 -32 0 -32.5 Q9 -32 9.4 -24 Q4 -27 -1 -25 Q-3 -20 -9.6 -19 Z" fill="${hair}"/><circle cx="-1.6" cy="-20.5" r="2" fill="${shade(skin, -18)}"/><path data-brow="s" fill="none" stroke="${hair}" stroke-width="1.3" stroke-linecap="round"/><ellipse data-eye="s" cx="4.6" cy="-22" rx="1.3" ry="1.3" fill="#141414"/><path d="M9 -21 L11.6 -18.6 L9 -17.6" fill="${skin}"/><path data-mouth="s" stroke="rgba(60,20,10,.7)" stroke-width="1" stroke-linecap="round"/></g>`)
  const heads = Object.fromEntries([...head.e.querySelectorAll<SvgNode>('[data-h]')].map((e) => [e.dataset.h, e]))
  // [Sprint 37 N4] The face's feeling in a close-up: the brows and the mouth (front and profile).
  const brow = Object.fromEntries([...head.e.querySelectorAll<SvgNode>('[data-brow]')].map((e) => [e.dataset.brow, e]))
  const mouth = Object.fromEntries([...head.e.querySelectorAll<SvgNode>('[data-mouth]')].map((e) => [e.dataset.mouth, e]))
  const eyes = Object.fromEntries([...head.e.querySelectorAll<SvgNode>('[data-eye]')].map((e) => [e.dataset.eye, e]))
  let felt = ''
  const setMood = (m: string) => {
    if (m === felt) return
    felt = m
    const F = FACES[m] ?? FACES.idle
    sa(brow.l, 'd', F.bl); sa(brow.r, 'd', F.br); sa(brow.s, 'd', F.bs)
    sa(mouth.f, 'd', F.mf); sa(mouth.s, 'd', F.ms)
    for (const k of ['f', 's']) { sa(mouth[k], 'fill', F.open ? '#5A1A14' : 'none') }
    // [Sprint 42] The eyes: wide in shock, one shut in the diver's peek.
    const [lx, ly] = F.eye ?? [1.3, 1.3], [rx, ry] = F.eyeR ?? F.eye ?? [1.3, 1.3]
    sa(eyes.l, 'rx', lx); sa(eyes.l, 'ry', ly); sa(eyes.r, 'rx', rx); sa(eyes.r, 'ry', ry); sa(eyes.s, 'rx', rx); sa(eyes.s, 'ry', ry)
  }
  setMood('idle')
  // Facing: 'back', 'front' or 'side'; mirror -1 turns the side profile to the left. Narrower from the side.
  let facing = 'back', mirror = 1, wide = 1
  const setLeg = (i: number, r: number, lift: number) => sa(legs[i].e, 'transform', `translate(${legs[i].x * wide} ${legs[i].y}) rotate(${r}) scale(1 ${1 - 0.45 * lift})`)
  const setArm = (i: number, r: number) => sa(arms[i].e, 'transform', `translate(${arms[i].x * (wide < 1 ? 0.12 : 1)} ${arms[i].y}) rotate(${r})`)
  const api = {
    g,
    at(x: number, y: number, r = 0, k = s) { sa(g, 'transform', `translate(${x} ${y}) rotate(${r}) scale(${k * mirror} ${k})`) },
    face(f = 'back', m = 1) {
      if (f === facing && m === mirror) return
      facing = f; mirror = f === 'side' ? (m < 0 ? -1 : 1) : 1; wide = f === 'side' ? 0.45 : 1
      for (const k in heads) sa(heads[k], 'display', k === f ? 'inline' : 'none')
      sa(back, 'display', f === 'back' ? 'inline' : 'none'); sa(chest, 'display', f === 'front' ? 'inline' : 'none')
      sa(body, 'transform', f === 'side' ? 'scale(.72 1)' : 'scale(1 1)')
      // From the side the far arm swings behind the body, the near one in front of it.
      fig.insertBefore(arms[0].e, f === 'side' ? body : arms[1].e)
    },
    get facing() { return facing },
    // [Sprint 37 N4] idle, joy, angry, sad or focus: seen in the close-ups that turn him to the camera or side on.
    mood: setMood,
    // [Sprint 35 C2] A card in the right hand (its colour), or none.
    card(colour: string | null) { sa(cardEl, 'display', colour ? 'inline' : 'none'); if (colour) sa(cardEl, 'fill', colour) },
    // Arm angles: 0 hangs down, positive swings the left arm out (the right arm takes the negative).
    pose(l1 = 3, l2 = -3, a1 = 10, a2 = -10, lift1 = 0, lift2 = 0) { setLeg(0, l1, lift1); setLeg(1, l2, lift2); setArm(0, a1); setArm(1, a2) },
    // From the side the legs and arms swing forward and back (a stride); from behind or in front they lift in turn.
    run(ph: number, amp = 1) {
      const q = Math.sin(ph)
      if (facing === 'side') { const st = 30 * q * amp; api.pose(st, -st, -st * 1.1, st * 1.1, Math.max(0, -q) * amp * 0.5, Math.max(0, q) * amp * 0.5); return }
      api.pose(4, -4, 16 + 24 * q * amp, -16 + 24 * q * amp, Math.max(0, q) * amp, Math.max(0, -q) * amp)
    },
    // Standing: breathing, the arms swaying a little (b 0..1 around the breath).
    idle(b: number) { const w = Math.sin(b) * 3; api.pose(3, -3, 10 + w, -10 - w) },
    // A strike with the right foot: the leg swings back, then through the ball (f 0..1).
    kick(f: number) { const r = f < 0.55 ? lerp(-4, -38, f / 0.55) : lerp(-38, 52, ease((f - 0.55) / 0.45)); api.pose(6, r, 34, -48, 0, f < 0.55 ? 0.55 : 0.15) },
    celebrate(t: number) { const w = Math.sin(t * 9) * 12; api.pose(8, -8, 112 + w, -112 - w) },
    // Hands on hips, the head down: the chance has gone.
    despair() { api.pose(2, -2, 32, -32) },
  }
  api.pose()
  return api
}
// Stands a player on the ground at (x, y): scale and feet follow the depth.
export function put(f: Figure, x: number, y: number, r = 0, k = 1, lift = 0) { const s = persp(y) * k; f.at(x, y - 58 * s - lift, r, s); return s }
// A keeper's kit that stands apart from both teams, with bright gloves.
export const keeper = (svg: Svg, side: Side, look = 3) => player(svg, keeperKit(side), 1, 1, { gloves: '#E4FF5A', look, shorts: '#111827', socks: keeperKit(side) })

/**
 * The keeper's dive from his spot (x0, ground y0): his gloves reach (gx, gy) at f = 1, then he
 * lands (after 0..1). A ball near his body he takes standing. Returns where his gloves are.
 */
export function dive(k: Figure, x0: number, y0: number, gx: number, gy: number, f: number, after = 0) {
  const s = persp(y0), cx0 = x0, cy0 = y0 - 58 * s, L = 36 * s
  if (Math.abs(gx - x0) < 17 * s / 0.55 && gy > cy0 - 30) {
    // Straight at him: he bends, gathers it into his chest.
    const e = ease(f), y = cy0 + 4 * e
    k.at(x0 + (gx - x0) * 0.6 * e, y, 0, s)
    k.pose(14, -14, lerp(30, 62, e), lerp(-30, -62, e))
    return [x0 + (gx - x0) * 0.6 * e, y + 8 * s]
  }
  let rot = Math.atan2(gx - cx0, -(gy - cy0))
  rot = Math.max(-1.62, Math.min(1.62, rot))
  const e = ease(f)
  let x = lerp(cx0, gx - Math.sin(rot) * L, e), y = lerp(cy0, gy + Math.cos(rot) * L, e) - Math.sin(e * Math.PI) * 5, r = rot * e
  if (after > 0) {
    const a = inout(clamp(after)), dir = Math.sign(rot) || 1
    x += dir * 12 * a
    y = lerp(y, y0 - 13 * s, a)
    r = lerp(r, dir * 1.56, a)
  }
  k.at(x, y, r * 57.3, s)
  const arm = lerp(30, 168, e)
  k.pose(4 + 22 * e, -4 - 22 * e, arm, -arm)
  return [x + Math.sin(r) * L, y - Math.cos(r) * L]
}
// The keeper waiting: on his toes, following the ball across his line.
export function ready(k: Figure, x: number, y: number, t: number, crouch = 1) { put(k, x + Math.sin(t * 4.2) * 1.5, y, 0, 1, Math.abs(Math.sin(t * 8.4)) * 1.2); k.pose(12 * crouch, -12 * crouch, 30 + 6 * crouch, -30 - 6 * crouch) }

// [Sprint 42 K2] The ball, easy to follow: bigger, shaded round, a dark edge against the white net and the day sky, a
// faint white halo against the night grass, and never smaller than readable far away.
export function ball(svg: Svg, p = svg.world) {
  const shadow = el('ellipse', { rx: 7, ry: 2.4, fill: 'rgba(0,0,0,.5)' }, p)
  const g = el('g', {}, p), id = svg.dataset.id
  g.innerHTML = `<circle r="10.5" fill="#FFFFFF" opacity=".28"/><circle r="8" fill="url(#${id}ball)" stroke="#16203A" stroke-width="1.1"/><g data-spin="1" transform="scale(1.23)"><path d="M0 -2.6 L2.5 -0.8 L1.6 2.1 L-1.6 2.1 L-2.5 -0.8 Z" fill="#16203A"/><path d="M0 -6.5 L0 -2.6 M2.5 -0.8 L6.2 -2 M1.6 2.1 L3.8 5.3 M-1.6 2.1 L-3.8 5.3 M-2.5 -0.8 L-6.2 -2" stroke="#16203A" stroke-width=".9"/></g><circle cx="-2.6" cy="-3" r="2" fill="#fff" opacity=".8"/>`
  const spin = g.querySelector<SvgNode>('[data-spin]')!
  return {
    g,
    // Screen point, its depth on the ground (for size and shadow), and how much it has spun.
    set(x: number, y: number, ground: number, turn = 0, op = 1) {
      const s = Math.max(0.78, persp(ground)) * 1.05
      sa(g, 'transform', `translate(${x} ${y}) scale(${s})`)
      sa(g, 'opacity', op)
      sa(spin, 'transform', `rotate(${turn})`)
      const h = clamp((ground - y) / 90)
      sa(shadow, 'cx', x + h * 6); sa(shadow, 'cy', ground); sa(shadow, 'rx', 6 * s * (1 - h * 0.5)); sa(shadow, 'ry', 2 * s * (1 - h * 0.5))
      sa(shadow, 'opacity', op * (1 - h * 0.7))
    },
  }
}
export function trail(svg: Svg, p = svg.world, color = '#FFE7A8') { return el('path', { d: '', fill: 'none', stroke: color, 'stroke-width': 2.5, 'stroke-linecap': 'round', opacity: 0, filter: ref(svg, 'glow') }, p) }
export const drawTrail = (trl: SvgNode, path: number[][], f: number, op: number, from = 0) => { const pts = Array.from({ length: 14 }, (_, i) => bez(path, Math.max(from, f - 0.35) + ((f - Math.max(from, f - 0.35)) * i) / 13)); sa(trl, 'd', 'M' + pts.map((q) => q.join(' ')).join(' L')); sa(trl, 'opacity', op) }
// The headline: a dark band with gold rules sliding in, the word over it.
export function title(svg: Svg, text: string, color?: string) {
  const fill = color ?? ref(svg, 'gold'), style = VARIANT.title
  const band = el('rect', { x: 0, y: 4, width: 640, height: 60, fill: style === 2 ? 'rgba(4,11,28,.45)' : 'rgba(4,11,28,.75)', opacity: 0 }, svg)
  const r1 = el('rect', { x: 0, y: 4, width: 640, height: 2, fill: style === 2 ? fill : ref(svg, 'gold'), opacity: 0 }, svg), r2 = el('rect', { x: 0, y: 62, width: 640, height: 2, fill: style === 2 ? fill : ref(svg, 'gold'), opacity: 0 }, svg)
  // [Sprint 42 J1] The stamp: a box behind the word, at a slant.
  const box = style === 3 ? el('rect', { x: 200, y: 10, width: 240, height: 56, rx: 6, fill: 'rgba(4,11,28,.82)', stroke: fill, 'stroke-width': 4, opacity: 0 }, svg) : null
  // [Sprint 30 Q8] A dark edge under the word: read whole over the pitch, the flashes and the band.
  const t = el('text', { x: 320, y: 40, 'text-anchor': 'middle', 'dominant-baseline': 'middle', 'font-family': 'Tajawal, sans-serif', 'font-weight': 700, 'font-size': 36, fill, stroke: '#040B1C', 'stroke-width': 5, 'paint-order': 'stroke', 'stroke-linejoin': 'round', opacity: 0 }, svg)
  t.textContent = text
  // [Sprint 42 J1] Four looks for the headline, one per scene (VARIANT.title): the gold band sliding in; the slam (the
  // word drops in big, no band); neon (a thin band in its colour, the word flickering on); the stamp (a box at a slant).
  return (f: number) => {
    const e = ease(f)
    if (style === 1) { sa(t, 'opacity', f); sa(t, 'transform', `translate(320 40) scale(${(lerp(2.6, 1, e)).toFixed(3)}) rotate(${((1 - e) * -6).toFixed(1)}) translate(-320 -40)`); return }
    if (style === 3) { const k = f < 1 ? lerp(1.7, 1, e) - Math.sin(Math.PI * f) * 0.08 : 1; for (const x of [box!, t]) { sa(x, 'opacity', f); sa(x, 'transform', `translate(320 38) rotate(-5) scale(${k.toFixed(3)}) translate(-320 -38)`) } return }
    sa(band, 'opacity', f); sa(r1, 'opacity', f); sa(r2, 'opacity', f); sa(r1, 'transform', `translate(${(1 - e) * -640} 0)`); sa(r2, 'transform', `translate(${(1 - e) * 640} 0)`)
    sa(t, 'opacity', style === 2 && f < 1 ? (Math.sin(f * 45) > 0 ? f : f * 0.3) : f); sa(t, 'transform', `translate(320 40) scale(${0.8 + 0.2 * e}) translate(-320 -40)`)
  }
}
export function bigNumber(svg: Svg, no: number | string | null | undefined, kit: string) {
  const t = el('text', { x: 520, y: 300, 'text-anchor': 'middle', 'font-family': 'Barlow Condensed, Tajawal, sans-serif', 'font-weight': 800, 'font-style': 'italic', 'font-size': 260, fill: 'none', stroke: kit, 'stroke-width': 2, opacity: 0 }, svg)
  t.textContent = String(no ?? '')
  return (f: number) => { sa(t, 'opacity', f * 0.35); sa(t, 'transform', `translate(${(1 - ease(f)) * 60} 0)`) }
}
export function flash(svg: Svg) { const r = el('rect', { width: 640, height: 340, fill: '#FFF6DA', opacity: 0 }, svg); return (f: number) => sa(r, 'opacity', f) }
// Camera flashes in the stands after a goal.
export function flashes(svg: Svg, p = svg.world) { const d = Array.from({ length: 26 }, (_, i) => el('circle', { cx: ((i * 97) % 720) - 40, cy: 12 + ((i * 53) % 100), r: 2.2, fill: '#fff', opacity: 0 }, p)); return (t: number, on: boolean) => d.forEach((c, i) => sa(c, 'opacity', on && Math.sin(t * 23 + i * 7.3) > 0.92 ? 0.95 : 0)) }
export const run = (t: number, a: number, b: number) => Math.sin(t * 12) * 4 * (t > a && t < b ? 1 : 0)
