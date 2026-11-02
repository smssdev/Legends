// @ts-nocheck
// The match feed's art (docs/MATCH_VIEW.md 4.6): broadcast motion graphics in the
// brand's navy and gold, with each team's colour as light. A night pitch in
// perspective, clean player silhouettes with numbers, light trails, flashes and
// particles; crests and line icons for the timeline. Drawing only: which scene
// plays, and with whom, comes from story.ts.
import { t as tr } from '../../lib/i18n'

const NS = 'http://www.w3.org/2000/svg'
// The two kits of the match: { kit, ink, trim, name } per side, set by the feed.
let KITS = { home: { kit: '#E8ECF4', ink: '#0A1F42', trim: '#F5B82E', name: '' }, away: { kit: '#D3122F', ink: '#FFFFFF', trim: '#F6C343', name: '' } }
export function setKits(k) { KITS = k }
// The smooth mode [X30]: no glow filter (redrawn every frame on the phone's processor for every line and trail) and a third of the crowd.
let SMOOTH = false
export function setSmooth(v) { SMOOTH = !!v }
// [Sprint 36 F3] The match's rain (the live pitch's, from its seed) falls in the scenes too.
let RAIN = false
export function setRain(v) { RAIN = !!v }
const K = (s) => KITS[s] ?? KITS.home
const other = (s) => (s === 'home' ? 'away' : 'home')
export const lum = (hex) => { const n = parseInt(String(hex).slice(1), 16); return 0.3 * (n >> 16) + 0.59 * ((n >> 8) & 255) + 0.11 * (n & 255) }
export const shade = (hex, p) => { const n = parseInt(hex.slice(1), 16), f = (v) => Math.max(0, Math.min(255, v + p)); return '#' + [f(n >> 16), f((n >> 8) & 255), f(n & 255)].map((v) => v.toString(16).padStart(2, '0')).join('') }
// A keeper's kit that stands apart from both teams.
// [Sprint 31 D3] Chosen from a few, the first that stands apart from both teams' shirts (and from the other keeper's).
const rgbOf = (hex) => { const n = parseInt(String(hex).slice(1, 7), 16); return [n >> 16, (n >> 8) & 255, n & 255] }
const apart = (a, b) => { const x = rgbOf(a), y = rgbOf(b); return Math.abs(x[0] - y[0]) + Math.abs(x[1] - y[1]) + Math.abs(x[2] - y[2]) > 150 }
const pickKit = (choices, avoid) => choices.find((c) => avoid.every((a) => !a || apart(c, a))) ?? choices[0]
export const keeperKit = (side) => {
  const shirts = [KITS.home?.kit, KITS.away?.kit]
  const home = pickKit(['#2BB673', '#7B3FE4', '#F2994A', '#14B8C4'], shirts)
  return side === 'home' ? home : pickKit(['#F2994A', '#14B8C4', '#7B3FE4', '#2BB673'], [...shirts, home])
}
/** [Sprint 31 D1, D3] The officials' shirt: black, or another colour when a team plays in a dark kit. */
export const officialKit = () => pickKit(['#15171C', '#F2E205', '#E85D9A', '#7B3FE4'], [KITS.home?.kit, KITS.away?.kit, keeperKit('home'), keeperKit('away')])

// Writes an attribute only when it changes [X30]: every write, even of the same value, makes the browser lay the
// scene out again, and a scene sets hundreds of them a frame (most of them unchanged, like the flashes at rest).
const sa = (e, k, v) => { const key = '_' + k; if (e[key] === v) return; e[key] = v; e.setAttribute(k, v) }

let uid = 0
export const crest = ([c1, c2, t]) => {
  const id = 'cr' + ++uid
  return `<svg viewBox="0 0 64 72"><defs><linearGradient id="${id}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${c1}"/><stop offset="1" stop-color="${shade(c1, -50)}"/></linearGradient></defs><path d="M32 2 L60 10 V36 C60 54 47 65 32 70 C17 65 4 54 4 36 V10 Z" fill="url(#${id})" stroke="${c2}" stroke-width="3"/><path d="M32 9 L53 15 V35 C53 49 43 58 32 62" fill="none" stroke="rgba(255,255,255,.35)" stroke-width="2"/><text x="32" y="42" text-anchor="middle" font-family="Barlow Condensed, Amin, sans-serif" font-weight="800" font-size="${t.length > 2 ? 17 : 20}" fill="${lum(c1) > 150 ? '#0A1F42' : '#fff'}">${t}</text></svg>`
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
const el = (tag, a, p) => { const e = document.createElementNS(NS, tag); for (const k in a) sa(e, k, a[k]); p && p.appendChild(e); return e }
const clamp = (v) => Math.max(0, Math.min(1, v))
const seg = (t, a, b) => clamp((t - a) / (b - a))
const ease = (f) => 1 - Math.pow(1 - f, 3)
const inout = (f) => (f < 0.5 ? 4 * f * f * f : 1 - Math.pow(-2 * f + 2, 3) / 2)
const lerp = (a, b, f) => a + (b - a) * f
const bez = (p, f) => { const u = 1 - f; return [u * u * p[0][0] + 2 * u * f * p[1][0] + f * f * p[2][0], u * u * p[0][1] + 2 * u * f * p[1][1] + f * f * p[2][1]] }
// The same scene for the same minute: every choice (the corner aimed at, the keeper's dive) comes from the minute's seed.
function rnd(seed) {
  let a = (seed >>> 0) || 7
  return () => { a = (a + 0x6d2b79f5) >>> 0; let t = a; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296 }
}

// The camera looks at the goal from behind the attack. The goal line is at y 150 (posts at
// x 246 and 394, bar at y 72); a player standing at ground y is drawn at scale persp(y).
const LINE = 150, POSTS = [246, 394], BAR = 72
const persp = (y) => 0.55 + (y - LINE) * 0.0055

// The stage: a night stadium, the pitch in perspective, boards behind the goal, the team's light.
// Everything that the camera moves sits in svg.world; titles and flashes go on top of it.
function stage(side) {
  const c = K(side).kit, id = 's' + ++uid
  const svg = el('svg', { viewBox: '0 0 640 340' })
  svg.innerHTML = `<defs>
    <linearGradient id="${id}t" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#14532F"/><stop offset="1" stop-color="#0A2E1B"/></linearGradient>
    <radialGradient id="${id}h" cx=".5" cy="0" r="1"><stop offset="0" stop-color="rgba(255,255,255,.22)"/><stop offset=".6" stop-color="rgba(255,255,255,0)"/></radialGradient>
    <radialGradient id="${id}c" cx=".5" cy=".55" r=".6"><stop offset="0" stop-color="${c}" stop-opacity=".2"/><stop offset="1" stop-color="${c}" stop-opacity="0"/></radialGradient>
    <radialGradient id="${id}v" cx=".5" cy=".45" r=".75"><stop offset=".6" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity=".55"/></radialGradient>
    <linearGradient id="gold${id}" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#C08A0C"/><stop offset=".5" stop-color="#FFD36B"/><stop offset="1" stop-color="#C08A0C"/></linearGradient>
    <linearGradient id="${id}b" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#0B2149"/><stop offset=".5" stop-color="#163B78"/><stop offset="1" stop-color="#0B2149"/></linearGradient>
    <filter id="glow${id}" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="4" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter>
    <filter id="soft${id}"><feGaussianBlur stdDeviation="10"/></filter>
  </defs>
  <rect width="640" height="340" fill="#040B1C"/>
  <g data-world="1">
  <rect x="-80" y="-40" width="800" height="200" fill="url(#${id}h)"/>
  <g>${Array.from({ length: SMOOTH ? 70 : 220 }, (_, i) => `<circle cx="${((i * 71) % 760) - 60}" cy="${8 + ((i * 37) % 112)}" r="${1.2 + (i % 3) * 0.7}" fill="${['#2B4F8C', '#3D63A8', c, '#F5B82E', '#C9D2E1'][i % 5]}" opacity="${0.18 + (i % 5) * 0.08}"/>`).join('')}</g>
  <rect x="-80" y="122" width="800" height="16" fill="url(#${id}b)"/>
  <rect x="-80" y="122" width="800" height="1.5" fill="#F5B82E" opacity=".6"/>
  ${[60, 220, 380, 540].map((x) => `<text x="${x}" y="134" font-family="Amin, sans-serif" font-weight="800" font-size="10" letter-spacing="3" fill="#FFD36B" opacity=".75">LEGENDS</text>`).join('')}
  <path d="M-120 380 L120 ${LINE - 12} L520 ${LINE - 12} L760 380 Z" fill="url(#${id}t)"/>
  ${Array.from({ length: 9 }, (_, i) => { const y0 = LINE - 12 + Math.pow(i / 9, 1.6) * 242, y1 = LINE - 12 + Math.pow((i + 0.5) / 9, 1.6) * 242, k0 = (y0 - LINE + 12) * 1.0, k1 = (y1 - LINE + 12) * 1.0; return `<path d="M${120 - k0} ${y0} L${520 + k0} ${y0} L${520 + k1} ${y1} L${120 - k1} ${y1} Z" fill="rgba(255,255,255,.035)"/>` }).join('')}
  <g fill="none" stroke="rgba(255,255,255,.6)" stroke-width="1.6"><path d="M108 ${LINE} H532"/><path d="M196 ${LINE} L160 226 H480 L444 ${LINE}"/><path d="M258 ${LINE} L250 172 H390 L382 ${LINE}"/><path d="M262 226 Q320 254 378 226"/></g>
  <ellipse cx="320" cy="207" rx="2.2" ry="1" fill="#fff" opacity=".8"/>
  </g>
  <rect width="640" height="340" fill="url(#${id}c)" pointer-events="none"/>${RAIN ? `<style>.rain{animation:rainfall .5s linear infinite}@keyframes rainfall{to{transform:translate(-5px,30px)}}@media (prefers-reduced-motion:reduce){.rain{animation:none}}</style><g class="rain" stroke="rgba(200,215,235,.45)" stroke-width="1.1">${Array.from({ length: SMOOTH ? 30 : 90 }, (_, i) => `<line x1="${(i * 73) % 680}" y1="${(i * 41) % 360 - 20}" x2="${(i * 73) % 680 - 5}" y2="${(i * 41) % 360 + 10}"/>`).join('')}</g><rect width="640" height="340" fill="rgba(40,55,75,.18)"/>` : ''}`
  svg.dataset.id = id
  svg.world = svg.querySelector('[data-world]')
  return svg
}
const ref = (svg, name) => (SMOOTH && name === 'glow' ? 'none' : `url(#${name}${svg.dataset.id})`)
// The camera: zoom z around a point that stays put on screen.
const cam = (svg, z, fx = 320, fy = 170, dx = 0, dy = 0) => sa(svg.world, 'transform', `translate(${fx + dx} ${fy + dy}) scale(${z}) translate(${-fx} ${-fy})`)

// The goal with a net that bulges where the ball hits it.
function goalFrame(svg, p = svg.world) {
  const g = el('g', {}, p), net = el('g', { fill: 'none', stroke: '#C2CDE3', 'stroke-width': 0.65, opacity: 0.6 }, g)
  const lines = []
  const line = (pts) => { const e = el('polyline', { points: pts.map((q) => q.join(',')).join(' ') }, net); lines.push({ e, pts }) }
  // The back of the net seen through the mouth, its roof, and its sides.
  for (let i = 0; i <= 16; i++) { const x = 250 + i * 8.75; line(Array.from({ length: 9 }, (_, j) => [x, 60 + j * 10.5])) }
  for (let j = 0; j <= 8; j++) line(Array.from({ length: 17 }, (_, i) => [250 + i * 8.75, 60 + j * 10.5]))
  for (let i = 0; i <= 14; i++) line([[POSTS[0] + i * 10.57, BAR], [250 + i * 10, 60]])
  for (const [a, b] of [[POSTS[0], 250], [POSTS[1], 390]]) for (let j = 0; j <= 6; j++) line([[a, BAR + j * 13], [b, 60 + j * 12.7]])
  el('path', { d: `M${POSTS[0] + 3} ${LINE + 1} L${POSTS[0] - 10} ${LINE + 5} M${POSTS[1] - 3} ${LINE + 1} L${POSTS[1] + 10} ${LINE + 5}`, stroke: 'rgba(0,0,0,.35)', 'stroke-width': 4 }, g)
  const frame = el('path', { d: `M${POSTS[0]} ${LINE} V${BAR} H${POSTS[1]} V${LINE}`, fill: 'none', stroke: '#fff', 'stroke-width': 4.5, 'stroke-linejoin': 'round', filter: ref(svg, 'glow') }, g)
  let bulged = false
  return {
    g, frame,
    bulge(x0, y0, f) {
      if (f <= 0 && !bulged) return
      bulged = f > 0
      for (const { e, pts } of lines) sa(e, 'points', pts.map(([x, y]) => { const k = f * Math.exp(-((x - x0) ** 2 + (y - y0) ** 2) / 1300); return `${x + (x - x0) * 0.18 * k},${y - 13 * k + (y - y0) * 0.1 * k}` }).join(' '))
    },
  }
}

// A player: legs, shorts, shirt with the number, arms and head, each part posable (running, striking, diving,
// celebrating). look picks the skin and hair. Seen from behind by default; face() turns him to the camera or to his
// side (mirrored for the other side) [Sprint 31 M4]: the live pitch picks it from where he runs.
export const SKINS = ['#C99A78', '#8D5A3B', '#E2B48F', '#6B4027', '#B07B57', '#D9A982', '#5A3524']
export const HAIR = ['#1B1410', '#2A1A10', '#5A3A1E', '#0E0E0E', '#B8893E', '#3B2414']
// [X76] The club's kit pattern on a scene's player, in its trim colour: the side is the one whose shirt this is.
function kitPatternSvg(kit, o) {
  const side = kit === KITS.home?.kit ? 'home' : kit === KITS.away?.kit ? 'away' : null, p = side && !o.gloves ? KITS[side].pattern : null
  if (!p) return ''
  const id = 'kp' + ++uid, c = o.trim ?? KITS[side].trim ?? '#fff'
  const shapes = p === 'stripes' ? [-12, -4, 4, 12].map((x) => `<rect x="${x - 2}" y="-16" width="4" height="42"/>`).join('')
    : p === 'hoops' ? [-8, 1, 10, 19].map((y) => `<rect x="-16" y="${y - 2.2}" width="32" height="4.4"/>`).join('')
    : p === 'halves' ? '<rect x="0" y="-16" width="16" height="42"/>'
    : p === 'sash' ? '<path d="M-16 -6 L-9 -16 L16 16 L16 25 Z"/>' : ''
  return `<clipPath id="${id}"><path d="M-15 -9 Q0 -15 15 -9 L14.5 21 Q0 24 -14.5 21 Z"/></clipPath><g clip-path="url(#${id})" fill="${c}">${shapes}</g>`
}
export function player(p, kit, no, s = 1, o = {}) {
  if (p.world) p = p.world
  const light = lum(kit) > 150, ink = light ? '#0A1F42' : '#fff', look = o.look ?? 0
  const skin = SKINS[look % SKINS.length], hair = HAIR[Math.floor(look / 7) % HAIR.length], shorts = o.shorts ?? (light ? '#1C2B48' : shade(kit, -80))
  const g = el('g', {}, p)
  el('ellipse', { cx: 0, cy: 58, rx: 17, ry: 4.5, fill: 'rgba(0,0,0,.42)' }, g)
  const fig = el('g', {}, g)
  const part = (x, y, html) => { const e = el('g', {}, fig); e.innerHTML = html; return { e, x, y } }
  const leg = `<rect x="-4.5" y="0" width="9" height="15" rx="3.5" fill="${skin}"/><rect x="-4.6" y="12" width="9.2" height="16" rx="3.5" fill="${o.socks ?? (light ? kit : shade(kit, 25))}"/><path d="M-5.5 27 h10 q4.5 0 4.5 3.2 v1.6 h-14.5 z" fill="#0B0F1A"/>`
  const legs = [part(-6, 25, leg), part(6, 25, leg)]
  const body = el('g', {}, fig)
  body.innerHTML = `<path d="M-13.5 17 H13.5 L15 31 H1.5 L0 27 L-1.5 31 H-15 Z" fill="${shorts}"/>
    <path d="M-15 -9 Q0 -15 15 -9 L14.5 21 Q0 24 -14.5 21 Z" fill="${kit}"/>${kitPatternSvg(kit, o)}
    <path d="M-6 21 Q0 -2 6 21" fill="rgba(0,0,0,.08)"/>
    <path d="M-15 -9 Q0 -15 15 -9" fill="none" stroke="${o.trim ?? shade(kit, light ? -45 : 45)}" stroke-width="2"/>
    <text data-back="1" x="0" y="12" text-anchor="middle" font-family="Barlow Condensed, Amin, sans-serif" font-weight="800" font-size="18" fill="${ink}">${no ?? ''}</text>
    <text data-front="1" x="6" y="4" text-anchor="middle" font-family="Barlow Condensed, Amin, sans-serif" font-weight="800" font-size="8" fill="${ink}" display="none">${no ?? ''}</text>`
  const back = body.querySelector('[data-back]'), chest = body.querySelector('[data-front]')
  const arm = `<rect x="-4" y="0" width="8" height="12" rx="3.5" fill="${kit}"/><rect x="-3.4" y="10" width="6.8" height="13" rx="3.4" fill="${o.gloves ? kit : skin}"/>${o.gloves ? `<rect x="-5" y="20" width="10" height="9" rx="3.5" fill="${o.gloves}" stroke="rgba(0,0,0,.35)" stroke-width=".8"/>` : ''}`
  // [Sprint 35 C2] The right hand can hold a card up (the referee's).
  const arms = [part(-14.5, -7, arm), part(14.5, -7, arm + '<rect data-card="1" x="-4.5" y="20" width="9" height="13" rx="1.5" stroke="rgba(0,0,0,.35)" stroke-width=".8" display="none"/>')]
  const cardEl = arms[1].e.querySelector('[data-card]')
  // The head from behind (hair over it), from the front (a face) and from the side (a profile looking right).
  const head = part(0, 0, `<rect x="-3.4" y="-15" width="6.8" height="7" fill="${skin}"/><circle cx="0" cy="-21" r="9.4" fill="${skin}"/>
    <g data-h="back"><path d="M-9.6 -21 Q-10 -32 0 -32.5 Q10 -32 9.6 -21 Q7 -24 3 -24.5 Q-4 -25 -9.6 -21 Z" fill="${hair}"/></g>
    <g data-h="front" display="none"><path d="M-9.6 -22 Q-10 -32 0 -32.5 Q10 -32 9.6 -22 Q6 -28 0 -28 Q-6 -28 -9.6 -22 Z" fill="${hair}"/><circle cx="-3.4" cy="-21" r="1.3" fill="#141414"/><circle cx="3.4" cy="-21" r="1.3" fill="#141414"/><path d="M-2.6 -16.6 Q0 -15 2.6 -16.6" fill="none" stroke="rgba(60,20,10,.6)" stroke-width="1"/></g>
    <g data-h="side" display="none"><path d="M-9.6 -19 Q-11 -32 0 -32.5 Q9 -32 9.4 -24 Q4 -27 -1 -25 Q-3 -20 -9.6 -19 Z" fill="${hair}"/><circle cx="4.6" cy="-22" r="1.3" fill="#141414"/><path d="M9 -21 L11.6 -18.6 L9 -17.6" fill="${skin}"/></g>`)
  const heads = Object.fromEntries([...head.e.querySelectorAll('[data-h]')].map((e) => [e.dataset.h, e]))
  // Facing: 'back', 'front' or 'side'; mirror -1 turns the side profile to the left. Narrower from the side.
  let facing = 'back', mirror = 1, wide = 1
  const setLeg = (i, r, lift) => sa(legs[i].e, 'transform', `translate(${legs[i].x * wide} ${legs[i].y}) rotate(${r}) scale(1 ${1 - 0.45 * lift})`)
  const setArm = (i, r) => sa(arms[i].e, 'transform', `translate(${arms[i].x * (wide < 1 ? 0.12 : 1)} ${arms[i].y}) rotate(${r})`)
  const api = {
    g,
    at(x, y, r = 0, k = s) { sa(g, 'transform', `translate(${x} ${y}) rotate(${r}) scale(${k * mirror} ${k})`) },
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
    // [Sprint 35 C2] A card in the right hand (its colour), or none.
    card(colour) { sa(cardEl, 'display', colour ? 'inline' : 'none'); if (colour) sa(cardEl, 'fill', colour) },
    // Arm angles: 0 hangs down, positive swings the left arm out (the right arm takes the negative).
    pose(l1 = 3, l2 = -3, a1 = 10, a2 = -10, lift1 = 0, lift2 = 0) { setLeg(0, l1, lift1); setLeg(1, l2, lift2); setArm(0, a1); setArm(1, a2) },
    // From the side the legs and arms swing forward and back (a stride); from behind or in front they lift in turn.
    run(ph, amp = 1) {
      const q = Math.sin(ph)
      if (facing === 'side') { const st = 30 * q * amp; api.pose(st, -st, -st * 1.1, st * 1.1, Math.max(0, -q) * amp * 0.5, Math.max(0, q) * amp * 0.5); return }
      api.pose(4, -4, 16 + 24 * q * amp, -16 + 24 * q * amp, Math.max(0, q) * amp, Math.max(0, -q) * amp)
    },
    // Standing: breathing, the arms swaying a little (b 0..1 around the breath).
    idle(b) { const w = Math.sin(b) * 3; api.pose(3, -3, 10 + w, -10 - w) },
    // A strike with the right foot: the leg swings back, then through the ball (f 0..1).
    kick(f) { const r = f < 0.55 ? lerp(-4, -38, f / 0.55) : lerp(-38, 52, ease((f - 0.55) / 0.45)); api.pose(6, r, 34, -48, 0, f < 0.55 ? 0.55 : 0.15) },
    celebrate(t) { const w = Math.sin(t * 9) * 12; api.pose(8, -8, 112 + w, -112 - w) },
    // Hands on hips, the head down: the chance has gone.
    despair() { api.pose(2, -2, 32, -32) },
  }
  api.pose()
  return api
}
// Stands a player on the ground at (x, y): scale and feet follow the depth.
function put(f, x, y, r = 0, k = 1, lift = 0) { const s = persp(y) * k; f.at(x, y - 58 * s - lift, r, s); return s }
// A keeper's kit that stands apart from both teams, with bright gloves.
const keeper = (svg, side, look = 3) => player(svg, keeperKit(side), 1, 1, { gloves: '#E4FF5A', look, shorts: '#111827', socks: keeperKit(side) })

/**
 * The keeper's dive from his spot (x0, ground y0): his gloves reach (gx, gy) at f = 1, then he
 * lands (after 0..1). A ball near his body he takes standing. Returns where his gloves are.
 */
function dive(k, x0, y0, gx, gy, f, after = 0) {
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
function ready(k, x, y, t, crouch = 1) { put(k, x + Math.sin(t * 4.2) * 1.5, y, 0, 1, Math.abs(Math.sin(t * 8.4)) * 1.2); k.pose(12 * crouch, -12 * crouch, 30 + 6 * crouch, -30 - 6 * crouch) }

function ball(svg, p = svg.world) {
  const shadow = el('ellipse', { rx: 6, ry: 2, fill: 'rgba(0,0,0,.45)' }, p)
  const g = el('g', {}, p)
  g.innerHTML = '<circle r="6.5" fill="#F7F8FB"/><g data-spin="1"><path d="M0 -2.6 L2.5 -0.8 L1.6 2.1 L-1.6 2.1 L-2.5 -0.8 Z" fill="#0A1F42"/><path d="M0 -6.5 L0 -2.6 M2.5 -0.8 L6.2 -2 M1.6 2.1 L3.8 5.3 M-1.6 2.1 L-3.8 5.3 M-2.5 -0.8 L-6.2 -2" stroke="#0A1F42" stroke-width=".9"/></g><path d="M-6.5 .5 A6.5 6.5 0 0 0 6.5 .5 A7 5 0 0 1 -6.5 .5Z" fill="rgba(10,31,66,.2)"/>'
  const spin = g.querySelector('[data-spin]')
  return {
    g,
    // Screen point, its depth on the ground (for size and shadow), and how much it has spun.
    set(x, y, ground, turn = 0, op = 1) {
      const s = persp(ground) * 1.05
      sa(g, 'transform', `translate(${x} ${y}) scale(${s})`)
      sa(g, 'opacity', op)
      sa(spin, 'transform', `rotate(${turn})`)
      const h = clamp((ground - y) / 90)
      sa(shadow, 'cx', x + h * 6); sa(shadow, 'cy', ground); sa(shadow, 'rx', 6 * s * (1 - h * 0.5)); sa(shadow, 'ry', 2 * s * (1 - h * 0.5))
      sa(shadow, 'opacity', op * (1 - h * 0.7))
    },
  }
}
function trail(svg, p = svg.world, color = '#FFE7A8') { return el('path', { d: '', fill: 'none', stroke: color, 'stroke-width': 2.5, 'stroke-linecap': 'round', opacity: 0, filter: ref(svg, 'glow') }, p) }
const drawTrail = (trl, path, f, op, from = 0) => { const pts = Array.from({ length: 14 }, (_, i) => bez(path, Math.max(from, f - 0.35) + ((f - Math.max(from, f - 0.35)) * i) / 13)); sa(trl, 'd', 'M' + pts.map((q) => q.join(' ')).join(' L')); sa(trl, 'opacity', op) }
// The headline: a dark band with gold rules sliding in, the word over it.
function title(svg, text, color) {
  const band = el('rect', { x: 0, y: 4, width: 640, height: 60, fill: 'rgba(4,11,28,.75)', opacity: 0 }, svg)
  const r1 = el('rect', { x: 0, y: 4, width: 640, height: 2, fill: ref(svg, 'gold'), opacity: 0 }, svg), r2 = el('rect', { x: 0, y: 62, width: 640, height: 2, fill: ref(svg, 'gold'), opacity: 0 }, svg)
  // [Sprint 30 Q8] A dark edge under the word: read whole over the pitch, the flashes and the band.
  const t = el('text', { x: 320, y: 40, 'text-anchor': 'middle', 'dominant-baseline': 'middle', 'font-family': 'Amin, sans-serif', 'font-weight': 900, 'font-size': 36, fill: color ?? ref(svg, 'gold'), stroke: '#040B1C', 'stroke-width': 5, 'paint-order': 'stroke', 'stroke-linejoin': 'round', opacity: 0 }, svg)
  t.textContent = text
  return (f) => { const e = ease(f); sa(band, 'opacity', f); sa(r1, 'opacity', f); sa(r2, 'opacity', f); sa(r1, 'transform', `translate(${(1 - e) * -640} 0)`); sa(r2, 'transform', `translate(${(1 - e) * 640} 0)`); sa(t, 'opacity', f); sa(t, 'transform', `translate(320 40) scale(${0.8 + 0.2 * e}) translate(-320 -40)`) }
}
function bigNumber(svg, no, kit) {
  const t = el('text', { x: 520, y: 300, 'text-anchor': 'middle', 'font-family': 'Barlow Condensed, Amin, sans-serif', 'font-weight': 800, 'font-style': 'italic', 'font-size': 260, fill: 'none', stroke: kit, 'stroke-width': 2, opacity: 0 }, svg)
  t.textContent = no ?? ''
  return (f) => { sa(t, 'opacity', f * 0.35); sa(t, 'transform', `translate(${(1 - ease(f)) * 60} 0)`) }
}
function flash(svg) { const r = el('rect', { width: 640, height: 340, fill: '#FFF6DA', opacity: 0 }, svg); return (f) => sa(r, 'opacity', f) }
// Camera flashes in the stands after a goal.
function flashes(svg, p = svg.world) { const d = Array.from({ length: 26 }, (_, i) => el('circle', { cx: ((i * 97) % 720) - 40, cy: 12 + ((i * 53) % 100), r: 2.2, fill: '#fff', opacity: 0 }, p)); return (t, on) => d.forEach((c, i) => sa(c, 'opacity', on && Math.sin(t * 23 + i * 7.3) > 0.92 ? 0.95 : 0)) }
const run = (t, a, b) => Math.sin(t * 12) * 4 * (t > a && t < b ? 1 : 0)

/**
 * Open play (goal, save, miss, blocked): the move that leads to the shot, from the engine's
 * own description of the attack (e.lane: left, center, right; e.quality: big = one on one,
 * normal = edge of the box, half = a tight chance among defenders, long = from distance,
 * header = a cross). The ball reaches the goal at KT; what happens then is the outcome.
 */
function openPlay(e, outcome, KT) {
  const R = rnd(e.v ?? (e.no ?? 9) * 977), pick = (a) => a[Math.floor(R() * a.length)]
  const svg = stage(e.side), w = svg.world, atk = K(e.side).kit, dfk = K(other(e.side)).kit
  const q = ['big', 'normal', 'half', 'long', 'header'].includes(e.quality) ? e.quality : pick(['normal', 'normal', 'half', 'long', 'big'])
  const lane = ['left', 'center', 'right'].includes(e.lane) ? e.lane : pick(['left', 'center', 'right'])
  const lx = { left: 248, center: 320, right: 392 }[lane] + (R() - 0.5) * 26, side = lx < 320 ? -1 : 1
  const spot = q === 'header' ? [320 + side * 18 + (R() - 0.5) * 20, 194] : q === 'big' ? [lerp(lx, 320, 0.4), 198] : q === 'long' ? [lx, 292] : q === 'half' ? [lx + side * 22, 226] : [lx, 250]
  const F = { big: 0.36, header: 0.4, normal: 0.5, half: 0.46, long: 0.72 }[q], tS = KT - F
  const tP0 = 0.45, tP1 = q === 'big' ? 0.9 : tS - 0.6

  const G = goalFrame(svg)
  const kp = keeper(svg, other(e.side), Math.floor(R() * 40))
  // Who else is in the picture: the marker on the shooter, a covering centre back, a team-mate arriving.
  // Shirt numbers: the engine's players where it names them, never two the same.
  const free = [7, 10, 11, 8, 17, 6, 14, 20].filter((n) => String(n) !== String(e.no))
  const passNo = e.passNo && String(e.passNo) !== String(e.no) ? e.passNo : free.shift()
  const mateNo = free.filter((n) => String(n) !== String(passNo))[Math.floor(R() * 4)]
  const cover = player(w, dfk, '', 1, { look: Math.floor(R() * 40) })
  const mate = player(w, atk, mateNo, 1, { look: Math.floor(R() * 40) })
  const passer = player(w, atk, passNo, 1, { look: Math.floor(R() * 40) })
  const marker = player(w, dfk, e.defNo ?? '', 1, { look: Math.floor(R() * 40) })
  const sh = player(w, atk, e.no, 1, { look: Math.floor(R() * 40) })
  const b = ball(svg), trl = trail(svg)

  // Where the move starts, and the pass that sets the shooter up.
  const pFrom = q === 'header' ? [side > 0 ? 548 : 92, 214] : q === 'big' ? [Math.max(110, Math.min(530, lx - side * 150)), 290] : [Math.max(110, Math.min(530, spot[0] - side * (130 + R() * 40))), Math.min(300, spot[1] + 18)]
  const sFrom = q === 'header' ? [spot[0] + side * 26, 238] : q === 'big' ? [spot[0] + side * 20, 300] : [spot[0] + side * 34, spot[1] + 46]
  const recv = q === 'header' ? spot : q === 'big' ? [lerp(sFrom[0], spot[0], 0.35), lerp(sFrom[1], spot[1], 0.35)] : [spot[0] + side * 6, spot[1] + 10]

  // Where the ball ends: chosen from the outcome, then the keeper's answer to it.
  const corner = (far) => [side * (far ? -1 : 1) > 0 ? POSTS[1] - 9 - R() * 10 : POSTS[0] + 9 + R() * 10, pick([84, 92, 136, 142, 140])]
  let target, kGoal, kWrong = false, after = 'net'
  // [Sprint 35 C2] How a one-on-one ends: a chip over the keeper coming out, or round him into the empty net.
  const finish = outcome === 'goal' && q === 'big' ? pick(['shot', 'shot', 'chip', 'round']) : 'shot'
  if (outcome === 'goal' && finish === 'chip') {
    target = [320 + side * (8 + R() * 20), 140]
    kGoal = [lerp(320, target[0], 0.4), 150]
  } else if (outcome === 'goal' && finish === 'round') {
    target = [320 - side * (20 + R() * 20), 144]
    kGoal = [320 + side * 40, 170]
  } else if (outcome === 'goal') {
    target = q === 'big' && R() < 0.4 ? [320 + side * (30 + R() * 25), 144] : corner(R() < 0.6)
    kWrong = q !== 'big' && R() < 0.3
    const reach = q === 'long' && target[1] < 100 ? 0.5 : 0.72
    kGoal = kWrong ? [640 - target[0], target[1] + 6] : [lerp(320, target[0], reach), lerp(110, target[1], reach)]
  } else if (outcome === 'save') {
    const high = R() < 0.45
    target = [320 + (R() < 0.5 ? -1 : 1) * (q === 'big' ? 14 + R() * 18 : 20 + R() * 46), high ? 86 + R() * 16 : 118 + R() * 24]
    after = e.corner ? (target[1] < 104 ? 'tip' : 'parry') : Math.abs(target[0] - 320) < 30 ? 'hold' : pick(['hold', 'parry'])
    // [Sprint 35 C2] Different saves: a high ball near him punched clear with both fists, a low one near him blocked
    // with his foot (a one-on-one), a high one wide tipped over.
    if (!e.corner && high && Math.abs(target[0] - 320) < 34 && R() < 0.6) after = 'punch'
    else if (!e.corner && !high && q === 'big' && R() < 0.6) { after = 'foot'; target = [320 + side * (10 + R() * 14), 142] }
    else if (!e.corner && high && Math.abs(target[0] - 320) > 40 && R() < 0.4) after = 'tip'
    kGoal = target
  } else if (outcome === 'miss') {
    const how = e.how ?? 'wide'
    target = how === 'over' ? [300 + R() * 40, 54] : how === 'post' ? [side > 0 ? POSTS[1] : POSTS[0], 96 + R() * 34] : [side > 0 ? POSTS[1] + 16 + R() * 18 : POSTS[0] - 16 - R() * 18, 112 + R() * 30]
    after = how
    kGoal = [lerp(320, target[0], how === 'over' ? 0.15 : 0.6), lerp(110, Math.max(80, target[1]), 0.6)]
  } else {
    // Blocked: the marker throws himself in the way a few steps from the shooter.
    target = [lerp(spot[0], 320, 0.2), lerp(spot[1], LINE, 0.2) - 6]
    after = 'block'
    kGoal = [320, 120]
  }
  const strike = [spot[0] - 3, spot[1] + 2]
  const loft = finish === 'chip' ? 110 : { big: 28, normal: 48, half: 34, long: 70, header: 14 }[q] + (target[1] < 100 ? 22 : 0)
  const path = [strike, [(strike[0] + target[0]) / 2 + side * (R() - 0.3) * 40, Math.min(strike[1], target[1]) - loft], target]
  const groundOf = (f) => lerp(strike[1], outcome === 'blocked' ? target[1] + 6 : LINE + 2, f)
  const kRush = q === 'big' ? (finish === 'shot' ? 22 : 46) : 0, kx0 = () => 320 + (lx - 320) * 0.18
  const party = outcome === 'goal' ? pick(['corner', 'slide', 'leap', 'crowd', 'pile']) : null
  const out = side > 0 ? 1 : -1
  let landed = null

  return { svg, go: (t) => {
    // The camera closes in as the chance builds, and stays on the goal for the outcome.
    cam(svg, 1.02 + 0.16 * inout(seg(t, tP0, tS + 0.1)) - (outcome === 'goal' ? 0.08 * inout(seg(t, KT + 0.9, KT + 2)) : 0), 320, 168)

    // The team-mate and the covering defender.
    const mt = ease(seg(t, 0.2, KT + 0.4)); put(mate, lerp(640 - lx + side * 30, 640 - lx - side * 10, mt), lerp(262, 214, mt)); mate.run(t * 13, mt < 1 ? 0.8 : 0.1)
    const ct = ease(seg(t, 0.3, tS)); put(cover, lerp(320 - side * 40, lerp(spot[0], 320, 0.55), ct), lerp(204, 196, ct)); cover.run(t * 12, ct < 1 ? 0.7 : 0.15)

    // The passer: the ball at his feet, then the pass (on the ground, or the cross in the air).
    // ... and after it he follows the move up the pitch.
    const pt = seg(t, 0, tP0), fw = ease(seg(t, tP0 + 0.25, KT + 1)) * 0.35
    put(passer, lerp(lerp(pFrom[0] + side * 18, pFrom[0], ease(pt)), spot[0], fw), lerp(pFrom[1], spot[1] + 20, fw))
    if (t < tP0 - 0.15) passer.run(t * 12); else if (t < tP0 + 0.25) passer.kick(seg(t, tP0 - 0.15, tP0 + 0.15)); else passer.run(t * 12, fw < 0.35 ? 0.8 : 0.1)

    // The shooter: runs onto it, a touch to set himself, the strike (or the leap for a header).
    let sx, sy, lift = 0
    if (t < tP1) { const f = inout(seg(t, 0.1, tP1)); sx = lerp(sFrom[0], recv[0], f); sy = lerp(sFrom[1], recv[1], f) }
    else { const f = inout(seg(t, tP1, tS)); sx = lerp(recv[0], spot[0], f); sy = lerp(recv[1], spot[1], f) }
    if (q === 'header') lift = 26 * Math.sin(Math.PI * seg(t, tS - 0.32, tS + 0.3))
    // Round the keeper: a touch past him to the side, then the finish.
    if (finish === 'round') sx -= side * 36 * ease(seg(t, tS - 0.5, tS - 0.05))
    put(sh, sx, sy, q === 'header' ? -side * 8 * seg(t, tS - 0.3, tS) : 0, 1, lift)
    if (t > KT + 0.5 && outcome === 'goal') {
      // [Sprint 36 F1] The celebration, one of five (from the scene's seed): away to the corner flag arms out, a
      // slide on his knees, a leap punching the air, arms wide towards the crowd, or his team-mates piling on him.
      const c = ease(seg(t, KT + 0.5, KT + 2.6))
      if (party === 'slide') {
        const sl = ease(seg(t, KT + 0.7, KT + 1.6)); put(sh, lerp(spot[0], spot[0] + out * 120, c), lerp(spot[1], spot[1] + 40, c), -out * 18 * sl, 1, -10 * sl); sh.pose(70, 70, 140, -140)
      } else if (party === 'leap') {
        const up = Math.abs(Math.sin((t - KT) * 5)) * 22 * seg(t, KT + 0.6, KT + 0.9); put(sh, lerp(spot[0], spot[0] + out * 40, c), spot[1] + 10, 0, 1, up); sh.pose(10, -10, 175, -20)
      } else if (party === 'crowd') {
        put(sh, lerp(spot[0], 320 + out * 30, c), lerp(spot[1], 300, c), 0, 1.15); sh.face?.('front'); sh.pose(6, -6, 95, -95)
      } else if (party === 'pile') {
        put(sh, lerp(spot[0], spot[0] + out * 60, c), lerp(spot[1], spot[1] + 20, c)); sh.celebrate(t)
      } else { put(sh, lerp(spot[0], spot[0] + out * 150, c), lerp(spot[1], spot[1] + 30, c)); sh.celebrate(t) }
      // The team-mates: the one nearest runs to him, and in a pile-on the passer too, arms around him.
      const near = party === 'pile' ? 0.92 : 0.8
      put(mate, lerp(640 - lx - side * 10, lerp(spot[0], spot[0] + out * 150, c) - out * 18 * (1 - near), c), lerp(214, spot[1] + 30, c)); mate.celebrate(t + 0.4)
      if (party === 'pile') { const pc = ease(seg(t, KT + 0.8, KT + 2.4)); put(passer, lerp(spot[0] - side * 60, spot[0] + out * 66, pc), lerp(spot[1] + 30, spot[1] + 26, pc)); passer.pose(6, -6, 120, -60) }
    } else if (t > KT + 0.3 && outcome !== 'goal') sh.despair()
    else if (q === 'header' && t > tS - 0.35) sh.pose(10, -10, 60, -60, 0.4, 0.4)
    else if (t > tS - 0.32 && t < tS + 0.3) sh.kick(seg(t, tS - 0.32, tS + 0.12))
    else sh.run(t * 13, t < tS ? 1 : 0.2)

    // The marker chases from behind; on a block he slides across the shot.
    const mk = ease(seg(t, 0.1, tS))
    let mx = lerp(sFrom[0] + side * 30, sx + side * 16, mk), my = lerp(sFrom[1] - 12, sy - 8, mk), mr = 0
    let low = 0
    if (outcome === 'blocked') { const sl = ease(seg(t, tS - 0.3, KT)); mx = lerp(mx, target[0] + side * 10, sl); my = lerp(my, target[1] + 6, sl); mr = -side * 72 * sl; low = -30 * persp(my) * sl }
    put(marker, mx, my, mr, 1, low); outcome === 'blocked' && t > tS - 0.3 ? marker.pose(30, -30, 80, -40) : marker.run(t * 12.5, mk < 1 ? 1 : 0.3)
    if (outcome === 'goal' && t > KT + 0.4) marker.despair()

    // The keeper: on his line (or rushing out one on one), then the dive.
    const ky = LINE + 2 + kRush * ease(seg(t, tP0, tS))
    const k0 = lerp(320, kx0(), ease(seg(t, 0, tS)))
    let glove = null
    const tD = tS + (kWrong ? 0.02 : 0.1)
    if (t < tD) ready(kp, k0 + (sx - 320) * 0.08, ky, t, q === 'big' ? 1.4 : 1)
    else {
      const f = seg(t, tD, KT), a = seg(t, KT + 0.25, KT + 0.9)
      if (after === 'punch') { const j = Math.sin(Math.PI * Math.min(1, f * 1.2)); put(kp, lerp(k0, target[0], f), ky, 0, 1, 26 * j); kp.pose(10, -10, 172, -172, 0.3, 0.3); glove = [target[0], target[1]] }
      else if (after === 'foot') { put(kp, lerp(k0, target[0] - side * 8, f), ky + 6 * f); kp.pose(6, -64 * f * side, 40, -40); glove = [target[0], target[1]] }
      else glove = after === 'block' ? (ready(kp, k0, ky, t), null) : dive(kp, k0, ky, kGoal[0], kGoal[1], f, a)
      if (outcome === 'goal' && t > KT + 1.6) kp.pose(4, -4, 150, -150)
    }

    // The ball.
    let bx, by, gr, turn = t * 900, op = 1
    if (t < tP0) { bx = pFrom[0] - 2; by = pFrom[1] + 1; gr = by }
    else if (t < tP1) {
      const f = seg(t, tP0, tP1)
      if (q === 'header') { const p = bez([pFrom, [lerp(pFrom[0], recv[0], 0.5), 96], [recv[0], recv[1] - 46]], f); bx = p[0]; by = p[1]; gr = lerp(pFrom[1], recv[1], f) }
      else { bx = lerp(pFrom[0], recv[0], ease(f)); by = lerp(pFrom[1] + 1, recv[1] + 1, ease(f)); gr = by }
    } else if (t < tS) {
      if (q === 'header') { bx = recv[0]; by = recv[1] - 46; gr = recv[1] }
      else { bx = sx + side * -3 + Math.sin(t * 13) * 2; by = sy + 2; gr = by }
    } else if (t < KT) {
      const f = seg(t, tS, KT), from = q === 'header' ? [spot[0], spot[1] - 46] : strike
      const p = bez([from, path[1], target], f); bx = p[0]; by = p[1]; gr = groundOf(f)
      drawTrail(trl, [from, path[1], target], f, 0.55)
      turn = t * 2400
    } else {
      // What happens once it gets there.
      const a = t - KT
      sa(trl, 'opacity', Math.max(0, 0.55 - a * 1.5))
      if (after === 'net') { const f = ease(clamp(a / 0.18)), d = clamp((a - 0.18) / 0.5); bx = target[0] + (target[0] - 320) * 0.05 * f; by = lerp(target[1] - 10 * f, 146, d * d) - Math.abs(Math.sin(d * 9)) * 4 * (1 - d); gr = LINE - 8 }
      else if (after === 'hold') { landed ??= glove; bx = (glove ?? landed)[0]; by = (glove ?? landed)[1]; gr = LINE + 2; turn = 0 }
      else if (after === 'parry') { const f = ease(clamp(a / 0.8)), dx = Math.sign(target[0] - 320) || 1; const p = bez([target, [target[0] + dx * 70, target[1] - 26], [target[0] + dx * (e.corner ? 150 : 96), 196]], f); bx = p[0]; by = p[1] - Math.abs(Math.sin(f * 7)) * 8 * (1 - f); gr = lerp(LINE, 196, f) }
      else if (after === 'punch') { const f = ease(clamp(a / 0.8)); const p = bez([target, [target[0] + (target[0] - 320) * 2, target[1] - 40], [target[0] + (target[0] >= 320 ? 120 : -120), 230]], f); bx = p[0]; by = p[1]; gr = lerp(LINE, 230, f) }
      else if (after === 'foot') { const f = ease(clamp(a / 0.8)); const p = bez([target, [target[0] - side * 50, target[1] + 10], [target[0] - side * 150, 220]], f); bx = p[0]; by = p[1]; gr = lerp(LINE + 4, 220, f) }
      else if (after === 'tip') { const f = ease(clamp(a / 0.7)); bx = target[0] + Math.sign(target[0] - 320) * 26 * f; by = lerp(target[1], 30, f); gr = LINE - 10 * f; op = 1 - seg(a, 0.45, 0.7) }
      else if (after === 'post') { const f = ease(clamp(a / 0.9)); const p = bez([target, [lerp(target[0], 320, 0.3), target[1] + 10], [lerp(target[0], 320, 0.55), 212]], f); bx = p[0]; by = p[1] - Math.abs(Math.sin(f * 6)) * 10 * (1 - f); gr = lerp(LINE, 212, f) }
      else if (after === 'block') { const f = ease(clamp(a / 0.9)); const p = bez([target, [target[0] + side * 60, target[1] - 40], [target[0] + side * 160, target[1] + 40]], f); bx = p[0]; by = p[1]; gr = lerp(target[1] + 6, target[1] + 40, f) }
      else { const f = clamp(a / 0.7); bx = target[0] + (target[0] - strike[0]) * 0.18 * f; by = target[1] - 30 * f; gr = LINE - 20 * f; op = 1 - f }
    }
    b.set(bx, by, gr, turn, op)
    if (after === 'net') G.bulge(target[0], target[1] - 8, seg(t, KT, KT + 0.1) * (1 - seg(t, KT + 0.25, KT + 1.2)))
    if (after === 'post') sa(G.frame, 'transform', `translate(${Math.sin(t * 70) * 1.8 * seg(t, KT, KT + 0.05) * (1 - seg(t, KT + 0.1, KT + 0.6))} 0)`)
    return { target }
  } }
}

// ---------------------------------------------------------------- scenes: one per kind of moment
// Lengths and key moments are SCENE_TIME in story.ts; keep them in step.
export const SCENES = {
  goal(e) {
    const KT = 3.0, { svg, go } = openPlay(e, 'goal', KT)
    const num = bigNumber(svg, e.no, K(e.side).kit), fl = flash(svg), cf = flashes(svg), tt = title(svg, tr('هدف!'))
    return { dur: 6.0, svg, update(t) {
      go(t); num(seg(t, KT + 0.6, KT + 1.4)); cf(t, t > KT)
      fl(seg(t, KT - 0.01, KT + 0.05) * (1 - seg(t, KT + 0.05, KT + 0.25)) * 0.16)
      tt(seg(t, KT + 0.2, KT + 0.6))
    } }
  },
  save(e) {
    const KT = 2.9, { svg, go } = openPlay(e, 'save', KT)
    const ring = el('circle', { r: 26, fill: 'none', stroke: '#2BB673', 'stroke-width': 3, opacity: 0, filter: ref(svg, 'glow') }, svg.world)
    const tt = title(svg, tr('تصدٍّ رائع'), '#2BB673')
    return { dur: 5.4, svg, update(t) {
      const { target } = go(t)
      const s = seg(t, KT - 0.02, KT + 0.6); sa(ring, 'transform', `translate(${target[0]} ${target[1]}) scale(${0.4 + s * 1.6})`); sa(ring, 'opacity', s > 0 ? 1 - s : 0)
      tt(seg(t, KT + 0.3, KT + 0.7))
    } }
  },
  miss(e) {
    const KT = 2.9, { svg, go } = openPlay(e, 'miss', KT)
    const tt = title(svg, e.how === 'post' ? tr('القائم!') : e.how === 'over' ? tr('فوق العارضة') : tr('بجانب القائم'), '#C9D2E1')
    return { dur: 5.0, svg, update(t) { go(t); tt(seg(t, KT + 0.35, KT + 0.75)) } }
  },
  blocked(e) {
    const KT = 2.6, { svg, go } = openPlay(e, 'blocked', KT)
    const ring = el('circle', { r: 22, fill: 'none', stroke: '#7FB4FF', 'stroke-width': 3, opacity: 0, filter: ref(svg, 'glow') }, svg.world)
    const tt = title(svg, tr('صدّها الدفاع'), '#7FB4FF')
    return { dur: 4.8, svg, update(t) {
      const { target } = go(t)
      const s = seg(t, KT - 0.02, KT + 0.6); sa(ring, 'transform', `translate(${target[0]} ${target[1]}) scale(${0.4 + s * 1.5})`); sa(ring, 'opacity', s > 0 ? 1 - s : 0)
      tt(seg(t, KT + 0.3, KT + 0.7))
    } }
  },
  penalty(e) {
    const R = rnd(e.v ?? (e.no ?? 9) * 31), svg = stage(e.side), w = svg.world, G = goalFrame(svg)
    const kp = keeper(svg, other(e.side), Math.floor(R() * 40)), tk = player(w, K(e.side).kit, e.no, 1, { look: Math.floor(R() * 40) }), b = ball(svg), trl = trail(svg)
    const hush = el('text', { x: 320, y: 30, 'text-anchor': 'middle', 'font-family': 'IBM Plex Sans Arabic, sans-serif', 'font-weight': 600, 'font-size': 15, fill: '#C9D2E1', opacity: 0 }, svg); hush.textContent = tr('صمت في المدرجات...')
    const tt = title(svg, e.scored ? tr('هدف!') : tr('تصدٍّ!'), e.scored ? undefined : '#2BB673'), fl = flash(svg), cf = flashes(svg)
    const KT = 2.85, tS = 2.45, dir = R() < 0.5 ? -1 : 1
    // [Sprint 36 F2] The face-off before the kick, as on TV: the taker and the keeper in two panels, eye to eye.
    const vs = el('g', { opacity: 0 }, svg)
    vs.innerHTML = `<rect x="0" y="50" width="320" height="250" fill="${K(e.side).kit}" opacity=".9"/><rect x="320" y="50" width="320" height="250" fill="${keeperKit(other(e.side))}" opacity=".9"/>`
      + `<path d="M300 50 L340 50 L320 300 L280 300 Z" fill="#071733"/><text x="310" y="186" text-anchor="middle" font-family="Barlow Condensed, sans-serif" font-style="italic" font-weight="800" font-size="44" fill="#F5B82E">VS</text>`
    const fT = player(vs, K(e.side).kit, e.no, 2.2, { look: Math.floor(R() * 40) }), fK = player(vs, keeperKit(other(e.side)), 1, 2.2, { gloves: '#E4FF5A', look: Math.floor(R() * 40), shorts: '#111827' })
    const target = e.scored ? [320 + dir * (48 + R() * 12), R() < 0.5 ? 140 : 90] : [320 + dir * (30 + R() * 20), 110 + R() * 30]
    const kAim = e.scored ? (R() < 0.6 ? [640 - target[0], target[1]] : [lerp(320, target[0], 0.7), target[1] + 8]) : target
    const spot = [320, 207], path = [[spot[0], spot[1]], [lerp(spot[0], target[0], 0.5), Math.min(spot[1], target[1]) - 18], target]
    return { dur: 5.6, svg, update(t) {
      cam(svg, 1.15 + 0.1 * inout(seg(t, 0.3, tS)), 320, 160)
      sa(hush, 'opacity', seg(t, 0.2, 0.6) * (1 - seg(t, 2, 2.3)))
      const v = SMOOTH ? 0 : seg(t, 0.05, 0.25) * (1 - seg(t, 1.0, 1.2))
      sa(vs, 'opacity', v)
      if (v > 0) { fT.face?.('side', 1); fT.at(170 + (1 - ease(seg(t, 0.05, 0.4))) * -60, 180, 0, 1.9); fT.pose(4, -4, 14, -14); fK.face?.('side', -1); fK.at(470 + (1 - ease(seg(t, 0.05, 0.4))) * 60, 180, 0, 1.9); fK.pose(12, -12, 50, -50) }
      // The run-up from the edge of the box, a stutter, then the kick.
      const f = inout(seg(t, 1.1, tS)); put(tk, lerp(352, 324, f), lerp(256, spot[1] + 6, f))
      if (t < 1.1) tk.pose(4, -4, 8, -8); else if (t < tS - 0.3) tk.run(t * 11, 0.8); else tk.kick(seg(t, tS - 0.3, tS + 0.12))
      if (t > KT + 0.6 && e.scored) tk.celebrate(t)
      if (t > KT + 0.4 && !e.scored) tk.despair()
      // The keeper bounces on his line, then goes.
      let glove = null
      if (t < tS) { ready(kp, 320 + Math.sin(t * 2.4) * 6, LINE + 2, t, 1.3); kp.pose(14, -14, 52 + Math.sin(t * 6) * 8, -52 - Math.sin(t * 6) * 8) }
      else glove = dive(kp, 320, LINE + 2, kAim[0], kAim[1], seg(t, tS + 0.03, KT), seg(t, KT + 0.2, KT + 0.85))
      let p, gr = LINE + 2
      if (t < tS) { p = spot; gr = spot[1] }
      else if (t < KT) { const g = seg(t, tS, KT); p = bez(path, g); gr = lerp(spot[1], LINE + 2, g); drawTrail(trl, path, g, 0.55) }
      else if (e.scored) { const a = t - KT, d = clamp((a - 0.15) / 0.5); p = [target[0], lerp(target[1] - 8 * ease(clamp(a / 0.15)), 146, d * d)]; gr = LINE - 8; sa(trl, 'opacity', 0) }
      else { const a = ease(clamp((t - KT) / 0.8)); p = bez([target, [target[0] - dir * 30, target[1] - 30], [target[0] + dir * 110, 200]], a); gr = lerp(LINE, 200, a); sa(trl, 'opacity', 0) }
      b.set(p[0], p[1], gr, t > tS ? t * 2000 : 0)
      if (e.scored) { G.bulge(target[0], target[1] - 8, seg(t, KT, KT + 0.1) * (1 - seg(t, KT + 0.25, KT + 1.2))); fl(seg(t, KT - 0.01, KT + 0.05) * (1 - seg(t, KT + 0.05, KT + 0.25)) * 0.16); cf(t, t > KT) }
      tt(seg(t, KT + 0.2, KT + 0.6))
    } }
  },
  freekick(e) {
    const R = rnd(e.v ?? (e.no ?? 9) * 53), svg = stage(e.side), w = svg.world, G = goalFrame(svg)
    const kp = keeper(svg, other(e.side), Math.floor(R() * 40))
    const wall = [0, 1, 2, 3].map((i) => player(w, K(other(e.side)).kit, '', 1, { look: Math.floor(R() * 40) }))
    const tk = player(w, K(e.side).kit, e.no, 1, { look: Math.floor(R() * 40) }), b = ball(svg), trl = trail(svg)
    const fl = flash(svg), cf = flashes(svg)
    const KT = 2.65, tS = 1.85, side = R() < 0.5 ? -1 : 1, spot = [320 - side * 50, 252]
    const target = e.scored ? [side > 0 ? POSTS[1] - 12 : POSTS[0] + 12, 84 + R() * 8] : e.saved ? [320 + side * (44 + R() * 14), 92 + R() * 14] : [320 + side * 20, 50]
    const path = [spot, [lerp(spot[0], target[0], 0.4) - side * 30, 30], target]
    const tt = title(svg, e.scored ? tr('هدف!') : e.saved ? tr('تصدٍّ!') : tr('فوق العارضة'), e.scored ? undefined : e.saved ? '#2BB673' : '#C9D2E1')
    return { dur: 5.2, svg, update(t) {
      cam(svg, 1.06 + 0.1 * inout(seg(t, 0.2, tS)), 320, 165)
      // The wall, nine metres off, jumps as the kick is taken.
      const jump = 14 * Math.sin(Math.PI * seg(t, tS - 0.05, tS + 0.45))
      wall.forEach((p, i) => { put(p, spot[0] + side * 20 + (i - 1.5) * 15, 218, 0, 1, jump); p.pose(4, -4, 4, -4, jump > 1 ? 0.5 : 0, jump > 1 ? 0.5 : 0) })
      const f = inout(seg(t, 0.6, tS)); put(tk, lerp(spot[0] - side * 30, spot[0] - side * 5, f), lerp(spot[1] + 30, spot[1] + 6, f))
      if (t < 0.6) tk.pose(3, -3, 20, -20); else if (t < tS - 0.3) tk.run(t * 11, 0.7); else tk.kick(seg(t, tS - 0.3, tS + 0.12))
      if (t > KT + 0.6 && e.scored) tk.celebrate(t)
      if (t < tS + 0.12) ready(kp, 320 - side * 14, LINE + 2, t)
      else dive(kp, 320 - side * 14, LINE + 2, e.scored ? lerp(320, target[0], 0.75) : e.saved ? target[0] : lerp(320, target[0], 0.4), e.scored ? target[1] + 8 : Math.max(86, target[1]), seg(t, tS + 0.12, KT), seg(t, KT + 0.2, KT + 0.9))
      let p, gr
      if (t < tS) { p = spot; gr = spot[1] }
      else if (t < KT) { const g = seg(t, tS, KT); p = bez(path, g); gr = lerp(spot[1], LINE + 2, g); drawTrail(trl, path, g, 0.6) }
      else if (e.scored) { const a = t - KT, d = clamp((a - 0.15) / 0.5); p = [target[0], lerp(target[1] - 8 * ease(clamp(a / 0.15)), 146, d * d)]; gr = LINE - 8; sa(trl, 'opacity', 0) }
      else if (e.saved) { const a = ease(clamp((t - KT) / 0.8)); p = bez([target, [target[0] + side * 40, target[1] - 20], [target[0] + side * 120, 190]], a); gr = lerp(LINE, 190, a); sa(trl, 'opacity', 0) }
      else { const a = clamp((t - KT) / 0.7); p = [target[0] + side * 12 * a, target[1] - 28 * a]; gr = LINE - 20 * a; sa(trl, 'opacity', 0) }
      b.set(p[0], p[1], gr, t > tS ? t * 1600 : 0, !e.scored && !e.saved ? 1 - seg(t, KT + 0.3, KT + 0.7) : 1)
      if (e.scored) { G.bulge(target[0], target[1] - 8, seg(t, KT, KT + 0.1) * (1 - seg(t, KT + 0.25, KT + 1.2))); fl(seg(t, KT - 0.01, KT + 0.05) * (1 - seg(t, KT + 0.05, KT + 0.25)) * 0.16); cf(t, t > KT) }
      tt(seg(t, KT + 0.2, KT + 0.6))
    } }
  },
  corner(e) {
    const R = rnd(e.v ?? (e.no ?? 9) * 71), svg = stage(e.side), w = svg.world, G = goalFrame(svg)
    const kp = keeper(svg, other(e.side), Math.floor(R() * 40))
    const pack = [0, 1, 2].map((i) => player(w, i % 2 ? K(e.side).kit : K(other(e.side)).kit, '', 1, { look: Math.floor(R() * 40) }))
    const df = player(w, K(other(e.side)).kit, '', 1, { look: Math.floor(R() * 40) }), hd = player(w, K(e.side).kit, e.no, 1, { look: Math.floor(R() * 40) })
    const b = ball(svg), trl = trail(svg)
    el('path', { d: 'M598 214 V184', stroke: '#DDE3F0', 'stroke-width': 2 }, w); el('path', { d: 'M599 184 L614 189 L599 194 Z', fill: '#F5B82E' }, w)
    const from = [596, 214], head = [326, 186], path = [from, [470, 20], [head[0], head[1] - 44]]
    const tt = title(svg, e.claim ? tr('الحارس يمسكها') : tr('رأسية!'), e.claim ? '#2BB673' : '#C9D2E1')
    return { dur: 4.6, svg, update(t) {
      cam(svg, 1.12, 360, 170)
      const f = seg(t, 0.6, 1.7), jump = 24 * Math.sin(Math.PI * seg(t, 1.35, 2.05))
      put(hd, lerp(346, head[0], ease(seg(t, 0, 1.4))), head[1], 0, 1, jump); jump > 1 ? hd.pose(10, -10, 70, -70, 0.4, 0.4) : hd.run(t * 12, 0.6)
      put(df, lerp(310, head[0] + 16, ease(seg(t, 0, 1.4))), head[1] - 4, 0, 1, jump * 0.6); jump > 1 ? df.pose(8, -8, 60, -60, 0.3, 0.3) : df.run(t * 11, 0.5)
      pack.forEach((p, i) => { put(p, 290 + i * 40 + Math.sin(t * 3 + i) * 6, 200 + (i % 2) * 12); p.run(t * 10 + i, 0.4) })
      let glove = null
      if (e.claim) { const c = seg(t, 1.2, 1.7); glove = dive(kp, 320, LINE + 2, lerp(320, head[0] + 4, 0.8), lerp(120, 96, c), c, 0) }
      else ready(kp, 322, LINE + 2, t)
      let p, gr
      if (t < 0.6) { p = from; gr = from[1] }
      else if (t < 1.7) { const g = ease(f); p = bez(path, g); gr = lerp(from[1], head[1], g); drawTrail(trl, path, g, 0.5) }
      else if (e.claim) { p = glove ?? [head[0], 100]; gr = LINE + 2; sa(trl, 'opacity', 0) }
      else { const g = ease(seg(t, 1.7, 2.4)); p = bez([[head[0], head[1] - 44], [head[0] - 6, 60], [head[0] - 10, 40]], g); gr = lerp(head[1], LINE - 10, g); sa(trl, 'opacity', 0) }
      b.set(p[0], p[1], gr, t * 1200, e.claim ? 1 : 1 - seg(t, 2.2, 2.5))
      tt(seg(t, 2.2, 2.6))
    } }
  },
  // [Sprint 35 C2] The card: the referee holds it up over the offender, who protests (arms out, or hands together
  // pleading); a red, and he walks off, head down, past his team-mate.
  card(e) {
    const svg = stage(e.side), w = svg.world, red = e.type === 'red', col = red ? '#EF4444' : '#FFD400', R = rnd(e.v ?? (e.no ?? 4) * 13)
    const rf = player(w, officialKit(), '', 1.5, { look: 9, shorts: '#111827', socks: '#111827', trim: '#F5B82E' })
    const pl = player(w, K(e.side).kit, e.no, 1.5, { look: Math.floor(R() * 40) })
    const mate = red ? player(w, K(e.side).kit, '', 1.3, { look: Math.floor(R() * 40) }) : null
    const glow = el('circle', { cx: 250, cy: 120, r: 70, fill: col, opacity: 0, filter: ref(svg, 'soft') }, w)
    const plead = R() < 0.5
    const tt = title(svg, red ? tr('طرد!') : tr('إنذار'), col)
    return { dur: 4.4, svg, update(t) {
      cam(svg, 1.08, 320, 200)
      rf.face?.('front'); pl.face?.('front')
      rf.at(250, 196, 0, 1.5)
      const up = ease(seg(t, 0.5, 1.0))
      rf.pose(3, -3, 12, -12 - 156 * up)
      rf.card(up > 0.05 ? col : null)
      sa(glow, 'opacity', 0.4 * seg(t, 0.9, 1.3))
      // The offender: protests, then (a red) walks away.
      const go = red ? ease(seg(t, 2.0, 4.4)) : 0
      pl.at(lerp(400, 700, go), 200 + go * 20, 0, 1.5)
      if (go > 0) { pl.face?.('side', 1); pl.run(t * 6, 0.25); pl.despair() }
      else if (t > 1.0) { const w2 = Math.sin(t * 7) * 10; plead ? pl.pose(4, -4, 60 + w2, -60 - w2) : pl.pose(6, -6, 96 + w2, -96 - w2) }
      else pl.pose()
      if (mate) { mate.at(lerp(520, 470, ease(seg(t, 1.5, 2.5))), 214, 0, 1.3); mate.pose(3, -3, 40, -40) }
      tt(seg(t, 1.1, 1.5))
    } }
  },
  // [Sprint 35 C2] After a red card: players of both sides square up and push, the referee steps in between them.
  brawl(e) {
    const svg = stage(e.side), w = svg.world, R = rnd(e.v ?? 11)
    const a = [0, 1, 2].map((i) => player(w, K(e.side).kit, '', 1.3, { look: Math.floor(R() * 40) }))
    const b = [0, 1, 2].map((i) => player(w, K(other(e.side)).kit, '', 1.3, { look: Math.floor(R() * 40) }))
    const rf = player(w, officialKit(), '', 1.35, { look: 9, shorts: '#111827', socks: '#111827', trim: '#F5B82E' })
    const tt = title(svg, tr('توتر في الملعب'), '#EF4444')
    return { dur: 2.8, svg, update(t) {
      cam(svg, 1.12 + 0.05 * Math.sin(t * 2), 320, 200)
      const shove = Math.sin(t * 9)
      a.forEach((p, i) => { p.face?.('side', 1); p.at(250 + i * 18 + shove * (i === 1 ? 10 : 4), 200 + i * 14, shove * 6, 1.3); p.pose(10, -10, 80 + shove * 30, 70 - shove * 20) })
      b.forEach((p, i) => { p.face?.('side', -1); p.at(390 - i * 18 - shove * (i === 1 ? 10 : 4), 204 + i * 12, -shove * 6, 1.3); p.pose(10, -10, 80 - shove * 30, 70 + shove * 20) })
      rf.face?.('front'); rf.at(320, 214, 0, 1.35); rf.pose(3, -3, 100 + Math.sin(t * 6) * 10, -100 - Math.sin(t * 6) * 10)
      tt(seg(t, 0.2, 0.6))
    } }
  },
  offside(e) {
    const svg = stage(e.side)
    const defs = [0, 1, 2, 3].map(() => player(svg, K(other(e.side)).kit, '', 0.9)), rn = player(svg, K(e.side).kit, e.no, 1.1)
    const line = el('line', { x1: 120, y1: 214, x2: 520, y2: 214, stroke: '#EF4444', 'stroke-width': 3, 'stroke-dasharray': '10 7', opacity: 0, filter: ref(svg, 'glow') }, svg)
    const fr = el('rect', { width: 640, height: 340, fill: 'rgba(30,70,160,.18)', opacity: 0 }, svg)
    const flag = el('g', { opacity: 0 }, svg); flag.innerHTML = '<rect x="-1.5" y="0" width="3" height="46" fill="#DDE3F0"/><path d="M1.5 2 H30 L24 12 L30 22 H1.5 Z" fill="#EF4444"/>'
    const tt = title(svg, tr('تسلل'), '#EF4444')
    return { dur: 4.2, svg, update(t) {
      const fz = t > 1.5 && t < 2.6
      defs.forEach((d, i) => d.at(200 + i * 80, 220, 0, 0.9))
      rn.at(lerp(330, 300, ease(seg(t, 0, 1.4))), lerp(260, 196, ease(seg(t, 0, 1.4))), 0, 1.1)
      sa(line, 'opacity', seg(t, 1.4, 1.7)); sa(fr, 'opacity', fz ? 1 : 0)
      sa(flag, 'opacity', seg(t, 1.2, 1.4)); sa(flag, 'transform', `translate(560 ${lerp(250, 170, ease(seg(t, 1.2, 1.5)))}) rotate(${Math.sin(t * 9) * 8})`)
      tt(seg(t, 2.4, 2.8))
    } }
  },
  sub(e) {
    const svg = stage(e.side), k = K(e.side).kit
    const out = player(svg, k, e.outNo, 1.5), inn = player(svg, k, e.inNo, 1.5)
    const board = el('g', {}, svg)
    board.innerHTML = `<rect x="-62" y="-44" width="124" height="88" rx="10" fill="#071733" stroke="rgba(245,184,46,.6)" stroke-width="2"/><text x="-26" y="-2" text-anchor="middle" font-family="Barlow Condensed, sans-serif" font-weight="800" font-size="36" fill="#EF4444">${e.outNo ?? ''}</text><text x="26" y="-2" text-anchor="middle" font-family="Barlow Condensed, sans-serif" font-weight="800" font-size="36" fill="#2BB673">${e.inNo ?? ''}</text><path d="M-26 12 V32 M-32 26 L-26 34 L-20 26" stroke="#EF4444" stroke-width="3" fill="none"/><path d="M26 34 V14 M20 20 L26 12 L32 20" stroke="#2BB673" stroke-width="3" fill="none"/>`
    return { dur: 4.2, svg, update(t) {
      sa(board, 'transform', `translate(320 ${lerp(400, 110, ease(seg(t, 0, 0.6)))})`)
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
      sa(med, 'transform', `translate(440 120) scale(${0.9 + 0.1 * Math.sin(t * 6)})`); sa(halo, 'opacity', 0.15 + 0.1 * Math.sin(t * 6))
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
    const chip = el('g', { opacity: 0 }, svg); chip.innerHTML = `<rect x="-150" y="-20" width="300" height="40" rx="20" fill="${ref(svg, 'gold')}"/><text y="7" text-anchor="middle" font-family="Amin, sans-serif" font-weight="800" font-size="18" fill="#071733">${e.tactic ?? ''}</text>`
    return { dur: 4.6, svg, update(t) {
      sa(tab, 'transform', `translate(320 ${lerp(380, 158, ease(seg(t, 0, 0.6)))}) scale(.9)`)
      const push = ease(seg(t, 1, 2)); dots.forEach((d) => { sa(d, 'cx', +d.dataset.x + (+d.dataset.x > -100 ? push * 26 : 0)); sa(d, 'cy', d.dataset.y) })
      A.forEach((a, i) => sa(a, 'stroke-dashoffset', 80 * (1 - ease(seg(t, 0.9 + i * 0.15, 1.6 + i * 0.15)))))
      sa(chip, 'opacity', seg(t, 1.6, 2)); sa(chip, 'transform', `translate(320 306) scale(${0.85 + 0.15 * ease(seg(t, 1.6, 2))})`)
    } }
  },
  whistle(e) {
    // Half time and full time: the score and the numbers of the match so far.
    const svg = stage('home'), g = el('g', {}, svg)
    el('rect', { x: 110, y: 26, width: 420, height: 296, rx: 18, fill: 'rgba(4,11,28,.9)', stroke: 'rgba(245,184,46,.35)' }, g)
    el('text', { x: 320, y: 66, 'text-anchor': 'middle', 'font-family': 'Amin, sans-serif', 'font-weight': 900, 'font-size': 28, fill: ref(svg, 'gold') }, g).textContent = e.big ?? ''
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
      sa(g, 'opacity', seg(t, 0, 0.4))
      // Home on the right, as on the scoreboard.
      bars.forEach((b, i) => { const f = ease(seg(t, 0.4 + i * 0.15, 1.2 + i * 0.15)), tot = b.h + b.a || 1, wh = (150 * b.h / tot) * f, wa = (150 * b.a / tot) * f; sa(b.hb, 'width', wh); sa(b.ab, 'x', 320 - wa); sa(b.ab, 'width', wa) })
    } }
  },
  // [Sprint 35 C3] A goal ruled out by VAR: the move and the ball in the net (the scorer away to celebrate), then
  // the referee's hand to his ear, the screen drawn in the air, the check (the offside lines, or the foul ringed),
  // and «لا هدف».
  var(e) {
    const KT = 3.0, { svg, go } = openPlay({ ...e, quality: e.quality ?? 'big' }, 'goal', KT)
    const shade = el('rect', { width: 640, height: 340, fill: 'rgba(8,18,40,.55)', opacity: 0 }, svg)
    const badge = el('g', { opacity: 0 }, svg)
    badge.innerHTML = `<rect x="-70" y="-26" width="140" height="52" rx="10" fill="#071733" stroke="#F5B82E" stroke-width="2"/><text y="10" text-anchor="middle" font-family="Barlow Condensed, sans-serif" font-weight="800" font-size="30" fill="#FFD36B" letter-spacing="4">VAR</text>`
    const check = el('text', { x: 320, y: 300, 'text-anchor': 'middle', 'font-family': 'Amin, sans-serif', 'font-weight': 800, 'font-size': 18, fill: '#C9D2E1', opacity: 0 }, svg)
    check.textContent = e.reason === 'foul' ? tr('مراجعة الفار: خطأ محتمل') : tr('مراجعة الفار: تسلل محتمل')
    const scan = el('rect', { x: 0, y: 0, width: 640, height: 3, fill: '#7FB4FF', opacity: 0 }, svg)
    const lines = el('g', { opacity: 0 }, svg)
    lines.innerHTML = e.reason === 'foul'
      ? `<circle cx="300" cy="215" r="34" fill="none" stroke="#EF4444" stroke-width="4" stroke-dasharray="10 6"/>`
      : `<path d="M200 70 L170 330" stroke="#EF4444" stroke-width="3"/><path d="M232 70 L206 330" stroke="#2BB673" stroke-width="3"/>`
    const tv = el('rect', { x: -28, y: -18, width: 56, height: 36, rx: 3, fill: 'none', stroke: '#fff', 'stroke-width': 3, opacity: 0 }, svg)
    const no = title(svg, tr('لا هدف'), '#EF4444')
    const sub = el('text', { x: 320, y: 86, 'text-anchor': 'middle', 'font-family': 'Amin, sans-serif', 'font-weight': 800, 'font-size': 20, fill: '#fff', stroke: '#040B1C', 'stroke-width': 4, 'paint-order': 'stroke', opacity: 0 }, svg)
    sub.textContent = e.reason === 'foul' ? tr('خطأ قبل الهدف') : tr('تسلل')
    return { dur: 8.2, svg, update(t) {
      // The goal as it seemed, then the frame stays as the check runs.
      go(Math.min(t, 3.9))
      const c = seg(t, 4.0, 4.4) * (1 - seg(t, 7.8, 8.2))
      sa(shade, 'opacity', 0.9 * c)
      sa(badge, 'opacity', c); sa(badge, 'transform', `translate(96 296) scale(${0.6 + 0.1 * ease(seg(t, 4.0, 4.4))})`)
      // The referee draws the screen in the air.
      const d = seg(t, 4.3, 5.0)
      sa(tv, 'opacity', d > 0 && t < 6.4 ? 1 : 0); sa(tv, 'transform', `translate(320 228) scale(${0.3 + 0.7 * ease(d)})`)
      sa(check, 'opacity', seg(t, 4.6, 5.0) * (1 - seg(t, 6.2, 6.4)))
      sa(scan, 'opacity', t > 4.8 && t < 6.4 ? 0.8 : 0); sa(scan, 'y', 40 + ((t - 4.8) * 160) % 260)
      sa(lines, 'opacity', seg(t, 5.2, 5.6) * (1 - seg(t, 7.6, 8.0)))
      no(seg(t, 6.4, 6.8)); sa(sub, 'opacity', seg(t, 6.6, 7.0))
    } }
  },
  // [Sprint 36 F5] Half time: both teams walk off towards the tunnel at the side, the camera following them.
  tunnel(e) {
    const svg = stage('home'), w = svg.world, R = rnd(5)
    const walkers = [0, 1, 2, 3, 4, 5].map((i) => ({ p: player(w, K(i % 2 ? 'away' : 'home').kit, '', 1.2, { look: Math.floor(R() * 40) }), x: 140 + i * 52, y: 200 + (i % 3) * 18, ph: i }))
    el('rect', { x: 560, y: 120, width: 90, height: 120, rx: 6, fill: '#0B1626' }, w); el('rect', { x: 570, y: 130, width: 70, height: 110, fill: '#040B1C' }, w)
    const tt = title(svg, tr('إلى غرف الملابس'))
    return { dur: 2.8, svg, update(t) {
      cam(svg, 1.05, 380, 200)
      for (const q of walkers) { q.p.face?.('side', 1); q.p.at(q.x + t * 60, q.y, 0, 1.2); q.p.run(t * 7 + q.ph, 0.25) }
      tt(seg(t, 0.2, 0.6))
    } }
  },
  // [Sprint 36 F5] Full time: the two teams pass each other in a line, shaking hands.
  handshake(e) {
    const svg = stage('home'), w = svg.world, R = rnd(9)
    const a = [0, 1, 2, 3].map(() => player(w, K('home').kit, '', 1.3, { look: Math.floor(R() * 40) }))
    const b = [0, 1, 2, 3].map(() => player(w, K('away').kit, '', 1.3, { look: Math.floor(R() * 40) }))
    const tt = title(svg, tr('المصافحة'))
    return { dur: 3.0, svg, update(t) {
      cam(svg, 1.1, 320, 200)
      a.forEach((p, i) => { const x = 60 + i * 80 + t * 70; p.face?.('side', 1); p.at(x, 196, 0, 1.3); const near = b.some((_, j) => Math.abs(x - (580 - j * 80 - t * 70)) < 40); near ? p.pose(3, -3, 10, -80) : p.run(t * 6 + i, 0.2) })
      b.forEach((p, i) => { const x = 580 - i * 80 - t * 70; p.face?.('side', -1); p.at(x, 214, 0, 1.3); const near = a.some((_, j) => Math.abs(x - (60 + j * 80 + t * 70)) < 40); near ? p.pose(3, -3, 10, -80) : p.run(t * 6 + i, 0.2) })
      tt(seg(t, 0.2, 0.6))
    } }
  },
  // ------------------------------------------------------------ [Sprint 35 C1] the director's cutaways
  // The crowd behind the goal on its feet: the scoring side's fans jumping with their arms and scarves up, two big
  // flags waving, and (the full tier) flares and paper raining down. e.side: whose fans; e.count: how many to draw.
  crowd(e) {
    const svg = stage(e.side), w = svg.world, k = K(e.side), R = rnd(e.v ?? 7)
    const g = el('g', {}, w), fans = []
    const skins = ['#C99A78', '#8D5A3B', '#E2B48F', '#6B4027', '#B07B57', '#D9A982']
    const n = e.count ?? 90
    for (let i = 0; i < n; i++) {
      const row = i % 6, x = ((i * 53 + row * 29) % 700) - 30, y = 120 + row * 38, s = 0.7 + row * 0.12
      const f = el('g', {}, g), shirt = R() < 0.7 ? k.kit : k.trim ?? '#fff'
      f.innerHTML = `<rect x="-9" y="0" width="18" height="26" rx="6" fill="${shirt}"/><circle cy="-8" r="8" fill="${skins[i % skins.length]}"/>`
        + `<rect class="a1" x="-12" y="-2" width="5" height="18" rx="2.5" fill="${shirt}"/><rect class="a2" x="7" y="-2" width="5" height="18" rx="2.5" fill="${shirt}"/>`
        + (i % 4 === 0 ? `<rect class="sc" x="-16" y="-34" width="32" height="7" rx="2" fill="${k.trim ?? '#F5B82E'}"/>` : '')
      fans.push({ f, x, y, s, ph: R() * 6.3, a1: f.querySelector('.a1'), a2: f.querySelector('.a2'), sc: f.querySelector('.sc') })
    }
    const flags = [140, 470].map((x) => { const p = el('path', { fill: k.kit, stroke: k.trim ?? '#fff', 'stroke-width': 3, opacity: 0.95 }, w); return { p, x } })
    const flares = (e.flares ? [90, 330, 560] : []).map((x) => el('circle', { cx: x, cy: 150, r: 26, fill: '#FF8A3D', opacity: 0, filter: ref(svg, 'soft') }, w))
    const paper = (e.flares ? Array.from({ length: 40 }, (_, i) => el('rect', { width: 5, height: 3, fill: ['#fff', k.kit, '#F5B82E'][i % 3], opacity: 0.9 }, w)) : [])
    const tt = title(svg, tr('فرحة الجماهير'))
    return { dur: 2.6, svg, update(t) {
      cam(svg, 1.25 - 0.08 * ease(seg(t, 0, 2.6)), 320, 200)
      for (const q of fans) {
        const j = Math.abs(Math.sin(t * 7 + q.ph)) * 10
        sa(q.f, 'transform', `translate(${q.x} ${q.y - j}) scale(${q.s})`)
        const a = 150 + Math.sin(t * 9 + q.ph) * 20
        sa(q.a1, 'transform', `rotate(${a} -9 0)`); sa(q.a2, 'transform', `rotate(${-a} 9 0)`)
        if (q.sc) sa(q.sc, 'transform', `translate(0 ${-j * 0.3}) rotate(${Math.sin(t * 5 + q.ph) * 6})`)
      }
      for (const { p, x } of flags) {
        const wv = (dx) => Math.sin(t * 6 + dx / 18) * 8
        sa(p, 'd', `M${x} 60 L${x + 120} ${60 + wv(120)} L${x + 120} ${130 + wv(120)} L${x} 130 Z`)
      }
      flares.forEach((f, i) => sa(f, 'opacity', 0.5 + 0.3 * Math.sin(t * 13 + i * 2)))
      paper.forEach((r, i) => { const x = (i * 83 + t * 30 * (i % 3 + 1)) % 700 - 30, y = ((t * (60 + (i % 5) * 20) + i * 37) % 360) - 20; sa(r, 'transform', `translate(${x} ${y}) rotate(${t * 200 + i * 40})`) })
      tt(seg(t, 0.3, 0.7))
    } }
  },
  // A coach on his touchline in his mood (the server's), the approved 3D model of his look (C1 to C3, Sprint 26):
  // his joy at a goal, his anger at a goal against or a red card, his worry at a chance missed.
  coachReact(e) {
    const svg = stage(e.side), w = svg.world
    el('rect', { x: -80, y: 236, width: 800, height: 110, fill: 'rgba(4,11,28,.55)' }, w)
    el('rect', { x: 60, y: 168, width: 520, height: 12, rx: 4, fill: '#0B1626' }, w)
    el('rect', { x: 60, y: 166, width: 520, height: 3, fill: 'rgba(200,215,235,.4)' }, w)
    el('path', { d: 'M100 300 H540', stroke: 'rgba(255,255,255,.7)', 'stroke-width': 2, 'stroke-dasharray': '8 6' }, w)
    const look = ['C1', 'C2', 'C3'].includes(e.look) ? e.look : 'C1', mood = e.mood ?? 'joy'
    const img = el('image', { href: `/characters/${look.toLowerCase()}-${mood}.webp`, x: 205, y: 8, width: 250, height: 325, preserveAspectRatio: 'xMidYMax meet' }, svg)
    const glow = el('circle', { cx: 360, cy: 180, r: 120, fill: K(e.side).kit, opacity: 0, filter: ref(svg, 'soft') }, svg)
    svg.insertBefore(glow, img)
    const words = { joy: 'فرحة المدرب', cheer: 'فرحة المدرب', angry: 'غضب المدرب', worried: 'قلق المدرب', sad: 'حسرة المدرب', surprise: 'دهشة المدرب', think: 'المدرب يفكر' }
    const tt = title(svg, tr(words[mood] ?? 'المدرب'), mood === 'angry' ? '#EF4444' : mood === 'joy' || mood === 'cheer' ? undefined : '#C9D2E1')
    return { dur: 2.4, svg, update(t) {
      cam(svg, 1.05 + 0.06 * t / 2.4, 320, 200)
      const f = ease(seg(t, 0, 0.35))
      sa(img, 'transform', `translate(${(1 - f) * 80} 0)`); sa(img, 'opacity', f)
      sa(glow, 'opacity', 0.35 * f)
      tt(seg(t, 0.2, 0.6))
    } }
  },
  board(e) {
    const svg = stage('home'), bd = el('g', {}, svg)
    bd.innerHTML = `<rect x="-90" y="-56" width="180" height="112" rx="14" fill="#071733" stroke="rgba(245,184,46,.6)" stroke-width="2"/><text y="-22" text-anchor="middle" font-family="IBM Plex Sans Arabic, sans-serif" font-size="15" fill="#93A3BF">الوقت بدل الضائع</text><text y="34" text-anchor="middle" font-family="Barlow Condensed, sans-serif" font-weight="800" font-size="60" fill="#2BB673">+${e.plus ?? ''}</text>`
    return { dur: 3, svg, update(t) { sa(bd, 'transform', `translate(320 ${lerp(400, 170, ease(seg(t, 0.1, 0.7)))}) scale(${1 + 0.03 * Math.sin(t * 8)})`) } }
  },
}
