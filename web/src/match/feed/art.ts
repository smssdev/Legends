// @ts-nocheck
// The match feed's art (docs/MATCH_VIEW.md 4.6): broadcast motion graphics in the
// brand's navy and gold, with each team's colour as light. A night pitch in
// perspective, clean player silhouettes with numbers, light trails, flashes and
// particles; crests and line icons for the timeline. Drawing only: which scene
// plays, and with whom, comes from story.ts.
import { t as tr } from '../../lib/i18n'
import { SCENE_TIME } from './timing'

const NS = 'http://www.w3.org/2000/svg'
// The two kits of the match: { kit, ink, trim, name } per side, set by the feed.
let KITS = { home: { kit: '#E8ECF4', ink: '#0A1F42', trim: '#F5B82E', name: '' }, away: { kit: '#D3122F', ink: '#FFFFFF', trim: '#F6C343', name: '' } }
export function setKits(k) { KITS = k }
// The smooth mode [X30]: no glow filter (redrawn every frame on the phone's processor for every line and trail) and a third of the crowd.
let SMOOTH = false
export function setSmooth(v) { SMOOTH = !!v }
// [Sprint 42 I1] Only the full tier draws the blurred glows: an SVG blur makes every repaint of the picture costly.
let RICH = true
export function setRich(v) { RICH = !!v }
// [Sprint 42 J1] The owner's (2026-11-03): no two matches alike. Each scene gets its looks from its own seed (a camera,
// a headline, an accent at its key moment, VARIANT), and each match its light (LIGHT: night, dusk or day).
const VARIANT = { cam: 0, title: 0, accent: 0 }
let LIGHT = 'night'
export function setLight(v) { LIGHT = ['night', 'dusk', 'day'].includes(v) ? v : 'night' }
// [Sprint 36 F3] The match's rain (the live pitch's, from its seed) falls in the scenes too.
let RAIN = false
export function setRain(v) { RAIN = !!v }
const K = (s) => KITS[s] ?? KITS.home
const other = (s) => (s === 'home' ? 'away' : 'home')
export const lum = (hex) => { const n = parseInt(String(hex).slice(1), 16); return 0.3 * (n >> 16) + 0.59 * ((n >> 8) & 255) + 0.11 * (n & 255) }
export const shade = (hex, p) => { const n = parseInt(hex.slice(1), 16), f = (v) => Math.max(0, Math.min(255, v + p)); return '#' + [f(n >> 16), f((n >> 8) & 255), f(n & 255)].map((v) => v.toString(16).padStart(2, '0')).join('') }
// [Sprint 37 N5] Between two colours (f 0..1): the stands take a little of the home club's colour.
export const mix = (a, b, f) => { const x = parseInt(String(a).slice(1), 16), y = parseInt(String(b).slice(1), 16), c = (sh) => Math.round(((x >> sh) & 255) * (1 - f) + ((y >> sh) & 255) * f); return '#' + [c(16), c(8), c(0)].map((v) => v.toString(16).padStart(2, '0')).join('') }
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

// [Sprint 42 K1] The stadium behind every scene, drawn in place (a picture of it, Sprint 42 I1, could show black until
// it was decoded, or not at all on some phones). Built as text once per club and light, then reused with the scene's
// own ids (@ is replaced by them). Closer to a real ground: two tiers of stands under a roof, the crowd, floodlight
// towers and their beams, the boards, and the grass in mowing stripes, brighter under the lights.
const STADIUMS = new Map()
function stadium(id, c, home) {
  const key = [c, home, KITS.home?.trim, SMOOTH, RICH, LIGHT].join('|')
  let txt = STADIUMS.get(key)
  if (!txt) {
    const L = { night: { sky: ['#030916', '#0B1C3D'], halo: ['#FFFFFF', 0.28], grass: ['#23864A', '#0F4A27'], stand: ['#0E1A33', '#16264A'], beam: 0.12 },
      dusk: { sky: ['#1E1238', '#D06A3E'], halo: ['#FFC08A', 0.3], grass: ['#2F8A3E', '#145226'], stand: ['#2A1C34', '#3A2742'], beam: 0.07 },
      day: { sky: ['#5C9FDB', '#CBE6F7'], halo: ['#FFFFFF', 0.1], grass: ['#3FA24C', '#1E6A2E'], stand: ['#3A4A66', '#4E5F7E'], beam: 0 } }[LIGHT]
    const fans = SMOOTH ? 90 : RICH ? 240 : 150, cols = [mix('#2B4F8C', home, 0.35), home, c, KITS.home?.trim ?? '#F5B82E', '#E6EAF2', '#C99A78']
    const CR = rnd(97)
    const crowd = Array.from({ length: fans }, (_, i) => { const upper = i % 3 === 0, x = CR() * 840 - 100, y = upper ? 4 + CR() * 48 : 66 + CR() * 48; return `<circle cx="${x}" cy="${y}" r="${(upper ? 1.3 : 1.8) + (i % 3) * 0.5}" fill="${cols[i % cols.length]}" opacity="${(upper ? 0.5 : 0.7) + (i % 4) * 0.08}"/>` }).join('')
    const tower = (x) => `<rect x="${x - 3}" y="-40" width="6" height="70" fill="#1A2236"/><rect x="${x - 26}" y="-46" width="52" height="20" rx="3" fill="#2A3350"/>${Array.from({ length: 8 }, (_, i) => `<rect x="${x - 23 + (i % 4) * 12}" y="${-43 + Math.floor(i / 4) * 9}" width="9" height="6" rx="1.5" fill="#FFF6DA" opacity="${LIGHT === 'day' ? 0.5 : 0.95}"/>`).join('')}`
    const beams = L.beam ? `<path d="M-40 -30 L140 160 L20 160 Z" fill="url(#@beam)"/><path d="M680 -30 L500 160 L620 160 Z" fill="url(#@beam)"/>` : ''
    txt = { defs: `<linearGradient id="@sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${L.sky[0]}"/><stop offset="1" stop-color="${L.sky[1]}"/></linearGradient>
      <linearGradient id="@stand" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${L.stand[0]}"/><stop offset="1" stop-color="${L.stand[1]}"/></linearGradient>
      <linearGradient id="@t" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${L.grass[0]}"/><stop offset="1" stop-color="${L.grass[1]}"/></linearGradient>
      <radialGradient id="@h" cx=".5" cy="0" r="1"><stop offset="0" stop-color="${L.halo[0]}" stop-opacity="${L.halo[1]}"/><stop offset=".6" stop-color="${L.halo[0]}" stop-opacity="0"/></radialGradient>
      <linearGradient id="@beam" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFF6DA" stop-opacity="${L.beam}"/><stop offset="1" stop-color="#FFF6DA" stop-opacity="0"/></linearGradient>
      <radialGradient id="@ball" cx=".36" cy=".32" r=".75"><stop offset="0" stop-color="#FFFFFF"/><stop offset=".7" stop-color="#F1F3F8"/><stop offset="1" stop-color="#B9C3D6"/></radialGradient>
      <linearGradient id="@b" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="${mix('#0B2149', home, 0.16)}"/><stop offset=".5" stop-color="${mix('#163B78', home, 0.2)}"/><stop offset="1" stop-color="${mix('#0B2149', home, 0.16)}"/></linearGradient>`,
    body: `<rect x="-120" y="-60" width="880" height="440" fill="url(#@sky)"/>
      ${RICH && LIGHT !== 'day' ? tower(-50) + tower(690) : ''}
      <path d="M-120 -8 L760 -8 L760 60 L-120 60 Z" fill="url(#@stand)" opacity=".92"/><path d="M-120 -10 L760 -10" stroke="#3A4A6A" stroke-width="3"/>
      <path d="M-120 60 L760 60 L760 118 L-120 118 Z" fill="url(#@stand)"/><path d="M-120 60 L760 60" stroke="rgba(255,255,255,.12)" stroke-width="2"/>
      ${Array.from({ length: 10 }, (_, i) => `<path d="M-120 ${8 + i * 11} L760 ${8 + i * 11}" stroke="rgba(0,0,0,.18)" stroke-width="1"/>`).join('')}
      <g>${crowd}</g>
      <rect x="-80" y="-40" width="800" height="200" fill="url(#@h)"/>
      ${beams}
      <rect x="-80" y="118" width="800" height="4" fill="#0A1224"/>
      <rect x="-80" y="122" width="800" height="16" fill="url(#@b)"/>
      <rect x="-80" y="122" width="800" height="1.5" fill="#F5B82E" opacity=".6"/>
      <rect x="-120" y="138" width="880" height="250" fill="${mix(L.grass[1], '#000000', 0.25)}"/>
      <path d="M-120 380 L120 ${LINE - 12} L520 ${LINE - 12} L760 380 Z" fill="url(#@t)"/>
      ${Array.from({ length: 10 }, (_, i) => { const y0 = LINE - 12 + Math.pow(i / 10, 1.5) * 242, y1 = LINE - 12 + Math.pow((i + 1) / 10, 1.5) * 242, k0 = y0 - LINE + 12, k1 = y1 - LINE + 12; return i % 2 ? '' : `<path d="M${120 - k0} ${y0} L${520 + k0} ${y0} L${520 + k1} ${y1} L${120 - k1} ${y1} Z" fill="#FFFFFF" fill-opacity=".06"/>` }).join('')}
      <g fill="none" stroke="#FFFFFF" stroke-opacity=".75" stroke-width="1.8"><path d="M108 ${LINE} H532"/><path d="M196 ${LINE} L160 226 H480 L444 ${LINE}"/><path d="M258 ${LINE} L250 172 H390 L382 ${LINE}"/><path d="M262 226 Q320 254 378 226"/></g>
      <ellipse cx="320" cy="207" rx="2.4" ry="1.1" fill="#fff" opacity=".9"/>` }
    STADIUMS.set(key, txt)
  }
  return { defs: txt.defs.replaceAll('@', id), body: txt.body.replaceAll('@', id) }
}

// The stage: a night stadium, the pitch in perspective, boards behind the goal, the team's light.
// Everything that the camera moves sits in svg.world; titles and flashes go on top of it.
function stage(side) {
  // [Sprint 37 N5] The stadium is the home club's: its stand and the board under it take its colours.
  const c = K(side).kit, home = KITS.home?.kit ?? '#2B4F8C', id = 's' + ++uid
  const svg = el('svg', { viewBox: '0 0 640 340' })
  const st = stadium(id, c, home)
  svg.innerHTML = `<defs>${st.defs}
    <radialGradient id="${id}c" cx=".5" cy=".55" r=".6"><stop offset="0" stop-color="${c}" stop-opacity=".16"/><stop offset="1" stop-color="${c}" stop-opacity="0"/></radialGradient>
    <linearGradient id="gold${id}" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#C08A0C"/><stop offset=".5" stop-color="#FFD36B"/><stop offset="1" stop-color="#C08A0C"/></linearGradient>
    <filter id="glow${id}" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="4" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter>
    <filter id="soft${id}"><feGaussianBlur stdDeviation="10"/></filter>
  </defs>
  <rect width="640" height="340" fill="#0B1A3A"/>
  <g data-world="1">${st.body}
  ${[60, 220, 380, 540].map((x) => `<text x="${x}" y="134" font-family="Amin, sans-serif" font-weight="800" font-size="10" letter-spacing="3" fill="#FFD36B" opacity=".8">LEGENDS</text>`).join('')}
  </g>
  <rect width="640" height="340" fill="url(#${id}c)" pointer-events="none"/>${RAIN ? `<style>.rain{animation:rainfall .5s linear infinite}@keyframes rainfall{to{transform:translate(-5px,30px)}}@media (prefers-reduced-motion:reduce){.rain{animation:none}}</style><g class="rain" stroke="rgba(200,215,235,.45)" stroke-width="1.1">${Array.from({ length: SMOOTH ? 30 : 90 }, (_, i) => `<line x1="${(i * 73) % 680}" y1="${(i * 41) % 360 - 20}" x2="${(i * 73) % 680 - 5}" y2="${(i * 41) % 360 + 10}"/>`).join('')}</g><rect width="640" height="340" fill="rgba(40,55,75,.18)"/>` : ''}`
  svg.dataset.id = id
  svg.world = svg.querySelector('[data-world]')
  return svg
}
const ref = (svg, name) => ((SMOOTH || !RICH) && name === 'glow' ? 'none' : `url(#${name}${svg.dataset.id})`)
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
// [Sprint 37 N4] The brows (left, right, profile) and the mouth (front, profile) for each feeling.
const FACES = {
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
    <g data-h="front" display="none"><circle cx="-9.4" cy="-20.5" r="2" fill="${shade(skin, -18)}"/><circle cx="9.4" cy="-20.5" r="2" fill="${shade(skin, -18)}"/><path d="M-9.6 -22 Q-10 -32 0 -32.5 Q10 -32 9.6 -22 Q6 -28 0 -28 Q-6 -28 -9.6 -22 Z" fill="${hair}"/><path data-brow="l" fill="none" stroke="${hair}" stroke-width="1.3" stroke-linecap="round"/><path data-brow="r" fill="none" stroke="${hair}" stroke-width="1.3" stroke-linecap="round"/><ellipse data-eye="l" cx="-3.4" cy="-21" rx="1.3" ry="1.3" fill="#141414"/><ellipse data-eye="r" cx="3.4" cy="-21" rx="1.3" ry="1.3" fill="#141414"/><path d="M0.2 -20.4 L-1 -17.8 L0.9 -17.6" fill="none" stroke="${shade(skin, -45)}" stroke-width=".8" stroke-linejoin="round"/><path data-mouth="f" stroke="rgba(60,20,10,.7)" stroke-width="1" stroke-linecap="round"/></g>
    <g data-h="side" display="none"><path d="M-9.6 -19 Q-11 -32 0 -32.5 Q9 -32 9.4 -24 Q4 -27 -1 -25 Q-3 -20 -9.6 -19 Z" fill="${hair}"/><circle cx="-1.6" cy="-20.5" r="2" fill="${shade(skin, -18)}"/><path data-brow="s" fill="none" stroke="${hair}" stroke-width="1.3" stroke-linecap="round"/><ellipse data-eye="s" cx="4.6" cy="-22" rx="1.3" ry="1.3" fill="#141414"/><path d="M9 -21 L11.6 -18.6 L9 -17.6" fill="${skin}"/><path data-mouth="s" stroke="rgba(60,20,10,.7)" stroke-width="1" stroke-linecap="round"/></g>`)
  const heads = Object.fromEntries([...head.e.querySelectorAll('[data-h]')].map((e) => [e.dataset.h, e]))
  // [Sprint 37 N4] The face's feeling in a close-up: the brows and the mouth (front and profile).
  const brow = Object.fromEntries([...head.e.querySelectorAll('[data-brow]')].map((e) => [e.dataset.brow, e]))
  const mouth = Object.fromEntries([...head.e.querySelectorAll('[data-mouth]')].map((e) => [e.dataset.mouth, e]))
  const eyes = Object.fromEntries([...head.e.querySelectorAll('[data-eye]')].map((e) => [e.dataset.eye, e]))
  let felt = ''
  const setMood = (m) => {
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
    // [Sprint 37 N4] idle, joy, angry, sad or focus: seen in the close-ups that turn him to the camera or side on.
    mood: setMood,
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

// [Sprint 42 K2] The ball, easy to follow: bigger, shaded round, a dark edge against the white net and the day sky, a
// faint white halo against the night grass, and never smaller than readable far away.
function ball(svg, p = svg.world) {
  const shadow = el('ellipse', { rx: 7, ry: 2.4, fill: 'rgba(0,0,0,.5)' }, p)
  const g = el('g', {}, p), id = svg.dataset.id
  g.innerHTML = `<circle r="10.5" fill="#FFFFFF" opacity=".28"/><circle r="8" fill="url(#${id}ball)" stroke="#16203A" stroke-width="1.1"/><g data-spin="1" transform="scale(1.23)"><path d="M0 -2.6 L2.5 -0.8 L1.6 2.1 L-1.6 2.1 L-2.5 -0.8 Z" fill="#16203A"/><path d="M0 -6.5 L0 -2.6 M2.5 -0.8 L6.2 -2 M1.6 2.1 L3.8 5.3 M-1.6 2.1 L-3.8 5.3 M-2.5 -0.8 L-6.2 -2" stroke="#16203A" stroke-width=".9"/></g><circle cx="-2.6" cy="-3" r="2" fill="#fff" opacity=".8"/>`
  const spin = g.querySelector('[data-spin]')
  return {
    g,
    // Screen point, its depth on the ground (for size and shadow), and how much it has spun.
    set(x, y, ground, turn = 0, op = 1) {
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
function trail(svg, p = svg.world, color = '#FFE7A8') { return el('path', { d: '', fill: 'none', stroke: color, 'stroke-width': 2.5, 'stroke-linecap': 'round', opacity: 0, filter: ref(svg, 'glow') }, p) }
const drawTrail = (trl, path, f, op, from = 0) => { const pts = Array.from({ length: 14 }, (_, i) => bez(path, Math.max(from, f - 0.35) + ((f - Math.max(from, f - 0.35)) * i) / 13)); sa(trl, 'd', 'M' + pts.map((q) => q.join(' ')).join(' L')); sa(trl, 'opacity', op) }
// The headline: a dark band with gold rules sliding in, the word over it.
function title(svg, text, color) {
  const fill = color ?? ref(svg, 'gold'), style = VARIANT.title
  const band = el('rect', { x: 0, y: 4, width: 640, height: 60, fill: style === 2 ? 'rgba(4,11,28,.45)' : 'rgba(4,11,28,.75)', opacity: 0 }, svg)
  const r1 = el('rect', { x: 0, y: 4, width: 640, height: 2, fill: style === 2 ? fill : ref(svg, 'gold'), opacity: 0 }, svg), r2 = el('rect', { x: 0, y: 62, width: 640, height: 2, fill: style === 2 ? fill : ref(svg, 'gold'), opacity: 0 }, svg)
  // [Sprint 42 J1] The stamp: a box behind the word, at a slant.
  const box = style === 3 ? el('rect', { x: 200, y: 10, width: 240, height: 56, rx: 6, fill: 'rgba(4,11,28,.82)', stroke: fill, 'stroke-width': 4, opacity: 0 }, svg) : null
  // [Sprint 30 Q8] A dark edge under the word: read whole over the pitch, the flashes and the band.
  const t = el('text', { x: 320, y: 40, 'text-anchor': 'middle', 'dominant-baseline': 'middle', 'font-family': 'Amin, sans-serif', 'font-weight': 900, 'font-size': 36, fill, stroke: '#040B1C', 'stroke-width': 5, 'paint-order': 'stroke', 'stroke-linejoin': 'round', opacity: 0 }, svg)
  t.textContent = text
  // [Sprint 42 J1] Four looks for the headline, one per scene (VARIANT.title): the gold band sliding in; the slam (the
  // word drops in big, no band); neon (a thin band in its colour, the word flickering on); the stamp (a box at a slant).
  return (f) => {
    const e = ease(f)
    if (style === 1) { sa(t, 'opacity', f); sa(t, 'transform', `translate(320 40) scale(${(lerp(2.6, 1, e)).toFixed(3)}) rotate(${((1 - e) * -6).toFixed(1)}) translate(-320 -40)`); return }
    if (style === 3) { const k = f < 1 ? lerp(1.7, 1, e) - Math.sin(Math.PI * f) * 0.08 : 1; for (const x of [box, t]) { sa(x, 'opacity', f); sa(x, 'transform', `translate(320 38) rotate(-5) scale(${k.toFixed(3)}) translate(-320 -38)`) } return }
    sa(band, 'opacity', f); sa(r1, 'opacity', f); sa(r2, 'opacity', f); sa(r1, 'transform', `translate(${(1 - e) * -640} 0)`); sa(r2, 'transform', `translate(${(1 - e) * 640} 0)`)
    sa(t, 'opacity', style === 2 && f < 1 ? (Math.sin(f * 45) > 0 ? f : f * 0.3) : f); sa(t, 'transform', `translate(320 40) scale(${0.8 + 0.2 * e}) translate(-320 -40)`)
  }
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

// ---------------------------------------------------------------- [Sprint 42] cartoon effects
// The owner's (2026-11-03): the clock stops and a cartoon tells the moment, with a screen that shakes, flashes of colour
// for its feeling (red anger or danger, yellow a warning, blue shock), speed lines, dust, stars and comic bursts.
// The whole picture shakes (a goal, the woodwork, a fight): the svg itself, so its titles shake with it. Half on a weak phone.
function shakeIt(svg, amt, t) { const k = SMOOTH ? amt * 0.5 : amt; const v = k > 0.05 ? `translate(${(Math.sin(t * 91) * k).toFixed(1)}px, ${(Math.cos(t * 77) * k * 0.7).toFixed(1)}px)` : ''; if (svg._shk !== v) { svg._shk = v; svg.style.transform = v } }
// A flash of colour over the whole screen (made before the title, so the title stays on top).
function tint(svg, color) { const r = el('rect', { width: 640, height: 340, fill: color, opacity: 0, 'pointer-events': 'none' }, svg); return (f) => sa(r, 'opacity', Math.max(0, f)) }
// Speed lines behind a runner going (dx, dy) at (x, y), streaming back as he runs; f fades them in and out.
function speedLines(svg, p = svg.world, n = 7, color = '#FFFFFF') {
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
function confetti(svg, n = 46) {
  const cols = ['#F5B82E', '#EF4444', '#2BB673', '#3B82F6', '#E85D9A', '#FFFFFF']
  const ps = Array.from({ length: SMOOTH ? Math.floor(n / 2) : n }, (_, i) => el('rect', { width: 5, height: 9, rx: 1, fill: cols[i % 6], opacity: 0 }, svg))
  return (a) => ps.forEach((r, i) => {
    if (a <= 0) { sa(r, 'opacity', 0); return }
    const x = ((i * 97.3) % 660) - 10 + Math.sin(a * 3 + i) * 18, y = -20 - ((i * 53) % 140) + a * (90 + ((i * 37) % 60))
    sa(r, 'opacity', y > 350 ? 0 : 1); sa(r, 'transform', `translate(${x.toFixed(1)} ${y.toFixed(1)}) rotate(${Math.round(a * 300 + i * 40)})`)
  })
}
// A comic burst (a jagged star with a word): the keeper's fingertips, the ball on the bar.
function boom(svg, p = svg.world, word = 'POW!', fill = '#FFD400', ink = '#B91C1C') {
  const g = el('g', { opacity: 0 }, p)
  const pts = Array.from({ length: 18 }, (_, i) => { const r = i % 2 ? 15 : 31, a = (i * Math.PI) / 9; return `${(Math.cos(a) * r).toFixed(1)},${(Math.sin(a) * r).toFixed(1)}` }).join(' ')
  g.innerHTML = `<polygon points="${pts}" fill="${fill}" stroke="#E2531F" stroke-width="3" stroke-linejoin="round"/><text y="5" text-anchor="middle" font-family="Barlow Condensed, sans-serif" font-weight="900" font-style="italic" font-size="15" fill="${ink}">${word}</text>`
  return (x, y, f) => { const on = f > 0 && f < 1; sa(g, 'opacity', on ? 1 - seg(f, 0.6, 1) : 0); if (on) sa(g, 'transform', `translate(${x.toFixed(1)} ${y.toFixed(1)}) scale(${(0.3 + ease(Math.min(1, f * 2.2)) * 0.9).toFixed(2)}) rotate(${Math.round(f * 20)})`) }
}
// A puff of dust on the grass (a slide, a fall, the medics' sprint).
function dust(svg, p = svg.world, n = 8, color = '#D9C9A8') {
  const ps = Array.from({ length: n }, (_, i) => el('circle', { fill: Array.isArray(color) ? color[i % color.length] : color, opacity: 0 }, p))
  return (x, y, f) => ps.forEach((c, i) => {
    const on = f > 0 && f < 1, a = (i / n) * Math.PI * 2, d = 8 + ease(f) * 28
    sa(c, 'opacity', on ? (0.75 * (1 - f)).toFixed(2) : 0)
    if (on) { sa(c, 'cx', (x + Math.cos(a) * d * 1.4).toFixed(1)); sa(c, 'cy', (y + Math.sin(a) * d * 0.4 - ease(f) * 8).toFixed(1)); sa(c, 'r', (4 + f * 8).toFixed(1)) }
  })
}
// Stars and little birds circling a dazed player's head.
function dizzy(svg, p = svg.world) {
  const g = el('g', { opacity: 0 }, p)
  const items = Array.from({ length: 5 }, (_, i) => { const e = el('g', {}, g); e.innerHTML = i % 2 ? '<path d="M-5 0 Q-2.5 -4 0 0 Q2.5 -4 5 0" fill="none" stroke="#fff" stroke-width="1.7" stroke-linecap="round"/>' : '<polygon points="0,-5 1.5,-1.5 5,-1.5 2.2,1 3.2,4.8 0,2.6 -3.2,4.8 -2.2,1 -5,-1.5 -1.5,-1.5" fill="#FFD400"/>'; return e })
  return (x, y, t, on) => { sa(g, 'opacity', on ? 1 : 0); if (on) items.forEach((e, i) => { const a = t * 5 + (i * Math.PI * 2) / items.length; sa(e, 'transform', `translate(${(x + Math.cos(a) * 20).toFixed(1)} ${(y + Math.sin(a) * 6).toFixed(1)})`) }) }
}
// [Sprint 42 F] The classic cartoon shock: the eyes pop out of the head on stalks, looking dir (-1 left, 1 right).
function popEyes(svg, p = svg.world) {
  const g = el('g', { opacity: 0 }, p)
  g.innerHTML = [-6, 6].map((dx) => `<path d="M${dx * 0.4} 6 Q${dx} -4 ${dx * 1.6} -14" stroke="#C99A78" stroke-width="2" fill="none"/><g transform="translate(${dx * 1.6} -18)"><circle r="7" fill="#fff" stroke="#111" stroke-width="1.4"/><circle data-pupil="1" r="3.2" fill="#111"/></g>`).join('')
  const pupils = [...g.querySelectorAll('[data-pupil]')]
  return (x, y, f, dir = 1) => { sa(g, 'opacity', f > 0 ? 1 : 0); if (f > 0) { sa(g, 'transform', `translate(${x.toFixed(1)} ${y.toFixed(1)}) scale(${(0.4 + 0.8 * ease(Math.min(1, f))).toFixed(2)})`); pupils.forEach((pu) => sa(pu, 'cx', dir * 3)) } }
}
// A speech bubble of comic swearing (or a scream); k scales it.
function bubbleOf(svg, p = svg.world, text = '#@!%&!', ink = '#D21F1F') {
  const g = el('g', { opacity: 0 }, p)
  g.innerHTML = `<path d="M-32 -14 Q-32 -27 -18 -27 H18 Q32 -27 32 -14 V-3 Q32 8 18 8 H-2 L-12 19 L-9 8 H-18 Q-32 8 -32 -3 Z" fill="#fff" stroke="#0A1F42" stroke-width="2"/><text y="-4" text-anchor="middle" font-family="Barlow Condensed, sans-serif" font-weight="900" font-size="16" fill="${ink}">${text}</text>`
  return (x, y, f, k = 1, wob = 0) => { sa(g, 'opacity', Math.max(0, f)); if (f > 0) sa(g, 'transform', `translate(${(x + wob).toFixed(1)} ${y.toFixed(1)}) scale(${(k * (0.7 + 0.3 * ease(Math.min(1, f)))).toFixed(2)})`) }
}
// The anger mark over a head, throbbing.
function vein(svg, p = svg.world) {
  const g = el('path', { d: 'M-7 -2 Q-2 -2 -2 -7 M2 -7 Q2 -2 7 -2 M7 2 Q2 2 2 7 M-2 7 Q-2 2 -7 2', fill: 'none', stroke: '#E11D2E', 'stroke-width': 2.4, 'stroke-linecap': 'round', opacity: 0 }, p)
  return (x, y, f, t = 0) => { sa(g, 'opacity', Math.max(0, f)); if (f > 0) sa(g, 'transform', `translate(${x.toFixed(1)} ${y.toFixed(1)}) scale(${(1 + 0.25 * Math.sin(t * 14)).toFixed(2)})`) }
}
// Short lines bursting out of a point: a whistle blown, a hand slapped, a ring off the bar.
function burst(svg, p = svg.world, color = '#FFFFFF', n = 8) {
  const g = el('g', { stroke: color, 'stroke-width': 2.2, 'stroke-linecap': 'round', opacity: 0 }, p)
  const ls = Array.from({ length: n }, () => el('line', {}, g))
  return (x, y, f, r0 = 8) => {
    const on = f > 0 && f < 1
    sa(g, 'opacity', on ? 1 - f : 0)
    if (on) ls.forEach((l, i) => { const a = (i / n) * Math.PI * 2 + 0.2, d0 = r0 + f * 10, d1 = d0 + 7; sa(l, 'x1', (x + Math.cos(a) * d0).toFixed(1)); sa(l, 'y1', (y + Math.sin(a) * d0).toFixed(1)); sa(l, 'x2', (x + Math.cos(a) * d1).toFixed(1)); sa(l, 'y2', (y + Math.sin(a) * d1).toFixed(1)) })
  }
}
const referee = (w, k = 1.4) => player(w, officialKit(), '', k, { look: 9, shorts: '#111827', socks: '#111827', trim: '#F5B82E' })
// Where a standing figure's head is, drawn with at(x, y, 0, k).
const headOf = (x, y, k) => [x, y - 21 * k]
// The flame round the ball: a shot like a fireball.
function flame(svg, p = svg.world) {
  const g = el('g', { opacity: 0 }, p)
  g.innerHTML = `<circle r="13" fill="#FF7A1A" opacity=".55" filter="${ref(svg, 'glow')}"/><path d="M-9 0 Q-30 -6 -44 0 Q-30 6 -9 0 Z" fill="#FFB23F" opacity=".85"/><path d="M-8 -3 Q-24 -12 -36 -8 Q-22 -2 -8 3 Z" fill="#FF5A1F" opacity=".75"/>`
  return (x, y, dx, dy, on) => { sa(g, 'opacity', on ? 1 : 0); if (on) sa(g, 'transform', `translate(${x.toFixed(1)} ${y.toFixed(1)}) rotate(${Math.round((Math.atan2(dy, dx) * 180) / Math.PI)})`) }
}
// A water bottle by the touchline (the sent-off player kicks it).
function bottle(p) { const g = el('g', {}, p); g.innerHTML = '<rect x="-4" y="-16" width="8" height="16" rx="2.5" fill="#7FC8FF" opacity=".85" stroke="#2D6FA8" stroke-width="1"/><rect x="-2.5" y="-20" width="5" height="4" rx="1" fill="#1F4E8C"/>'; return g }
// [Sprint 42 D1] The foul itself: the victim runs with the ball, the defender slides in feet first (contact at c), the
// victim flies in a flip, lands in a puff of dust and rolls holding his leg (until getUp). Both drawn with at(.., k).
function tackle(svg, t, c, pl, vi, k, fx, getUp = Infinity, quiet = Infinity) {
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
function brawlCloud(svg, p = svg.world) {
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
function danger(svg) {
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
  const b = ball(svg), trl = trail(svg, w, outcome === 'save' ? '#FF9A3D' : undefined)

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
  // [Sprint 42 H2] Ten celebrations: the five before, and a jump with a spin, the aeroplane, a backflip, a dance, and
  // a finger to the lips towards the other side's fans.
  const party = outcome === 'goal' ? pick(['corner', 'slide', 'leap', 'crowd', 'pile', 'spin', 'plane', 'flip', 'dance', 'shush']) : null
  // [Sprint 42 F] The server's telling of the move (e.drama): a nutmeg on the marker before the shot, a no-look pass
  // that pops the defenders' eyes out, a bicycle kick from the cross; a double save keeps the ball alive (a parry).
  const drama = e.drama, nut = drama === 'nutmeg' && (q === 'big' || q === 'normal'), look = drama === 'nolook', bike = drama === 'bicycle' && q === 'header'
  if (drama === 'double' && outcome === 'save') after = 'parry'
  const tN = lerp(tP1, tS, 0.45)
  const aura = nut ? el('circle', { r: 22, fill: 'none', stroke: '#FFD36B', 'stroke-width': 3, opacity: 0, filter: ref(svg, 'glow') }, w) : null
  const daze = nut ? dizzy(svg) : null
  const pop = look ? [popEyes(svg), popEyes(svg)] : null
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
    // The no-look pass: he looks hard the other way while the ball goes this way.
    if (look) passer.face?.(t < tP0 + 0.4 ? 'side' : 'back', recv[0] > pFrom[0] ? -1 : 1)

    // The shooter: runs onto it, a touch to set himself, the strike (or the leap for a header).
    let sx, sy, lift = 0
    if (t < tP1) { const f = inout(seg(t, 0.1, tP1)); sx = lerp(sFrom[0], recv[0], f); sy = lerp(sFrom[1], recv[1], f) }
    else { const f = inout(seg(t, tP1, tS)); sx = lerp(recv[0], spot[0], f); sy = lerp(recv[1], spot[1], f) }
    if (q === 'header') lift = (bike ? 44 : 26) * Math.sin(Math.PI * seg(t, tS - (bike ? 0.45 : 0.32), tS + 0.3))
    // [Sprint 42 C1] A dangerous run: he weaves past his man in a zig-zag before the shot.
    if ((q === 'big' || q === 'normal') && t > tP1 - 0.1 && t < tS) sx += Math.sin((t - tP1) * 15) * 10 * seg(t, tP1 - 0.1, tP1 + 0.15) * (1 - seg(t, tS - 0.3, tS - 0.08))
    // Round the keeper: a touch past him to the side, then the finish.
    if (finish === 'round') sx -= side * 36 * ease(seg(t, tS - 0.5, tS - 0.05))
    // The bicycle kick: he turns right over in the air, his back to the goal, and lands.
    const flip = bike ? 190 * inout(seg(t, tS - 0.45, tS)) * (1 - inout(seg(t, tS + 0.1, tS + 0.45))) : 0
    put(sh, sx, sy, bike ? -side * flip : q === 'header' ? -side * 8 * seg(t, tS - 0.3, tS) : 0, 1, lift)
    if (t > KT + 0.5 && outcome === 'goal') {
      // [Sprint 36 F1] The celebration, one of five (from the scene's seed): away to the corner flag arms out, a
      // slide on his knees, a leap punching the air, arms wide towards the crowd, or his team-mates piling on him.
      const c = ease(seg(t, KT + 0.5, KT + 2.6))
      if (party === 'spin') {
        const j = seg(t, KT + 0.9, KT + 1.5), up = Math.sin(Math.PI * j) * 34; put(sh, lerp(spot[0], spot[0] + out * 70, c), spot[1] + 14, 0, 1, up)
        sh.face?.(j > 0 && j < 1 ? (Math.floor(j * 4) % 2 ? 'side' : 'front') : j >= 1 ? 'front' : 'back', out); sh.mood('joy'); j >= 1 ? sh.pose(26, -26, 50, -50) : sh.pose(6, -6, 30, -30)
      } else if (party === 'plane') {
        put(sh, lerp(spot[0], spot[0] + out * 160, c) , lerp(spot[1], spot[1] + 34, c) + Math.sin((t - KT) * 6) * 10, Math.sin((t - KT) * 6) * 16); sh.pose(6, -6, 92, -92)
      } else if (party === 'flip') {
        const j = seg(t, KT + 0.9, KT + 1.5), up = Math.sin(Math.PI * j) * 40; put(sh, spot[0] + out * 40 * c, spot[1] + 14, -out * 360 * inout(j), 1, up); j < 1 && j > 0 ? sh.pose(60, 60, 120, -120) : sh.pose(6, -6, 160, -160)
      } else if (party === 'dance') {
        put(sh, spot[0] + out * 50 * c, spot[1] + 16, Math.sin((t - KT) * 10) * 10); sh.face?.('front'); sh.mood('joy'); const d = Math.sin((t - KT) * 10); sh.pose(10 * d, -10 * d, 60 + 40 * d, -60 + 40 * d, Math.max(0, d) * 0.4, Math.max(0, -d) * 0.4)
      } else if (party === 'shush') {
        put(sh, lerp(spot[0], 320 - out * 40, c), lerp(spot[1], 290, c), 0, 1.1); sh.face?.('front'); sh.mood('focus'); sh.pose(4, -4, 14, 158)
      } else if (party === 'slide') {
        const sl = ease(seg(t, KT + 0.7, KT + 1.6)); put(sh, lerp(spot[0], spot[0] + out * 120, c), lerp(spot[1], spot[1] + 40, c), -out * 18 * sl, 1, -10 * sl); sh.pose(70, 70, 140, -140)
      } else if (party === 'leap') {
        const up = Math.abs(Math.sin((t - KT) * 5)) * 22 * seg(t, KT + 0.6, KT + 0.9); put(sh, lerp(spot[0], spot[0] + out * 40, c), spot[1] + 10, 0, 1, up); sh.pose(10, -10, 175, -20)
      } else if (party === 'crowd') {
        put(sh, lerp(spot[0], 320 + out * 30, c), lerp(spot[1], 300, c), 0, 1.15); sh.face?.('front'); sh.mood?.('joy'); sh.pose(6, -6, 95, -95)
      } else if (party === 'pile') {
        put(sh, lerp(spot[0], spot[0] + out * 60, c), lerp(spot[1], spot[1] + 20, c)); sh.celebrate(t)
      } else { put(sh, lerp(spot[0], spot[0] + out * 150, c), lerp(spot[1], spot[1] + 30, c)); sh.celebrate(t) }
      // The team-mates: the one nearest runs to him, and in a pile-on the passer too, arms around him.
      const near = party === 'pile' ? 0.92 : 0.8
      put(mate, lerp(640 - lx - side * 10, lerp(spot[0], spot[0] + out * 150, c) - out * 18 * (1 - near), c), lerp(214, spot[1] + 30, c)); mate.celebrate(t + 0.4)
      if (party === 'pile') { const pc = ease(seg(t, KT + 0.8, KT + 2.4)); put(passer, lerp(spot[0] - side * 60, spot[0] + out * 66, pc), lerp(spot[1] + 30, spot[1] + 26, pc)); passer.pose(6, -6, 120, -60) }
    } else if (t > KT + 0.3 && outcome !== 'goal') sh.despair()
    else if (bike && t > tS - 0.45 && t < tS + 0.45) sh.pose(30, -150 * Math.sin(Math.PI * seg(t, tS - 0.3, tS + 0.1)), 120, -120, 0.2, 0)
    else if (q === 'header' && t > tS - 0.35) sh.pose(10, -10, 60, -60, 0.4, 0.4)
    else if (t > tS - 0.32 && t < tS + 0.3) sh.kick(seg(t, tS - 0.32, tS + 0.12))
    else sh.run(t * 13, t < tS ? 1 : 0.2)

    // The marker chases from behind; on a block he slides across the shot.
    const mk = ease(seg(t, 0.1, tS))
    let mx = lerp(sFrom[0] + side * 30, sx + side * 16, mk), my = lerp(sFrom[1] - 12, sy - 8, mk), mr = 0
    let low = 0
    if (outcome === 'blocked') { const sl = ease(seg(t, tS - 0.3, KT)); mx = lerp(mx, target[0] + side * 10, sl); my = lerp(my, target[1] + 6, sl); mr = -side * 72 * sl; low = -30 * persp(my) * sl }
    // The nutmeg: the marker squares up in front of him, the ball goes through his legs, his legs twist round in a
    // corkscrew and he goes down on his back with stars round his head.
    if (nut && t > tN - 0.45) { const st = ease(seg(t, tN - 0.45, tN - 0.2)); mx = lerp(mx, sx - side * 16, st); my = lerp(my, sy - 16, st) }
    // The close-up on the feet for the nutmeg, then back out for the shot.
    if (nut) { const z = ease(seg(t, tN - 0.4, tN - 0.15)) * (1 - ease(seg(t, tN + 0.55, tN + 0.85))); if (z > 0) cam(svg, lerp(1.18, 1.9, z), lerp(320, sx, z), lerp(168, sy - 14, z)) }
    const twist = nut ? seg(t, tN, tN + 0.35) : 0, down = nut ? ease(seg(t, tN + 0.3, tN + 0.55)) : 0
    put(marker, mx, my, nut ? -side * (twist * 540 * (1 - down) + 90 * down) : mr, 1, nut ? -24 * persp(my) * down : low)
    if (nut && t > tN) marker.pose(-20 + 40 * Math.sin(t * 30) * (1 - down), 20 - 40 * Math.sin(t * 30) * (1 - down), 60, -60)
    else { outcome === 'blocked' && t > tS - 0.3 ? marker.pose(30, -30, 80, -40) : marker.run(t * 12.5, mk < 1 ? 1 : 0.3) }
    if (outcome === 'goal' && t > KT + 0.4 && !nut) marker.despair()
    if (nut) {
      daze(mx + side * 14 * persp(my), my - 20 * persp(my), t, t > tN + 0.5)
      const on = seg(t, tN - 0.05, tN + 0.1) * (1 - seg(t, tS - 0.1, tS + 0.2)), s0 = persp(sy)
      sa(aura, 'opacity', on); if (on > 0) sa(aura, 'transform', `translate(${sx.toFixed(1)} ${(sy - 30 * s0).toFixed(1)}) scale(${(s0 * (1.6 + 0.15 * Math.sin(t * 16))).toFixed(2)} ${(s0 * 2.4).toFixed(2)})`)
    }
    // The no-look pass: both defenders' eyes pop out on stalks, following the ball the wrong way.
    if (look) {
      const f = seg(t, tP0, tP0 + 0.12) * (1 - seg(t, tP0 + 0.85, tP0 + 1.0)), dir = recv[0] > pFrom[0] ? 1 : -1
      const cx = lerp(320 - side * 40, lerp(spot[0], 320, 0.55), ease(seg(t, 0.3, tS))), cy = lerp(204, 196, ease(seg(t, 0.3, tS)))
      pop[0](cx, cy - 80 * persp(cy), f, dir); pop[1](mx, my - 80 * persp(my), f, dir)
    }

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
      // Through his legs, and collected on the other side.
      if (nut && t > tN - 0.15 && t < tN + 0.25) { const f = seg(t, tN - 0.15, tN + 0.25); by = lerp(sy + 2, sy - 30, Math.sin(Math.PI * f) * 0.9); gr = by }
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
    // [Sprint 42 C2] The net stretches far back, as in a cartoon; the woodwork wobbles hard.
    if (after === 'net') G.bulge(target[0], target[1] - 8, 1.9 * seg(t, KT, KT + 0.1) * (1 - seg(t, KT + 0.3, KT + 1.3)))
    if (after === 'post') { const wob = seg(t, KT, KT + 0.05) * (1 - seg(t, KT + 0.1, KT + 1.0)); sa(G.frame, 'transform', `translate(${(Math.sin(t * 70) * 4.5 * wob).toFixed(1)} ${(Math.cos(t * 55) * 1.5 * wob).toFixed(1)})`) }
    return { target, sx, sy, tS, tN, dir: [spot[0] - sFrom[0], spot[1] - sFrom[1]], ball: [bx, by], sh, kp, glove, after, b, mate, trl }
  } }
}

// ---------------------------------------------------------------- [Sprint 42 H1] the TV studio
// The owner's (2026-11-03): the match shown like TV, with commentators in a studio. Between the moments the picture
// is the studio: an LED wall with the score and the running clock, and two cartoon commentators at their desk with
// headsets, talking in turn when a line is said, and on their feet at a goal. Drawing only (MatchFeed feeds it).
// [Sprint 42 J2] The commentators' reactions. f: 0..1 over about three seconds; side: 1 the left one, -1 the right one
// (each faces the other). Returns how far he moves (dx towards the other, dy up), his lean, his arms (as pose()), his
// face and the word over his head.
const REACTIONS = {
  jump: (f, t) => ({ dy: Math.abs(Math.sin(t * 9)) * 16, pose: [6, -6, 155 + Math.sin(t * 12) * 12, -155 - Math.sin(t * 12) * 12], mood: 'joy', sym: 'GOAL!' }),
  hug: (f) => ({ dx: 70 * Math.sin(Math.PI * f), r: 8 * Math.sin(Math.PI * f), pose: [4, -4, 95, -40], mood: 'joy', sym: '♥' }),
  desk: (f, t) => ({ dy: -2, pose: [4, -4, 20 + Math.abs(Math.sin(t * 14)) * 70, -20 - Math.abs(Math.sin(t * 14 + 1)) * 70], mood: 'joy', sym: 'BAM!' }),
  spin: (f) => ({ face: f > 0.2 && f < 0.6 ? 'back' : 'front', dy: 8 * Math.sin(Math.PI * f), pose: [4, -4, 120, -120], mood: 'joy', sym: 'YES!' }),
  applaud: (f, t) => ({ pose: [4, -4, 70 + Math.sin(t * 22) * 22, -70 + Math.sin(t * 22) * 22], mood: 'joy', sym: '★★★' }),
  wow: (f) => ({ r: -6 * Math.sin(Math.PI * f), pose: [4, -4, 100, -100], mood: 'shock', sym: 'WOW!' }),
  headhands: () => ({ pose: [4, -4, 150, -150], mood: 'shock', sym: '!?' }),
  facepalm: () => ({ r: 6, pose: [4, -4, 22, 160], mood: 'sad', sym: '...' }),
  leanback: (f) => ({ r: -10 * Math.sin(Math.PI * f), dy: -4, pose: [4, -4, 40, -40], mood: 'sad', sym: 'OHH' }),
  point: (f, t) => ({ pose: [4, -4, 88 + Math.sin(t * 10) * 6, -22], mood: 'angry', sym: '!' }),
  headshake: (f, t) => ({ r: Math.sin(t * 16) * 6, pose: [4, -4, 22, -22], mood: 'angry', sym: 'NO!' }),
  crossarms: () => ({ pose: [4, -4, -30, 30], mood: 'focus', sym: 'hmm' }),
  laugh: (f, t) => ({ dy: Math.abs(Math.sin(t * 18)) * 5, r: Math.sin(t * 9) * 4, pose: [4, -4, 40, -40], mood: 'joy', sym: 'HAHA' }),
  eyeroll: (f) => ({ r: 4, pose: [4, -4, -20, 20], mood: 'peek', sym: '¬_¬' }),
  worried: (f, t) => ({ r: Math.sin(t * 3) * 2, pose: [4, -4, -20, 20], mood: 'sad', sym: '...' }),
  nails: (f, t) => ({ dy: Math.sin(t * 20) * 1.5, pose: [4, -4, 150, -22], mood: 'shock', sym: '!!' }),
  nod: (f, t) => ({ dy: Math.max(0, Math.sin(t * 8)) * 3, pose: [4, -4, 22, -22], mood: 'focus', sym: '✓' }),
  notes: (f, t) => ({ pose: [4, -4, 30 + Math.sin(t * 14) * 6, -30], mood: 'focus', sym: '✎' }),
  monitor: (f) => ({ face: 'side', dx: 22 * Math.sin(Math.PI * Math.min(1, f * 1.4)), pose: [4, -4, 30, -30], mood: 'focus', sym: '?' }),
  handshake: (f) => ({ dx: 50 * Math.sin(Math.PI * f), pose: [4, -4, 22, -85], mood: 'joy', sym: '' }),
  dance: (f, t) => ({ dy: Math.abs(Math.sin(t * 10)) * 8, r: Math.sin(t * 10) * 8, pose: [4, -4, 90 + Math.sin(t * 10) * 40, -90 + Math.sin(t * 10) * 40], mood: 'joy', sym: '♪♪' }),
}
// What each moment may draw from them (MatchFeed names the moment). Each commentator picks his own.
const REACT_POOLS = {
  goal: ['jump', 'hug', 'desk', 'spin', 'dance', 'applaud'], save: ['applaud', 'wow', 'headhands', 'point'], miss: ['facepalm', 'headhands', 'leanback', 'wow'],
  post: ['headhands', 'wow', 'facepalm'], yellow: ['point', 'headshake', 'crossarms', 'nod'], red: ['wow', 'headshake', 'point', 'headhands'],
  brawl: ['wow', 'headhands', 'laugh', 'headshake'], foul: ['worried', 'headshake', 'point'], dive: ['laugh', 'eyeroll', 'headshake'],
  injury: ['worried', 'nails'], sub: ['nod', 'notes', 'crossarms'], var: ['monitor', 'crossarms', 'headshake'], offside: ['monitor', 'point', 'nod'],
  penalty_goal: ['jump', 'applaud', 'nails'], penalty_miss: ['headhands', 'wow', 'nails'], freekick: ['wow', 'applaud', 'leanback'],
  corner: ['nod', 'notes'], coach: ['laugh', 'notes', 'nod'], slip: ['laugh', 'wow', 'facepalm'], whistle: ['handshake', 'notes', 'nod'],
  clearance: ['wow', 'applaud', 'headhands'], double: ['applaud', 'wow', 'jump'], blackout: ['wow', 'laugh', 'headhands'], calm: ['nod', 'notes'],
}
export const REACT_COUNT = Object.keys(REACTIONS).length

export function studio(kits, seed = 1, day = false) {
  // [Sprint 42 J2] Each match its studio: the LED wall's colours, the desk's trim and the two commentators (their
  // faces, hair, suits and ties), all from the match's seed. [Sprint 43 C7] By day in the day look.
  const SR = rnd((Number(seed) || 1) * 101 + 17)
  const THEMES = [['#0E2A5C', '#123A7A', '#0A2148', '#0B1A3A'], ['#2A1352', '#3B1D74', '#1E0E3D', '#170B30'], ['#063F45', '#0B5C63', '#052E33', '#06232A'], ['#4A0E1E', '#6B1428', '#330915', '#210610']]
  const TH = THEMES[Math.floor(SR() * THEMES.length)], TRIM = SR() < 0.6 ? ['#C08A0C', '#FFD36B'] : ['#8C96A8', '#F2F5FA']
  const SUITS = ['#22304F', '#2A2F45', '#3A2A2A', '#1F3B34', '#2E2E2E', '#3A3150', '#1C2A3F'], TIES = ['#F5B82E', '#7FB4FF', '#D21F1F', '#2BB673', '#E85D9A', '#FFFFFF']
  const crew = [0, 1].map(() => ({ suit: SUITS[Math.floor(SR() * SUITS.length)], tie: TIES[Math.floor(SR() * TIES.length)], look: Math.floor(SR() * 42) }))
  const svg = el('svg', { viewBox: '0 0 640 340', preserveAspectRatio: 'xMidYMid slice', direction: 'ltr' }), id = 's' + ++uid
  svg.style.direction = 'ltr'
  svg.dataset.id = id
  const H = kits?.home?.kit ?? '#C8102E', A = kits?.away?.kit ?? '#1E4FA8'
  svg.innerHTML = `<defs>
    <linearGradient id="${id}bg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${day ? '#DCEBF7' : TH[3]}"/><stop offset="1" stop-color="${day ? '#8FB0CF' : '#040B1C'}"/></linearGradient>
    <linearGradient id="${id}led" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="${TH[0]}"/><stop offset=".5" stop-color="${TH[1]}"/><stop offset="1" stop-color="${TH[2]}"/></linearGradient>
    <linearGradient id="${id}desk" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#1A2B4D"/><stop offset="1" stop-color="#0A1328"/></linearGradient>
    <linearGradient id="gold${id}" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="${TRIM[0]}"/><stop offset=".5" stop-color="${TRIM[1]}"/><stop offset="1" stop-color="${TRIM[0]}"/></linearGradient>
    <filter id="glow${id}" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="4" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter>
    <filter id="soft${id}"><feGaussianBlur stdDeviation="14"/></filter>
  </defs>
  <rect width="640" height="340" fill="url(#${id}bg)"/>
  <radialGradient id="${id}la"><stop offset="0" stop-color="${A}" stop-opacity=".35"/><stop offset="1" stop-color="${A}" stop-opacity="0"/></radialGradient><radialGradient id="${id}lh"><stop offset="0" stop-color="${H}" stop-opacity=".35"/><stop offset="1" stop-color="${H}" stop-opacity="0"/></radialGradient>
  <circle cx="80" cy="60" r="130" fill="url(#${id}la)"/><circle cx="560" cy="60" r="130" fill="url(#${id}lh)"/>
  ${Array.from({ length: 9 }, (_, i) => `<rect x="${i * 72 - 4}" y="0" width="2" height="250" fill="rgba(255,255,255,.05)"/>`).join('')}
  <rect x="150" y="18" width="340" height="132" rx="10" fill="url(#${id}led)" stroke="url(#gold${id})" stroke-width="3"/>
  <g data-ledgrid="1" opacity=".18">${Array.from({ length: 22 }, (_, i) => `<rect x="${158 + i * 15}" y="26" width="1" height="116" fill="#7FB4FF"/>`).join('')}</g>
  <rect x="150" y="18" width="12" height="132" fill="${A}" opacity=".9"/><rect x="478" y="18" width="12" height="132" fill="${H}" opacity=".9"/>
  <text x="320" y="44" text-anchor="middle" font-family="Barlow Condensed, sans-serif" font-weight="800" font-size="15" letter-spacing="4" fill="#FFD36B">GLM · LIVE</text>
  <text data-score="1" x="320" y="88" text-anchor="middle" font-family="Barlow Condensed, sans-serif" font-weight="800" font-size="40" fill="#fff"></text>
  <text data-clock="1" x="320" y="130" text-anchor="middle" font-family="Barlow Condensed, sans-serif" font-weight="800" font-size="34" fill="#FFD36B" stroke="rgba(245,184,46,.35)" stroke-width="4" paint-order="stroke"></text>
  <ellipse cx="320" cy="250" rx="300" ry="30" fill="${day ? '#6F8FB2' : '#0E2246'}" opacity=".9"/>
  <g data-spot="1" opacity=".0"><path d="M120 0 L180 0 L260 250 L60 250 Z" fill="#FFF6DA" opacity=".07"/><path d="M460 0 L520 0 L580 250 L380 250 Z" fill="#FFF6DA" opacity=".07"/></g>`
  const g = el('g', {}, svg)
  const suit = (trim) => ({ look: 0, shorts: '#1F2937', socks: '#111827', trim })
  const c1 = player(g, crew[0].suit, '', 2.1, { ...suit(crew[0].tie), look: crew[0].look }), c2 = player(g, crew[1].suit, '', 2.1, { ...suit(crew[1].tie), look: crew[1].look })
  // Headsets with their mics.
  const hs = [0, 1].map(() => { const e = el('g', {}, g); e.innerHTML = '<path d="M-11 -24 Q0 -38 11 -24" fill="none" stroke="#111" stroke-width="2.4"/><rect x="-12.5" y="-25" width="4" height="7" rx="1.5" fill="#111"/><rect x="8.5" y="-25" width="4" height="7" rx="1.5" fill="#111"/><path d="M-10.5 -19 Q-9 -12 -3 -13" fill="none" stroke="#111" stroke-width="1.6"/><circle cx="-2.5" cy="-13" r="1.6" fill="#F5B82E"/>'; return e })
  // The desk in front of them: curved, with the channel's mark, two mics and a laptop.
  const desk = el('g', {}, svg)
  desk.innerHTML = `<path d="M40 236 Q320 206 600 236 L620 340 L20 340 Z" fill="url(#${id}desk)" stroke="url(#gold${id})" stroke-width="3"/>
    <path d="M70 262 Q320 236 570 262" fill="none" stroke="rgba(127,180,255,.25)" stroke-width="2"/>
    <text x="320" y="262" text-anchor="middle" font-family="Barlow Condensed, sans-serif" font-weight="900" font-size="22" letter-spacing="6" fill="url(#gold${id})">GLM TV</text>
    <rect x="290" y="214" width="60" height="22" rx="3" fill="#0A0F1C" stroke="#3A4256"/><rect x="294" y="217" width="52" height="15" fill="#123A7A" opacity=".8"/>
    <g fill="#111"><rect x="196" y="206" width="4" height="26"/><ellipse cx="198" cy="204" rx="6" ry="8"/><rect x="438" y="206" width="4" height="26"/><ellipse cx="440" cy="204" rx="6" ry="8"/></g>`
  const score = svg.querySelector('[data-score]'), clockT = svg.querySelector('[data-clock]'), spot = svg.querySelector('[data-spot]')
  const POS = [[190, 196], [450, 196]]
  // [Sprint 42 J2] Over each head, the word of his reaction.
  const syms = [0, 1].map(() => el('text', { 'text-anchor': 'middle', 'font-family': 'Barlow Condensed, sans-serif', 'font-weight': 900, 'font-size': 22, fill: '#FFD36B', stroke: '#040B1C', 'stroke-width': 4, 'paint-order': 'stroke', opacity: 0 }, svg))
  let lastScore = null, react = null, picks = null
  return {
    svg,
    /** t: seconds. st: { clock, score ('away - home', home on the right as on the scorebar), frozen, talk (0 none, 1 or 2: who is talking), hype (0..1, a goal) } */
    update(t, st) {
      if (st.score !== lastScore) { lastScore = st.score; score.textContent = st.score }
      if (clockT.textContent !== st.clock) clockT.textContent = st.clock
      sa(clockT, 'opacity', st.frozen ? (Math.floor(t * 2.5) % 2 ? 0.35 : 1) : 1)
      const hype = st.hype ?? 0
      sa(spot, 'opacity', (hype * (0.6 + 0.4 * Math.sin(t * 9))).toFixed(2))
      // [Sprint 42 J2] Back from a clip, each commentator reacts to it, each in his own way (from the pool for that
      // moment, by the minute's seed): about three seconds, then back to talking.
      if (st.react && st.react !== react) { react = st.react; const R = rnd((react.seed >>> 0) + 1), pool = REACT_POOLS[react.key] ?? REACT_POOLS.calm; picks = [pool[Math.floor(R() * pool.length)], pool[Math.floor(R() * pool.length)]] }
      const rf = react ? (t - react.t0) / 3 : 2
      ;[c1, c2].forEach((c, i) => {
        const [x0, y0] = POS[i]
        if (rf >= 0 && rf < 1 && picks) {
          const r = REACTIONS[picks[i]]?.(rf, t, i ? -1 : 1) ?? {}
          const dx = (r.dx ?? 0) * (i ? -1 : 1), y = y0 - (r.dy ?? 0)
          c.face?.(r.face ?? 'front', i ? -1 : 1); c.mood(r.mood ?? 'idle'); c.at(x0 + dx, y, (r.r ?? 0) * (i ? -1 : 1), 2.1)
          const P = r.pose ?? [4, -4, 22, -22]; c.pose(...(i ? [P[1] * -1, P[0] * -1, -P[3], -P[2]] : P))
          sa(hs[i], 'transform', `translate(${(x0 + dx).toFixed(1)} ${y.toFixed(1)}) rotate(${((r.r ?? 0) * (i ? -1 : 1)).toFixed(1)}) scale(2.1)`)
          const so = seg(rf, 0.05, 0.15) * (1 - seg(rf, 0.8, 0.95))
          syms[i].textContent = r.sym ?? ''
          sa(syms[i], 'opacity', r.sym ? so.toFixed(2) : 0); sa(syms[i], 'x', (x0 + dx).toFixed(1)); sa(syms[i], 'y', (y - 78 - so * 6).toFixed(1))
          return
        }
        sa(syms[i], 'opacity', 0)
        const talking = st.talk === i + 1, [x, y] = POS[i], up = hype > 0 ? 18 * hype + Math.abs(Math.sin(t * 8 + i)) * 6 * hype : 0
        c.face?.('front')
        c.mood(hype > 0 ? 'joy' : talking ? (Math.floor(t * 8 + i) % 2 ? 'talk' : 'idle') : 'idle')
        // A little sway of the head as they listen; hands moving as they talk; arms up at a goal.
        const sway = Math.sin(t * 1.3 + i * 2) * 1.5
        c.at(x + sway, y - up, sway * 0.6, 2.1)
        if (hype > 0) c.pose(4, -4, 150 + Math.sin(t * 10 + i) * 15, -150 - Math.sin(t * 10 + i) * 15)
        else if (talking) c.pose(4, -4, 40 + Math.sin(t * 6) * 18, -40 - Math.cos(t * 5) * 18)
        else c.pose(4, -4, 22, -22)
        sa(hs[i], 'transform', `translate(${(x + sway).toFixed(1)} ${(y - up).toFixed(1)}) rotate(${(sway * 0.6).toFixed(1)}) scale(2.1)`)
      })
    },
  }
}

// ---------------------------------------------------------------- scenes: one per kind of moment
// Lengths and key moments are SCENE_TIME in story.ts; keep them in step.
export const SCENES = {
  goal(e) {
    const KT = 3.0, { svg, go } = openPlay(e, 'goal', KT), dg = danger(svg), cf2 = confetti(svg)
    const bike = e.drama === 'bicycle' && e.quality === 'header', dark = e.drama === 'blackout'
    // [Sprint 42 F5] The bicycle kick in slow motion: the build-up quicker, the flip and the strike slower, the ball in
    // at the same instant (KT), with a trail of fire and black bars as at the cinema.
    const warp = (t) => { if (!bike || t <= 0.4 || t >= KT) return t; const s = (t - 0.4) / (KT - 0.4); return 0.4 + (KT - 0.4) * (s < 0.5 ? s * 1.3 : 0.65 + (s - 0.5) * 0.7) }
    const fire = bike ? flame(svg) : null, bars = bike ? el('g', { opacity: 0 }, svg) : null
    if (bars) bars.innerHTML = '<rect width="640" height="38" fill="#000"/><rect y="302" width="640" height="38" fill="#000"/>'
    // [Sprint 42 F9] The blackout: the lights go just before the shot, only eyes in the dark, a click, and the lights
    // come back with the ball in the net.
    const black = dark ? el('g', { opacity: 0 }, svg) : null
    if (black) black.innerHTML = '<rect width="640" height="340" fill="#02030A"/>' + [[320, 120], [250, 210], [400, 200], [180, 250], [470, 260], [330, 230]].map(([x, y], i) => `<g data-eyes="${i}" transform="translate(${x} ${y})"><ellipse cx="-6" rx="4.5" ry="5.5" fill="#fff"/><ellipse cx="6" rx="4.5" ry="5.5" fill="#fff"/><circle data-p="1" cx="-6" r="2" fill="#000"/><circle data-p="1" cx="6" r="2" fill="#000"/></g>`).join('') + '<text data-click="1" x="320" y="70" text-anchor="middle" font-family="Barlow Condensed, sans-serif" font-weight="900" font-size="34" fill="#FFD400" opacity="0">*CLICK*</text>'
    const pupils = black ? [...black.querySelectorAll('[data-p]')] : [], click = black?.querySelector('[data-click]')
    const num = bigNumber(svg, e.no, K(e.side).kit), fl = flash(svg), cf = flashes(svg), tt = title(svg, tr('هدف!'))
    let last = null
    return { dur: 6.0, svg, update(t) {
      const u = warp(t), r = go(u); dg(u, r); num(seg(t, KT + 0.6, KT + 1.4)); cf(t, t > KT)
      fl(seg(t, KT - 0.01, KT + 0.05) * (1 - seg(t, KT + 0.05, KT + 0.25)) * 0.16)
      // [Sprint 42 C2] The net stretches, the screen shakes, and the confetti rains on the celebration.
      shakeIt(svg, 7 * seg(t, KT, KT + 0.04) * (1 - seg(t, KT + 0.05, KT + 0.6)), t)
      cf2(t - KT - 0.3)
      if (bike) {
        sa(bars, 'opacity', seg(t, 1.6, 1.9) * (1 - seg(t, KT + 0.2, KT + 0.5)))
        fire(r.ball[0], r.ball[1], last ? r.ball[0] - last[0] : 1, last ? r.ball[1] - last[1] : 0, u > r.tS && u < KT)
        last = r.ball
      }
      if (dark) {
        const off = seg(t, r.tS - 0.25, r.tS - 0.15) * (1 - seg(t, KT + 0.6, KT + 1.0))
        sa(black, 'opacity', off.toFixed(2))
        // The eyes blink and dart about in the dark.
        pupils.forEach((p, i) => sa(p, 'transform', `translate(${(Math.sin(t * 5 + i) * 2).toFixed(1)} 0)`))
        sa(click, 'opacity', seg(t, KT + 0.4, KT + 0.45) * (1 - seg(t, KT + 0.8, KT + 1.0)))
      }
      tt(seg(t, dark ? KT + 0.9 : KT + 0.2, dark ? KT + 1.3 : KT + 0.6))
    } }
  },
  save(e) {
    const KT = 2.9, { svg, go } = openPlay(e, 'save', KT), dg = danger(svg), fire = flame(svg), pow = boom(svg, svg.world, 'BOOM!')
    const double = e.drama === 'double', pow2 = double ? boom(svg, svg.world, 'BOOM!') : null, blue = double ? tint(svg, '#3B82F6') : null
    const ring = el('circle', { r: 26, fill: 'none', stroke: '#2BB673', 'stroke-width': 3, opacity: 0, filter: ref(svg, 'glow') }, svg.world)
    const tt = title(svg, double ? tr('تصدٍّ مزدوج!') : tr('تصدٍّ رائع'), '#2BB673')
    let last = null, land = null
    return { dur: 5.4, svg, update(t) {
      const r = go(t), { target } = r; dg(t, r)
      // [Sprint 42 C3] The shot a fireball to the top corner; the keeper's fingertips go BOOM.
      const fly = t > r.tS && t < KT
      fire(r.ball[0], r.ball[1], last ? r.ball[0] - last[0] : 1, last ? r.ball[1] - last[1] : 0, fly)
      last = r.ball
      pow(target[0], target[1], seg(t, KT - 0.02, KT + 0.7))
      shakeIt(svg, 4 * seg(t, KT, KT + 0.04) * (1 - seg(t, KT + 0.05, KT + 0.4)) + (double ? 4 * seg(t, KT + 1.35, KT + 1.38) * (1 - seg(t, KT + 1.4, KT + 1.7)) : 0), t)
      const s = seg(t, KT - 0.02, KT + 0.6); sa(ring, 'transform', `translate(${target[0]} ${target[1]}) scale(${0.4 + s * 1.6})`); sa(ring, 'opacity', s > 0 ? 1 - s : 0)
      // [Sprint 42 F2] The double save: the rebound falls to a team-mate who hits it at once; the keeper, still on the
      // ground, pushes off with one hand and flings himself across to block it with his foot.
      if (double) {
        const dx = Math.sign(target[0] - 320) || 1, reb = [target[0] + dx * 96, 196], aim = [320 - dx * 34, 128]
        if (t < KT + 0.9) land = r.glove ?? land
        const L = land ?? [target[0], LINE - 6]
        if (t > KT + 0.3) {
          const run = ease(seg(t, KT + 0.3, KT + 0.85)); put(r.mate, lerp(reb[0] + dx * 40, reb[0] + dx * 10, run), reb[1] + 36)
          t > KT + 0.8 && t < KT + 1.1 ? r.mate.kick(seg(t, KT + 0.8, KT + 1.05)) : t > KT + 1.5 ? r.mate.pose(3, -3, 150, -150) : r.mate.run(t * 13, 1 - run)
        }
        if (t > KT + 0.95) {
          const f = seg(t, KT + 0.95, KT + 1.35), up = Math.sin(Math.PI * Math.min(1, f * 1.1)), s0 = persp(LINE)
          const kx = lerp(L[0], aim[0] + dx * 10, ease(f)), ky = lerp(L[1] + 20 * s0, aim[1] + 30, ease(f)) - up * 26
          r.kp.at(kx, ky, -dx * (90 + 300 * ease(f)), s0); r.kp.pose(lerp(10, 80, f), -lerp(10, 110, f), 40 + 60 * (1 - f), -150)
          let p, gr
          if (t < KT + 1.35) { const g = seg(t, KT + 1.0, KT + 1.35); p = bez([reb, [lerp(reb[0], aim[0], 0.5), 150], aim], g); gr = lerp(reb[1], LINE, g) }
          else { const g = ease(seg(t, KT + 1.35, KT + 2.1)); p = bez([aim, [aim[0] - dx * 60, 60], [aim[0] - dx * 190, 150]], g); gr = lerp(LINE, 150, g) }
          r.b.set(p[0], p[1], gr, t * 1800, 1 - seg(t, KT + 1.9, KT + 2.1))
          pow2(aim[0], aim[1], seg(t, KT + 1.33, KT + 2.0))
          blue(0.3 * seg(t, KT + 1.35, KT + 1.42) * (1 - seg(t, KT + 1.55, KT + 1.9)))
        }
      }
      tt(seg(t, double ? KT + 1.5 : KT + 0.3, double ? KT + 1.9 : KT + 0.7))
    } }
  },
  miss(e) {
    const KT = 2.9, { svg, go } = openPlay(e, 'miss', KT), dg = danger(svg), post = e.how === 'post'
    // [Sprint 42 H2] Over the bar, one in two: into the stand, where a fan catches it and his popcorn goes everywhere.
    // Wide, one in two: it hits the photographer behind the goal, who goes over backwards, his flash going off.
    const V = rnd((e.v ?? 3) * 7 + 1)(), fan = e.how === 'over' && V < 0.5, snap = e.how === 'wide' && V < 0.5
    const fanG = fan ? el('g', { opacity: 0 }, svg.world) : null
    if (fanG) fanG.innerHTML = '<rect x="-11" y="0" width="22" height="26" rx="7" fill="' + (K(other(e.side)).kit) + '"/><circle cy="-9" r="9" fill="#D9A982"/><circle cx="-3" cy="-10" r="1.4" fill="#111"/><circle cx="3" cy="-10" r="1.4" fill="#111"/><ellipse cx="0" cy="-4" rx="2.2" ry="2.8" fill="#5A1A14"/><rect data-a="1" x="-15" y="-2" width="5" height="18" rx="2.5" fill="' + (K(other(e.side)).kit) + '"/><rect data-a="2" x="10" y="-2" width="5" height="18" rx="2.5" fill="' + (K(other(e.side)).kit) + '"/><path d="M12 18 L22 18 L20 30 L14 30 Z" fill="#E9EEF6" stroke="#D21F1F"/>'
    const corn = fan ? dust(svg, svg.world, 12, ['#FFF3C4', '#FFE08A', '#FFFFFF']) : null
    const ph = snap ? player(svg.world, '#2A2F45', '', 0.9, { look: 13, shorts: '#111827', socks: '#111827' }) : null
    const cam2 = snap ? el('g', {}, svg.world) : null
    if (cam2) cam2.innerHTML = '<rect x="-8" y="-6" width="16" height="11" rx="2" fill="#111"/><circle r="4" fill="#333" stroke="#888"/><rect x="-4" y="-9" width="8" height="3" fill="#111"/>'
    const flashB = snap ? burst(svg, svg.world, '#FFFFFF', 12) : null, ouch = snap ? boom(svg, svg.world, 'BONK!') : null
    // [Sprint 42 C4] The woodwork: it rings and shakes the screen, a flash of blue shock, the striker's hands on his head.
    const blue = post ? tint(svg, '#3B82F6') : null, clang = post ? boom(svg, svg.world, 'CLANG!', '#E9EEF6', '#1E3A8A') : null, ringL = post ? burst(svg, svg.world, '#FFFFFF', 10) : null
    const tt = title(svg, e.how === 'post' ? tr('القائم!') : e.how === 'over' ? tr('فوق العارضة') : tr('بجانب القائم'), '#C9D2E1')
    return { dur: 5.0, svg, update(t) {
      const r = go(t); dg(t, r)
      if (fan) {
        // In the stand beside the goal; the ball flies on into his hands.
        const x = r.target[0] + (r.target[0] >= 320 ? 120 : -120), y = 92, f = seg(t, KT + 0.1, KT + 0.25)
        if (t > KT) { const g = ease(seg(t, KT, KT + 0.45)); const p = bez([r.target, [lerp(r.target[0], x, 0.5), 20], [x, y - 4]], g); r.b.set(p[0], p[1], 140, t * 900, 1) }
        sa(fanG, 'opacity', f); sa(fanG, 'transform', `translate(${x.toFixed(1)} ${(y + 6 * (1 - f)).toFixed(1)}) scale(.9)`)
        const up = t > KT + 0.3 ? 165 : 20
        sa(fanG.querySelector('[data-a="1"]'), 'transform', `rotate(${up} -12 0)`); sa(fanG.querySelector('[data-a="2"]'), 'transform', `rotate(${-up} 12 0)`)
        corn(x + 16, y + 20, seg(t, KT + 0.6, KT + 1.6))
      }
      if (snap) {
        const x = r.target[0] + (r.target[0] > 320 ? 26 : -26), y = LINE - 4, hit = seg(t, KT + 0.05, KT + 0.5)
        put(ph, x, y, (r.target[0] > 320 ? 1 : -1) * 80 * ease(hit), 0.9, 0); ph.face?.('front'); ph.mood(hit > 0 ? 'shock' : 'focus'); ph.pose(30, -30, 150, -40)
        sa(cam2, 'transform', `translate(${(x - 4).toFixed(1)} ${(y - 52 - 30 * Math.sin(Math.PI * hit)).toFixed(1)}) rotate(${Math.round(hit * 400)})`)
        flashB(x, y - 50, seg(t, KT + 0.05, KT + 0.35), 6); ouch(x + (r.target[0] > 320 ? 30 : -30), y - 82, seg(t, KT, KT + 0.6))
      }
      if (post) {
        const k = seg(t, KT - 0.02, KT + 0.8)
        clang(r.target[0], r.target[1] - 10, k); ringL(r.target[0], r.target[1], seg(t, KT, KT + 0.5), 14)
        shakeIt(svg, 8 * seg(t, KT, KT + 0.04) * (1 - seg(t, KT + 0.05, KT + 0.7)), t)
        blue(0.28 * seg(t, KT + 0.05, KT + 0.15) * (1 - seg(t, KT + 0.4, KT + 0.9)))
        if (t > KT + 0.3) { r.sh.face?.('front'); r.sh.mood('shock'); r.sh.pose(3, -3, 150, -150) }
      }
      tt(seg(t, KT + 0.35, KT + 0.75))
    } }
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
    const KT = 2.85, tS = 2.45, dir = R() < 0.5 ? -1 : 1, wobbly = rnd((e.v ?? 5) * 3 + 2)() < 0.5
    // [Sprint 36 F2] The face-off before the kick, as on TV: the taker and the keeper in two panels, eye to eye.
    const vs = el('g', { opacity: 0 }, svg)
    vs.innerHTML = `<rect x="0" y="50" width="320" height="250" fill="${K(e.side).kit}" opacity=".9"/><rect x="320" y="50" width="320" height="250" fill="${keeperKit(other(e.side))}" opacity=".9"/>`
      + `<path d="M300 50 L340 50 L320 300 L280 300 Z" fill="#071733"/><text x="310" y="186" text-anchor="middle" font-family="Barlow Condensed, sans-serif" font-style="italic" font-weight="800" font-size="44" fill="#F5B82E">VS</text>`
    const fT = player(vs, K(e.side).kit, e.no, 2.2, { look: Math.floor(R() * 40) }), fK = player(vs, keeperKit(other(e.side)), 1, 2.2, { gloves: '#E4FF5A', look: Math.floor(R() * 40), shorts: '#111827' })
    fT.mood('focus'); fK.mood('angry')
    const target = e.scored ? [320 + dir * (48 + R() * 12), R() < 0.5 ? 140 : 90] : [320 + dir * (30 + R() * 20), 110 + R() * 30]
    const kAim = e.scored ? (R() < 0.6 ? [640 - target[0], target[1]] : [lerp(320, target[0], 0.7), target[1] + 8]) : target
    const spot = [320, 207], path = [[spot[0], spot[1]], [lerp(spot[0], target[0], 0.5), Math.min(spot[1], target[1]) - 18], target]
    // [Sprint 42 C5] Before it all (1.2 s): the referee blows hard and points straight at the spot, which glows.
    const PRE = 1.2, rf = referee(w, 1), blow = burst(svg, w, '#FFFFFF'), spotRing = el('ellipse', { cx: spot[0], cy: spot[1], rx: 10, ry: 3.5, fill: 'none', stroke: '#F5B82E', 'stroke-width': 2, opacity: 0, filter: ref(svg, 'glow') }, w)
    // ... and in the face-off, a close-up of their eyes, staring each other down.
    const eyes = el('g', { opacity: 0 }, vs)
    const eyePair = (cx, look, brow) => `<g transform="translate(${cx} 176)">${[-38, 38].map((dx) => `<g transform="translate(${dx} 0)"><path d="M-30 0 Q0 -20 30 0 Q0 16 -30 0 Z" fill="#F7F3EA" stroke="#1A1A1A" stroke-width="2.5"/><circle data-iris="1" cx="${look}" cy="0" r="9" fill="#3B2414"/><circle cx="${look}" cy="0" r="4.2" fill="#0A0A0A"/><circle cx="${look + 3}" cy="-3" r="1.8" fill="#fff"/><path d="${brow}" stroke="#1A1A1A" stroke-width="5" stroke-linecap="round" fill="none"/></g>`).join('')}</g>`
    eyes.innerHTML = `<rect x="0" y="134" width="640" height="84" fill="#0A0F1C"/><rect x="0" y="134" width="640" height="2" fill="#F5B82E"/><rect x="0" y="216" width="640" height="2" fill="#F5B82E"/>`
      + eyePair(160, 9, 'M-30 -18 L26 -8') + eyePair(480, -9, 'M-26 -8 L30 -18') + `<path d="M319 140 V212" stroke="#F5B82E" stroke-width="2" stroke-dasharray="4 4"/>`
    const old = (t) => {
      cam(svg, 1.15 + 0.1 * inout(seg(t, 0.3, tS)), 320, 160)
      sa(eyes, 'opacity', SMOOTH ? 0 : seg(t, 0.5, 0.6) * (1 - seg(t, 1.05, 1.15)))
      if (t > 0.5 && t < 1.15) sa(eyes, 'transform', `translate(320 176) scale(${(1 + 0.12 * seg(t, 0.5, 1.15)).toFixed(3)}) translate(-320 -176)`)
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
      // [Sprint 42 H2] One keeper in two puts the taker off with his spaghetti legs, arms waving, on his line.
      if (t < tS && wobbly && t > 1.2) { const q = Math.sin(t * 14); ready(kp, 320 + Math.sin(t * 5) * 14, LINE + 2, t, 1.1); kp.pose(36 * q, -36 * q, 120 + 40 * q, -120 + 40 * q, Math.max(0, q) * 0.5, Math.max(0, -q) * 0.5) }
      else if (t < tS) { ready(kp, 320 + Math.sin(t * 2.4) * 6, LINE + 2, t, 1.3); kp.pose(14, -14, 52 + Math.sin(t * 6) * 8, -52 - Math.sin(t * 6) * 8) }
      else glove = dive(kp, 320, LINE + 2, kAim[0], kAim[1], seg(t, tS + 0.03, KT), seg(t, KT + 0.2, KT + 0.85))
      let p, gr = LINE + 2
      if (t < tS) { p = spot; gr = spot[1] }
      else if (t < KT) { const g = seg(t, tS, KT); p = bez(path, g); gr = lerp(spot[1], LINE + 2, g); drawTrail(trl, path, g, 0.55) }
      else if (e.scored) { const a = t - KT, d = clamp((a - 0.15) / 0.5); p = [target[0], lerp(target[1] - 8 * ease(clamp(a / 0.15)), 146, d * d)]; gr = LINE - 8; sa(trl, 'opacity', 0) }
      else { const a = ease(clamp((t - KT) / 0.8)); p = bez([target, [target[0] - dir * 30, target[1] - 30], [target[0] + dir * 110, 200]], a); gr = lerp(LINE, 200, a); sa(trl, 'opacity', 0) }
      b.set(p[0], p[1], gr, t > tS ? t * 2000 : 0)
      if (e.scored) { G.bulge(target[0], target[1] - 8, 1.9 * seg(t, KT, KT + 0.1) * (1 - seg(t, KT + 0.3, KT + 1.3))); fl(seg(t, KT - 0.01, KT + 0.05) * (1 - seg(t, KT + 0.05, KT + 0.25)) * 0.16); cf(t, t > KT); shakeIt(svg, 6 * seg(t, KT, KT + 0.04) * (1 - seg(t, KT + 0.05, KT + 0.6)), t) }
      tt(seg(t, KT + 0.2, KT + 0.6))
    }
    return { dur: 5.6 + PRE, svg, update(t) {
      old(Math.max(0, t - PRE))
      // The referee: runs in, blows (0.15), points at the spot, then steps away as the taker places the ball.
      const away = ease(seg(t, PRE - 0.25, PRE + 0.4))
      sa(rf.g, 'opacity', 1 - away)
      if (away < 1) {
        const inn = ease(seg(t, 0, 0.3)); rf.face?.('front'); rf.mood(t > 0.12 ? 'angry' : 'focus')
        put(rf, lerp(500, 430, inn) + away * 80, 236)
        const pt = ease(seg(t, 0.25, 0.45)); rf.pose(3, -3, lerp(10, 78, pt), t < 0.3 ? -150 : -12)
        const [hx, hy] = [lerp(500, 430, inn), 236 - 58 * persp(236) - 21 * persp(236)]
        blow(hx + 6, hy + 4, seg(t, 0.1, 0.5))
      }
      sa(spotRing, 'opacity', seg(t, 0.35, 0.5) * (1 - seg(t, PRE, PRE + 0.4)) * (0.6 + 0.4 * Math.sin(t * 18)))
      sa(spotRing, 'transform', `translate(${spot[0]} ${spot[1]}) scale(${(1 + 0.6 * seg(t, 0.35, PRE)).toFixed(2)}) translate(${-spot[0]} ${-spot[1]})`)
    } }
  },
  freekick(e) {
    const R = rnd(e.v ?? (e.no ?? 9) * 53), svg = stage(e.side), w = svg.world, G = goalFrame(svg)
    const kp = keeper(svg, other(e.side), Math.floor(R() * 40))
    const wall = [0, 1, 2, 3].map((i) => player(w, K(other(e.side)).kit, '', 1, { look: Math.floor(R() * 40) }))
    const tk = player(w, K(e.side).kit, e.no, 1, { look: Math.floor(R() * 40) }), b = ball(svg), trl = trail(svg)
    const fl = flash(svg), cf = flashes(svg)
    // [Sprint 38 S3] The referee marks the wall's line with his spray, then steps away.
    const rf = player(w, officialKit(), '', 1, { look: 9, shorts: '#111827', socks: '#111827', trim: '#F5B82E' })
    const foam = el('path', { fill: 'none', stroke: '#F7F9FC', 'stroke-width': 2.6, 'stroke-linecap': 'round', opacity: 0.85 }, w)
    const KT = 2.65, tS = 1.85, side = R() < 0.5 ? -1 : 1, spot = [320 - side * 50, 252], scared = rnd((e.v ?? 5) * 11 + 4)() < 0.5
    const target = e.scored ? [side > 0 ? POSTS[1] - 12 : POSTS[0] + 12, 84 + R() * 8] : e.saved ? [320 + side * (44 + R() * 14), 92 + R() * 14] : [320 + side * 20, 50]
    const path = [spot, [lerp(spot[0], target[0], 0.4) - side * 30, 30], target]
    const tt = title(svg, e.scored ? tr('هدف!') : e.saved ? tr('تصدٍّ!') : tr('فوق العارضة'), e.scored ? undefined : e.saved ? '#2BB673' : '#C9D2E1')
    return { dur: 5.2, svg, update(t) {
      cam(svg, 1.06 + 0.1 * inout(seg(t, 0.2, tS)), 320, 165)
      // The wall, nine metres off, jumps as the kick is taken.
      const jump = 14 * Math.sin(Math.PI * seg(t, tS - 0.05, tS + 0.45))
      const sp = seg(t, 0, 0.55), x0 = spot[0] + side * 20 - 34, x1 = spot[0] + side * 20 + 34
      sa(foam, 'd', `M${x0} 224 L${lerp(x0, x1, sp)} 224`); sa(foam, 'opacity', 0.85 * (1 - seg(t, 4.2, 5)))
      put(rf, t < 0.6 ? lerp(x0, x1, sp) : lerp(x1, spot[0] + side * 140, ease(seg(t, 0.6, 1.4))), t < 0.6 ? 228 : lerp(228, 240, ease(seg(t, 0.6, 1.4))))
      t < 0.6 ? rf.pose(8, -8, 10, -60) : t < 1.4 ? rf.run(t * 9, 0.5) : rf.pose(); rf.mood('focus')
      // [Sprint 42 H2] One wall in two loses its nerve: hands over their faces, and one of them ducks out of it.
      wall.forEach((p, i) => {
        const duck = scared && i === 2 ? -16 * seg(t, tS - 0.35, tS - 0.1) * (1 - seg(t, KT + 0.6, KT + 1.2)) : 0
        put(p, spot[0] + side * 20 + (i - 1.5) * 15, 218, scared && i === 2 ? side * 20 * seg(t, tS - 0.35, tS - 0.1) : 0, 1, jump + duck)
        scared && t > tS - 0.5 && t < KT + 0.8 ? p.pose(4, -4, 150, -150, jump > 1 ? 0.5 : 0, jump > 1 ? 0.5 : 0) : p.pose(4, -4, 4, -4, jump > 1 ? 0.5 : 0, jump > 1 ? 0.5 : 0)
      })
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
  // [Sprint 37 N1] The corner, one of three when it is won (from the scene's seed): a header at the far post, a flick at
  // the near one, or played short to a team-mate who crosses; the taker stands at the flag. A claimed one: the keeper.
  corner(e) {
    const R = rnd(e.v ?? (e.no ?? 9) * 71), svg = stage(e.side), w = svg.world, G = goalFrame(svg)
    const kp = keeper(svg, other(e.side), Math.floor(R() * 40))
    const pack = [0, 1, 2].map((i) => player(w, i % 2 ? K(e.side).kit : K(other(e.side)).kit, '', 1, { look: Math.floor(R() * 40) }))
    const df = player(w, K(other(e.side)).kit, '', 1, { look: Math.floor(R() * 40) }), hd = player(w, K(e.side).kit, e.no, 1, { look: Math.floor(R() * 40) })
    const tk = player(w, K(e.side).kit, '', 1, { look: Math.floor(R() * 40) }), sh2 = player(w, K(e.side).kit, '', 1, { look: Math.floor(R() * 40) })
    const pick = R(), style = e.claim ? (pick < 0.4 ? 'short' : 'far') : pick < 0.4 ? 'far' : pick < 0.7 ? 'near' : 'short'
    const b = ball(svg), trl = trail(svg)
    el('path', { d: 'M598 214 V184', stroke: '#DDE3F0', 'stroke-width': 2 }, w); el('path', { d: 'M599 184 L614 189 L599 194 Z', fill: '#F5B82E' }, w)
    const flag = [596, 214], lay = [548, 232], short = style === 'short', from = short ? lay : flag
    // The cross starts later when it is played short first; the near-post flick meets it before the six-yard line.
    const t0 = short ? 1.0 : 0.6, dt = t0 - 0.6, head = style === 'near' ? [284, 192] : [326, 186]
    const path = [from, [style === 'near' ? 420 : 470, style === 'near' ? 50 : 20], [head[0], head[1] - 44]]
    const tt = title(svg, e.claim ? tr('الحارس يمسكها') : tr('رأسية!'), e.claim ? '#2BB673' : '#C9D2E1')
    return { dur: 4.6, svg, update(t) {
      cam(svg, 1.06, 400, 170)
      // The taker at the flag, and the team-mate who comes short for it.
      put(tk, 606, 218); if (t < 0.62 && t > 0.3) tk.kick(seg(t, 0.3, 0.62)); else tk.pose()
      if (short) { put(sh2, lerp(520, lay[0] + 6, ease(seg(t, 0, 0.6))), lay[1] + 2); t > 0.75 && t < t0 + 0.1 ? sh2.kick(seg(t, 0.75, t0 + 0.08)) : t < 0.6 ? sh2.run(t * 12, 0.6) : sh2.pose() }
      else put(sh2, 470, 236), sh2.idle(t * 3)
      const f = seg(t, t0, t0 + 1.1), jump = 24 * Math.sin(Math.PI * seg(t, 1.35 + dt, 2.05 + dt))
      put(hd, lerp(style === 'near' ? 330 : 346, head[0], ease(seg(t, 0, 1.4 + dt))), head[1], 0, 1, jump); jump > 1 ? hd.pose(10, -10, 70, -70, 0.4, 0.4) : hd.run(t * 12, 0.6)
      put(df, lerp(310, head[0] + 16, ease(seg(t, 0, 1.4 + dt))), head[1] - 4, 0, 1, jump * 0.6); jump > 1 ? df.pose(8, -8, 60, -60, 0.3, 0.3) : df.run(t * 11, 0.5)
      pack.forEach((p, i) => { put(p, 290 + i * 40 + Math.sin(t * 3 + i) * 6, 200 + (i % 2) * 12); p.run(t * 10 + i, 0.4) })
      let glove = null
      if (e.claim) { const c = seg(t, 1.2 + dt, 1.7 + dt); glove = dive(kp, 320, LINE + 2, lerp(320, head[0] + 4, 0.8), lerp(120, 96, c), c, 0) }
      else ready(kp, style === 'near' ? 300 : 322, LINE + 2, t)
      let p, gr
      if (t < 0.6) { p = flag; gr = flag[1] }
      else if (short && t < t0) { const g = ease(seg(t, 0.6, 0.85)); p = [lerp(flag[0], lay[0], g), lerp(flag[1], lay[1], g)]; gr = p[1] }
      else if (t < t0 + 1.1) { const g = ease(f); p = bez(path, g); gr = lerp(from[1], head[1], g); drawTrail(trl, path, g, 0.5) }
      else if (e.claim) { p = glove ?? [head[0], 100]; gr = LINE + 2; sa(trl, 'opacity', 0) }
      else { const g = ease(seg(t, t0 + 1.1, t0 + 1.8)), off = style === 'near' ? 30 : -10; p = bez([[head[0], head[1] - 44], [head[0] + off * 0.6, 60], [head[0] + off, 40]], g); gr = lerp(head[1], LINE - 10, g); sa(trl, 'opacity', 0) }
      b.set(p[0], p[1], gr, t * 1200, e.claim ? 1 : 1 - seg(t, 2.2 + dt, 2.5 + dt))
      tt(seg(t, 2.2 + dt, 2.6 + dt))
    } }
  },
  // [Sprint 35 C2] The card: the referee holds it up over the offender, who protests (arms out, or hands together
  // pleading); a red, and he walks off, head down, past his team-mate.
  // [Sprint 42 D1] A card, as a cartoon (tick.moment.drama, the server's): the slide tackle and the flip, then one of
  // four tellings. tackle: the referee runs in angry, rummages in his pocket and whips the card out; swarm: the
  // offender's team-mates surround him, arms flying, and he backs off blowing his whistle; brawl: the two vanish in a
  // cloud of dust with fists and boots flying out; spit: a close-up of the argument, the spit, the referee's shock,
  // his slow wipe, his face going red. A yellow: the offender acts innocent. A red: a red flash, the referee points
  // to the tunnel, and on his way off the player kicks a water bottle.
  card(e) {
    const svg = stage(e.side), w = svg.world, red = e.type === 'red', R = rnd(e.v ?? (e.no ?? 4) * 13)
    const drama = ['swarm', 'brawl', 'spit'].includes(e.drama) ? e.drama : 'tackle', KT = 3.4, k = 1.4
    const kit = K(e.side).kit, col = red ? '#EF4444' : '#FFD400'
    const vi = player(w, K(other(e.side)).kit, e.victimNo ?? '', k, { look: Math.floor(R() * 40) })
    const mates = drama === 'swarm' ? [0, 1, 2].map(() => player(w, kit, '', k, { look: Math.floor(R() * 40) })) : []
    const bot = red ? bottle(w) : null
    const pl = player(w, kit, e.no, k, { look: Math.floor(R() * 40) }), rf = referee(w, k)
    const fx = { dust: dust(svg), slide: dust(svg, w, 5), ouch: bubbleOf(svg, w, '!!!') }
    const cloud = drama === 'brawl' ? brawlCloud(svg) : null
    const vnP = vein(svg), vnR = vein(svg), swear = bubbleOf(svg, w, '#@!%&!'), swear2 = bubbleOf(svg, w, '?!#@!'), blow = burst(svg, w), kickB = burst(svg, w, '#7FC8FF')
    const hot = el('circle', { r: 13.2, fill: '#B00000', opacity: 0 }, w), steam = dust(svg, w, 6)
    const spit = el('ellipse', { rx: 2.6, ry: 1.8, fill: '#DFF4FF', stroke: '#7FB4D9', 'stroke-width': 0.8, opacity: 0 }, w)
    const notes = el('text', { 'font-size': 16, fill: '#FFFFFF', 'font-family': 'sans-serif', opacity: 0 }, w); notes.textContent = '♪ ♫'
    const glow = el('circle', { r: 70, fill: col, opacity: 0, filter: ref(svg, 'soft') }, w)
    const yel = tint(svg, '#FFD400'), redT = tint(svg, '#FF1E1E'), blue = tint(svg, '#3B82F6')
    const tt = title(svg, red ? tr('طرد!') : tr('إنذار'), col)
    // Where the referee stands to show it, and where the offender stands in front of him.
    const RX = drama === 'swarm' ? 430 : 395, PX = drama === 'spit' ? 318 : 300
    return { dur: 6.6, svg, update(t) {
      blow(0, 0, 0)
      // The tackle (contact at 0.8 s); the victim lies there and rolls, unless a brawl gets him up.
      const up = drama === 'brawl' ? 1.55 : Infinity
      tackle(svg, t, 0.8, pl, vi, k, fx, up, drama === 'spit' || drama === 'swarm' ? 1.7 : Infinity)
      // The camera: a little closer for the card; right up on the faces for the spit.
      const near = drama === 'spit' ? ease(seg(t, 1.8, 2.1)) * (1 - ease(seg(t, KT, KT + 0.4))) : 0
      cam(svg, lerp(1.06 + 0.06 * seg(t, 1.4, KT), 2.3, near), lerp(320, 336, near), lerp(205, 172, near))
      // ---- the referee comes in
      const tIn = drama === 'spit' ? [1.35, 1.8] : drama === 'brawl' ? [2.1, 2.7] : [1.35, 2.2]
      const rIn = ease(seg(t, tIn[0], tIn[1]))
      let rx = lerp(700, drama === 'spit' ? 362 : RX, rIn)
      if (drama === 'swarm') rx += 40 * ease(seg(t, 2.0, 3.0)) - 40
      if (t < tIn[1]) { rf.face?.('side', -1); rf.mood('focus'); rf.run(t * 16, 1) }
      else { rf.face?.(drama === 'spit' && t < 2.62 ? 'side' : 'front', -1); rf.mood(drama === 'spit' && t > 2.62 && t < 3.0 ? 'shock' : 'angry'); rf.pose(3, -3, 12, -12) }
      rf.at(rx, 200, 0, k)
      const [hx, hy] = headOf(rx, 200, k)
      vnR(hx + 12, hy - 14, drama === 'spit' ? 0 : seg(t, tIn[1], tIn[1] + 0.2) * (1 - seg(t, 5.4, 5.6)), t)
      // ---- each drama before the card
      if (drama === 'swarm') {
        // Four of them round him, arms flying; he backs away blowing his whistle again and again.
        const crowd = [pl, ...mates], spots = [[-62, 4], [-34, -10], [44, -8], [70, 6]], from = [[-260, 10], [-320, -20], [-420, 0], [-200, 30]]
        const s1 = ease(seg(t, 1.5, 2.0)), back = ease(seg(t, 3.0, 3.25))
        crowd.forEach((p, i) => {
          if (t < 1.5 && i === 0) return
          const x = rx + lerp(from[i][0], spots[i][0] * (1 + back * 0.9), s1), y = 200 + spots[i][1] + from[i][1] * (1 - s1)
          p.face?.(s1 < 1 ? 'side' : 'front', 1); p.mood('angry'); p.at(x, y, 0, k)
          if (s1 < 1) p.run(t * 15, 1); else if (t < 3.0) p.pose(4, -4, 90 + Math.sin(t * 28 + i) * 55, -90 - Math.sin(t * 31 + i * 2) * 55); else p.pose(3, -3, 14, -14)
        })
        swear(rx - 40, 128, seg(t, 2.0, 2.15) * (1 - seg(t, 2.95, 3.05)), 0.9, Math.sin(t * 40) * 2)
        swear2(rx + 60, 134, seg(t, 2.2, 2.35) * (1 - seg(t, 2.95, 3.05)), 0.85, Math.cos(t * 37) * 2)
        if (t > 2.0 && t < 3.0) { rf.pose(3, -3, 30, -150); blow(hx + 5, hy + 4, ((t - 2.0) % 0.25) / 0.25) }
      } else if (drama === 'brawl') {
        // The victim is up and charges; the two vanish in the dust cloud, fists and boots flying out of it.
        const inCloud = t > 1.85 && t < 2.95, f = seg(t, 1.8, 1.95) * (1 - seg(t, 2.9, 3.15))
        cloud(340, 236, t, f)
        sa(pl.g, 'opacity', inCloud ? 0 : 1); sa(vi.g, 'opacity', inCloud ? 0 : 1)
        swear(340, 150, f, 1, Math.sin(t * 40) * 2)
        shakeIt(svg, inCloud ? 3 : 0, t)
        if (t >= up && t < 1.85) { const c = ease(seg(t, up, 1.85)); vi.face?.('side', -1); vi.mood('angry'); vi.at(lerp(430, 360, c), lerp(268, 200, Math.min(1, c * 2)), lerp(90, 0, Math.min(1, c * 2)), k); vi.run(t * 14, 1) }
        else if (t >= 2.95) { vi.face?.('front'); vi.mood('angry'); vi.at(500, 206, 0, k); vi.pose(4, -4, 40 + Math.sin(t * 9) * 10, -40) }
        if (t > 2.7 && t < 3.2) blow(hx + 5, hy + 4, seg(t, 2.7, 3.1))
        vnP(PX + 12, 200 - 21 * k - 14, t > 2.95 && t < 3.9 ? 1 : 0, t)
      } else if (drama === 'spit') {
        // The close-up: he argues, spits, the referee stares, wipes his face slowly, and goes red with anger.
        if (t > 1.6 && t < KT) {
          pl.face?.('side', 1); pl.mood('angry'); pl.at(PX, 200, 0, k)
          t < 2.5 ? pl.pose(4, -4, -60 + Math.sin(t * 24) * 40, -110 + Math.cos(t * 21) * 40) : pl.pose(4, -4, -20, -30)
        }
        swear(PX - 6, 128, seg(t, 1.9, 2.0) * (1 - seg(t, 2.4, 2.5)), 0.8, Math.sin(t * 40) * 1.5)
        const sp = seg(t, 2.5, 2.62)
        sa(spit, 'opacity', sp > 0 && sp < 1 ? 1 : 0)
        if (sp > 0 && sp < 1) sa(spit, 'transform', `translate(${lerp(PX + 14, hx - 4, sp).toFixed(1)} ${(lerp(175, hy + 2, sp) - Math.sin(Math.PI * sp) * 6).toFixed(1)})`)
        blue(0.3 * seg(t, 2.62, 2.7) * (1 - seg(t, 2.85, 3.0)))
        // The slow wipe of his face, then the volcano: dark red, steam out of the top of his head.
        if (t > 2.95 && t < 3.3) { const wp = Math.sin(Math.PI * seg(t, 2.95, 3.3)); rf.pose(3, -3, 12, lerp(10, 160, wp)) }
        const boil = seg(t, 3.1, 3.35) * (1 - seg(t, 4.4, 4.8))
        sa(hot, 'opacity', (0.6 * boil).toFixed(2)); sa(hot, 'cx', hx); sa(hot, 'cy', hy)
        steam(hx, hy - 16, boil > 0 ? ((t - 3.1) % 0.5) / 0.5 : 0)
      }
      // ---- the card: his hand in the pocket, then whipped up (KT); a red's second yellow first shows yellow.
      const pocket = t > KT - 0.45 && t < KT - 0.1 && drama !== 'spit'
      if (pocket) rf.pose(3, -3, 12, -22 + Math.sin(t * 40) * 7)
      const snap = seg(t, KT - 0.12, KT + 0.05), arm = snap >= 1 ? -172 + Math.sin(Math.min(1, (t - KT - 0.05) * 6) * Math.PI) * 10 : lerp(-22, -180, ease(snap))
      const shown = e.second && t < KT + 0.6 ? '#FFD400' : col
      if (t > KT - 0.12 && t < 5.8) { rf.pose(3, -3, red && t > KT + 0.5 ? lerp(12, 96, ease(seg(t, KT + 0.5, KT + 0.8))) : 12, arm); rf.card(snap > 0.3 ? shown : null) } else rf.card(null)
      sa(glow, 'cx', hx + 20); sa(glow, 'cy', hy - 30); sa(glow, 'opacity', 0.4 * seg(t, KT, KT + 0.3) * (1 - seg(t, 5.4, 5.8)))
      ;(red ? redT : yel)(0.3 * seg(t, KT, KT + 0.06) * (1 - seg(t, KT + 0.15, KT + 0.6)))
      shakeIt(svg, (red ? 4 : 2) * seg(t, KT, KT + 0.03) * (1 - seg(t, KT + 0.05, KT + 0.4)) + (drama === 'brawl' && t > 1.85 && t < 2.95 ? 3 : 0), t)
      // ---- the offender after it
      if (t > KT - 0.6 && drama !== 'swarm' && drama !== 'spit' || (drama === 'spit' && t >= KT)) {
        const off = red ? seg(t, KT + 0.6, 6.4) : 0, x = lerp(PX, -60, off)
        if (off > 0) {
          // Walking off, angry; he kicks the bottle on his way (5.0 s).
          const kick = seg(t, 4.95, 5.2)
          pl.face?.('side', -1); pl.mood('angry'); pl.at(x, 200, 0, k)
          kick > 0 && kick < 1 ? pl.kick(kick) : pl.run(t * 9, 0.45)
          vnP(x - 4, 200 - 21 * k - 14, 1, t)
        } else if (!red) {
          // A yellow: all innocence, hands together, whistling to himself.
          pl.face?.('front'); pl.mood('idle'); pl.at(PX, 200, 0, k); pl.pose(3, -3, -24, 24)
          sa(notes, 'opacity', seg(t, KT + 0.2, KT + 0.4) * (1 - seg(t, 5.8, 6.2))); sa(notes, 'x', PX + 14); sa(notes, 'y', 200 - 21 * k - 18 - ((t * 12) % 8))
        } else { pl.face?.('front'); pl.mood(t > KT ? 'angry' : 'idle'); pl.at(PX, 200, 0, k); pl.pose(4, -4, 60 + Math.sin(t * 8) * 12, -60) }
      }
      if (drama === 'swarm' && red && t > KT + 0.6) {
        const off = seg(t, KT + 0.6, 6.4), x = lerp(rx - 62, -60, off), kick = seg(t, 4.95, 5.2)
        pl.face?.('side', -1); pl.mood('angry'); pl.at(x, 204, 0, k); kick > 0 && kick < 1 ? pl.kick(kick) : pl.run(t * 9, 0.45)
      }
      // The bottle by the touchline: still until the kick, then away, spinning.
      if (bot) {
        const fly = ease(seg(t, 5.08, 5.9)), bx = lerp(150, -40, fly), by = 287 - Math.sin(Math.PI * Math.min(1, fly * 1.3)) * 110 * (1 - fly * 0.3)
        sa(bot, 'transform', `translate(${bx.toFixed(1)} ${by.toFixed(1)}) rotate(${Math.round(fly * 900)}) scale(1.3)`)
        kickB(150, 278, seg(t, 5.08, 5.5))
      }
      tt(seg(t, KT + 0.2, KT + 0.6))
    } }
  },
  // [Sprint 42 D2] A foul as its own scene (tick.moment.drama). tackle: the slide, the flip, the dust, the agony, the
  // referee's whistle and his arm out for the free kick. dive: he runs past the defender untouched, takes off like a
  // diver, rolls five times screaming, opens one eye to see, and the referee gives it all the same.
  foul(e) {
    const svg = stage(e.side), w = svg.world, R = rnd(e.v ?? (e.no ?? 5) * 41), k = 1.4, dive = e.drama === 'dive'
    const vi = player(w, K(other(e.side)).kit, e.victimNo ?? '', k, { look: Math.floor(R() * 40) })
    const pl = player(w, K(e.side).kit, e.no, k, { look: Math.floor(R() * 40) }), rf = referee(w, k)
    const fx = { dust: dust(svg), slide: dust(svg, w, 5), ouch: bubbleOf(svg, w, '!!!') }
    const scream = bubbleOf(svg, w, 'AAAAH!'), huh = bubbleOf(svg, w, '?!', '#0A1F42'), blow = burst(svg, w), roll = dust(svg, w, 6)
    const q = el('text', { 'font-family': 'Barlow Condensed, sans-serif', 'font-weight': 900, 'font-size': 18, fill: '#FFD400', stroke: '#040B1C', 'stroke-width': 3, 'paint-order': 'stroke', opacity: 0 }, w); q.textContent = '?'
    const tt = title(svg, dive ? tr('سقوط مثير!') : tr('خطأ'), '#F2994A')
    return { dur: 5.2, svg, update(t) {
      roll(0, 0, 0)
      let zoom = 0, zx = 320, zy = 205
      if (!dive) {
        tackle(svg, t, 1.5, pl, vi, k, fx)
        if (t > 2.4) { pl.mood('sad'); pl.pose(3, -3, 60, -60) }
      } else {
        // The defender stands his ground (a half-hearted leg out), then throws his arms up: never touched him!
        pl.face?.(t < 1.9 ? 'side' : 'front', -1); pl.mood(t < 1.9 ? 'focus' : 'angry'); pl.at(236, 176, 0, k)
        t < 1.9 ? pl.pose(3, -3 - 18 * Math.sin(Math.PI * seg(t, 1.1, 1.6)), 14, -14) : pl.pose(3, -3, 160 + Math.sin(t * 10) * 8, -160 - Math.sin(t * 10) * 8)
        huh(236, 108, seg(t, 4.15, 4.3), 0.8)
        if (t < 1.25) { vi.face?.('side', 1); vi.mood('focus'); vi.at(lerp(90, 310, seg(t, 0.1, 1.25)), 222, 0, k); vi.run(t * 14, 1) }
        else if (t < 1.6) { const f = seg(t, 1.25, 1.6); vi.face?.('side', 1); vi.mood('joy'); vi.at(lerp(310, 380, f), lerp(222, 266, f) - Math.sin(Math.PI * f) * 56, f * 80, k); vi.pose(10, -10, -165, -165) }
        else if (t < 2.9) { const f = seg(t, 1.6, 2.9); vi.face?.('side', 1); vi.mood('shock'); vi.at(lerp(380, 540, f), 266, 80 + f * 1800, k); vi.pose(30, -30, 90, -90, 0.4, 0.4); roll(lerp(380, 540, f) - 20, 283, ((t - 1.6) % 0.26) / 0.26) }
        else if (t < 4.5) { vi.face?.('front'); vi.mood(t > 3.2 ? 'peek' : 'sad'); vi.at(540, 268, 90, k); vi.pose(10, -10, 40, -40) }
        else { const f = ease(seg(t, 4.5, 4.75)); vi.face?.('front'); vi.mood('joy'); vi.at(540, lerp(268, 200, f), lerp(90, 0, f), k); vi.pose(4, -4, lerp(40, 130, f), -lerp(40, 130, f)) }
        scream(lerp(400, 560, seg(t, 1.6, 2.9)), 210, seg(t, 1.6, 1.75) * (1 - seg(t, 2.85, 3.0)), 0.9, Math.sin(t * 45) * 2)
        // The close-up on his face: one eye opens to see what the referee does.
        zoom = ease(seg(t, 2.95, 3.25)) * (1 - ease(seg(t, 3.95, 4.25))); zx = 570; zy = 262
        sa(q, 'opacity', seg(t, 3.35, 3.45) * (1 - seg(t, 3.9, 4.0))); sa(q, 'x', 586); sa(q, 'y', 252 - ((t * 10) % 4))
      }
      cam(svg, lerp(1.06, 2.6, zoom), lerp(320, zx, zoom), lerp(205, zy, zoom))
      // The referee: in from behind, the whistle, the arm out for the free kick.
      const tIn = dive ? [3.4, 4.0] : [2.2, 2.9], rIn = ease(seg(t, tIn[0], tIn[1])), rx = dive ? lerp(-40, 130, rIn) : lerp(700, 560, rIn)
      if (t < tIn[1]) { rf.face?.('side', dive ? 1 : -1); rf.run(t * 15, 1) } else { rf.face?.('front'); rf.mood('focus'); rf.pose(3, -3, t > tIn[1] + 0.3 ? (dive ? 12 : 92) : 12, t > tIn[1] + 0.3 && dive ? -92 : t < tIn[1] + 0.3 ? -150 : -12) }
      rf.at(rx, dive ? 190 : 196, 0, k)
      const [hx, hy] = headOf(rx, dive ? 190 : 196, k)
      blow(hx + 5, hy + 4, seg(t, tIn[1], tIn[1] + 0.45))
      tt(seg(t, dive ? 4.3 : 2.4, dive ? 4.7 : 2.8))
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
      a.forEach((p, i) => { p.face?.('side', 1); p.mood('angry'); p.at(250 + i * 18 + shove * (i === 1 ? 10 : 4), 200 + i * 14, shove * 6, 1.3); p.pose(10, -10, 80 + shove * 30, 70 - shove * 20) })
      b.forEach((p, i) => { p.face?.('side', -1); p.mood('angry'); p.at(390 - i * 18 - shove * (i === 1 ? 10 : 4), 204 + i * 12, -shove * 6, 1.3); p.pose(10, -10, 80 - shove * 30, 70 + shove * 20) })
      rf.face?.('front'); rf.at(320, 214, 0, 1.35); rf.pose(3, -3, 100 + Math.sin(t * 6) * 10, -100 - Math.sin(t * 6) * 10)
      tt(seg(t, 0.2, 0.6))
    } }
  },
  // [Sprint 38 S1] Offside, as on TV: the pass is played, the attacker is a step beyond the last defender, the assistant
  // on the touchline raises his flag, and the picture freezes with the line drawn across the defence.
  offside(e) {
    const svg = stage(e.side), w = svg.world, R = rnd((e.no || 7) * 37)
    const defs = [0, 1, 2, 3].map(() => player(w, K(other(e.side)).kit, '', 1, { look: Math.floor(R() * 40) }))
    const rn = player(w, K(e.side).kit, e.no, 1, { look: Math.floor(R() * 40) }), ps = player(w, K(e.side).kit, '', 1, { look: Math.floor(R() * 40) })
    const ar = player(w, officialKit(), '', 1, { look: 20, shorts: '#111827', socks: '#111827', trim: '#F5B82E' })
    const fl = el('g', {}, w); fl.innerHTML = '<rect x="-0.8" y="0" width="1.6" height="18" fill="#2B2B2B"/><path d="M0.8 0 H13 V9 H0.8 Z" fill="#F2E205"/><path d="M0.8 0 H6.9 V4.5 H0.8 Z M6.9 4.5 H13 V9 H6.9 Z" fill="#D3122F"/>'
    const b = ball(svg), lineY = 206, runTo = [352, 190]
    // A horizontal line has no height, so a filter would draw nothing: the glow is a wider faint line under it.
    const line = el('g', { opacity: 0 }, w)
    el('line', { x1: -40, y1: lineY, x2: 680, y2: lineY, stroke: 'rgba(239,68,68,.35)', 'stroke-width': 7 }, line)
    el('line', { x1: -40, y1: lineY, x2: 680, y2: lineY, stroke: '#EF4444', 'stroke-width': 2.4, 'stroke-dasharray': '10 7' }, line)
    const fr = el('rect', { width: 640, height: 340, fill: 'rgba(30,70,160,.18)', opacity: 0 }, svg)
    const tt = title(svg, tr('تسلل'), '#EF4444')
    return { dur: 4.2, svg, update(t) {
      // The picture freezes at the pass's arrival (1.5 s) until 2.6 s.
      const T = t > 1.5 && t < 2.6 ? 1.5 : t < 2.6 ? t : t - 1.1
      cam(svg, 1.08, 340, 200)
      defs.forEach((d, i) => { put(d, 170 + i * 90 + Math.sin(T * 2 + i) * 4, lineY + (i % 2) * 3); T < 1.3 ? d.run(T * 8 + i, 0.3) : d.pose(4, -4, i === 1 ? 140 : 10, i === 2 ? -140 : -10) })
      const go = ease(seg(T, 0, 1.4)); put(rn, lerp(330, runTo[0], go), lerp(262, runTo[1], go)); rn.run(T * 12, go < 1 ? 0.8 : 0.2)
      put(ps, 250, 286); T < 0.75 && T > 0.45 ? ps.kick(seg(T, 0.45, 0.75)) : ps.pose()
      // The assistant level with the last defender on the far touchline: the flag goes up as the ball arrives.
      const up = ease(seg(T, 1.2, 1.45))
      put(ar, 572, lineY); ar.face?.('front'); ar.mood('focus'); ar.pose(3, -3, 10, -10 - 160 * up)
      const s2 = persp(lineY)
      sa(fl, 'transform', `translate(${572 + 15 * s2 * up} ${lineY - 58 * s2 - lerp(-30, 52, up) * s2}) scale(${s2})`)
      const k = ease(seg(T, 0.7, 1.5)), p = [lerp(256, runTo[0] - 6, k), lerp(282, runTo[1] + 3, k)]
      b.set(p[0], p[1] - 30 * Math.sin(Math.PI * k) * 0.6, p[1], T * 900, 1)
      sa(line, 'opacity', seg(t, 1.5, 1.7) * (1 - seg(t, 2.6, 2.9))); sa(fr, 'opacity', t > 1.5 && t < 2.6 ? 1 : 0)
      tt(seg(t, 1.6, 2.0))
    } }
  },
  // [Sprint 37 N2] The substitution: the fourth official holds up the lit board (off in red, on in green), the player
  // coming off walks to the line and shakes hands with the one coming on, who runs onto the pitch.
  // [Sprint 42 D4] The sub, as a cartoon: the board flashes green and red, the tired player trudges off with his head
  // down, the substitute bounces on the spot, they slap a high five, and he leaps onto the pitch.
  sub(e) {
    const svg = stage(e.side), w = svg.world, k = K(e.side).kit, R = rnd((e.inNo || 3) * 17 + (e.outNo || 5))
    const fo = referee(w, 1.4)
    const out = player(w, k, e.outNo, 1.4, { look: Math.floor(R() * 40) }), inn = player(w, k, e.inNo, 1.4, { look: Math.floor(R() * 40) })
    const led = (n, c) => `<text y="-2" text-anchor="middle" font-family="Barlow Condensed, sans-serif" font-weight="800" font-size="34" fill="${c}" style="letter-spacing:1px" filter="${ref(svg, 'glow')}">${n ?? ''}</text>`
    const board = el('g', {}, w)
    board.innerHTML = `<rect data-frame="1" x="-58" y="-34" width="116" height="52" rx="5" fill="#05080F" stroke="#3A4256" stroke-width="2"/><g data-o="1" transform="translate(-28 8)">${led(e.outNo, '#FF4D4D')}</g><g data-i="1" transform="translate(28 8)">${led(e.inNo, '#3BFF8A')}</g><path d="M0 -26 V12" stroke="#1B2233" stroke-width="2"/><rect x="-6" y="18" width="12" height="24" rx="3" fill="#1B2233"/>`
    const frameB = board.querySelector('[data-frame]'), oN = board.querySelector('[data-o]'), iN = board.querySelector('[data-i]')
    const slap = burst(svg, w, '#FFD400', 10), sweat = el('path', { d: 'M0 -5 Q4 1 0 3 Q-4 1 0 -5 Z', fill: '#9AD4FF', opacity: 0 }, w)
    const tt = title(svg, tr('تبديل'), '#2BB673')
    return { dur: 5.0, svg, update(t) {
      cam(svg, 1.05, 320, 200)
      // The fourth official, the board up and flashing (out red, in green, its frame blinking both colours).
      const up = ease(seg(t, 0, 0.5)), blink = t < 2.4 ? Math.floor(t * 6) % 2 : 0
      fo.face?.('front'); fo.mood('focus'); fo.at(236, 186, 0, 1.4); fo.pose(3, -3, 150 * up, -150 * up)
      sa(board, 'transform', `translate(236 ${lerp(150, 92, up).toFixed(1)}) scale(${(0.8 + 0.2 * up).toFixed(2)})`)
      sa(frameB, 'stroke', t < 2.4 ? (blink ? '#3BFF8A' : '#FF4D4D') : '#3A4256'); sa(frameB, 'stroke-width', t < 2.4 ? 3.5 : 2)
      sa(oN, 'opacity', t < 2.4 && blink ? 0.35 : 1); sa(iN, 'opacity', t < 2.4 && !blink ? 0.35 : 1)
      // Off: trudges over slowly, head down, a drop of sweat; on: bounces on the spot, can't wait.
      const meet = ease(seg(t, 0.3, 2.4)), five = seg(t, 2.4, 2.75)
      if (t < 2.75) { out.face?.('side', -1); out.mood('sad'); out.at(lerp(660, 400, meet), 214 + Math.sin(t * 5) * 1.5, -4, 1.4); meet < 1 ? out.run(t * 4.5, 0.2) : out.pose(4, -4, 10, lerp(-10, -165, Math.sin(Math.PI * five))) }
      else { out.face?.('front'); out.mood('sad'); out.at(lerp(400, 90, ease(seg(t, 2.75, 5.0))), lerp(214, 236, seg(t, 2.75, 5.0)), 0, 1.4); out.run(t * 4.5, 0.2); out.pose(4, -4, 14, -14) }
      sa(sweat, 'opacity', t < 2.4 ? 0.9 : 0); sa(sweat, 'transform', `translate(${(lerp(660, 400, meet) - 14).toFixed(1)} ${(170 + ((t * 30) % 14)).toFixed(1)})`)
      if (t < 2.75) { inn.face?.('side', 1); inn.mood(t > 2.3 ? 'joy' : 'focus'); inn.at(356, 214 - Math.abs(Math.sin(t * 9)) * 9 * (1 - five), 0, 1.4); t < 2.4 ? inn.pose(4, -4, 20 + Math.sin(t * 9) * 12, -20 - Math.sin(t * 9) * 12) : inn.pose(4, -4, 10, lerp(-10, -165, Math.sin(Math.PI * five))) }
      else { inn.face?.('back'); const go = ease(seg(t, 2.75, 4.6)); inn.mood('joy'); inn.at(lerp(356, 540, go), lerp(214, 150, go) - Math.sin(Math.PI * seg(t, 2.75, 3.2)) * 40, 0, lerp(1.4, 0.9, go)); inn.run(t * 14, 1) }
      // The high five: a slap and a burst where their hands meet.
      slap(378, 174, seg(t, 2.52, 2.85), 6)
      tt(seg(t, 0.4, 0.8))
    } }
  },
  // [Sprint 37 N3] The injury: he lies down, a team-mate waves to the bench, the medical staff run on with the
  // stretcher and carry him off (an injured player leaves the match, the engine's rule).
  // [Sprint 42 D3] As a cartoon: stars and little birds circle his head, and the two medics come on and go off at a
  // comic sprint, legs a blur, with speed lines and a trail of dust.
  injury(e) {
    const svg = stage(e.side), w = svg.world, R = rnd((e.no || 4) * 29)
    const pl = player(w, K(e.side).kit, e.no, 1.3, { look: Math.floor(R() * 40) }), mate = player(w, K(e.side).kit, '', 1.3, { look: Math.floor(R() * 40) })
    const medic = () => player(w, '#1FA463', '+', 1.25, { look: Math.floor(R() * 40), shorts: '#F4F6FA', socks: '#1FA463', trim: '#F4F6FA' })
    const m1 = medic(), m2 = medic()
    const bed = el('g', {}, w)
    bed.innerHTML = '<rect x="-64" y="-5" width="128" height="10" rx="3" fill="#E9EEF6" stroke="#8A97AD" stroke-width="1"/><path d="M-80 0 H80" stroke="#5A667C" stroke-width="3" stroke-linecap="round"/><path d="M-6 -2 H6 M0 -8 V4" stroke="#EF4444" stroke-width="2.4"/>'
    sa(bed, 'transform', 'translate(-200 0)')
    const stars = dizzy(svg), lines = speedLines(svg, w, 7), trailD = dust(svg, w, 6), ouch = bubbleOf(svg, w, '!!!')
    const tt = title(svg, tr('إصابة'), '#EF4444')
    return { dur: 5.6, svg, update(t) {
      cam(svg, 1.06, 320, 210)
      // The stretcher: in at a sprint (1.0 to 1.5), down by him, loaded, then off to the right even faster (3.0 on).
      const inn = ease(seg(t, 1.0, 1.5)), off = inout(seg(t, 3.0, 3.6)), lift = seg(t, 1.9, 2.5)
      const sx = t < 3.0 ? lerp(-140, 300, inn) : lerp(300, 820, off), sy = lerp(lerp(214, 230, seg(t, 1.5, 1.8)), 232, lift)
      sa(bed, 'transform', `translate(${sx.toFixed(1)} ${sy.toFixed(1)})`)
      const sprint = (t > 0.95 && t < 1.5) || (t > 3.0 && t < 3.6), carrying = t < 1.5 || t > 3.0
      for (const [m, dx] of [[m1, -86], [m2, 86]]) {
        m.face?.('side', 1); m.mood(sprint ? 'focus' : 'idle'); m.at(sx + dx, sy - 24 + (carrying ? 0 : 6) - (sprint ? Math.abs(Math.sin(t * 30)) * 3 : 0), sprint ? 8 : 0, 1.25)
        carrying ? m.run(t * (sprint ? 34 : 9) + dx, sprint ? 1 : 0.45) : m.pose(30, -30, 40, -40, 0.4, 0.4)
      }
      lines(sx - 40, sy - 20, 1, 0, sprint ? 1 : 0, t)
      trailD(sx - 110, 282, sprint ? ((t - 0.95) % 0.3) / 0.3 : 0)
      // He lies by the stretcher, dazed (stars round his head), then is on it.
      if (t < 1.9) { pl.face?.('front'); pl.mood('sad'); pl.at(300 + Math.sin(t * 3) * 2, 262, 82, 1.3); pl.pose(14, -6, 60 + Math.sin(t * 6) * 10, -20) }
      else { pl.face?.('side', 1); pl.mood('sad'); pl.at(lerp(300, sx, lift), lerp(262, sy - 12, lift), 90, 1.15); pl.pose(4, -4, 40, -10) }
      const hx = t < 1.9 ? 327 : sx + 24, hy = t < 1.9 ? 246 : sy - 22
      stars(hx, hy, t, t > 0.15 && t < 3.3)
      ouch(hx + 26, hy - 24, seg(t, 0.2, 0.35) * (1 - seg(t, 0.95, 1.1)), 0.8, Math.sin(t * 40) * 1.5)
      // The team-mate waves to the bench, then stands, hands on hips.
      mate.face?.('front'); mate.mood('sad'); mate.at(420, 196, 0, 1.3)
      if (t < 1.3) { const wv = Math.sin(t * 12) * 24; mate.pose(3, -3, 150 + wv, -150 - wv) } else if (t > 3.0 && t < 3.6) { mate.mood('shock'); mate.pose(3, -3, 40, -40) } else mate.despair()
      tt(seg(t, 0.2, 0.6))
    } }
  },
  // [Sprint 42 F1] Cleared off the line: the shot beats the diving keeper and rolls slowly towards the empty net; a
  // defender comes from nowhere in a slide and a cloud of dust and kicks it off the line. A "!" over the striker,
  // and the camera pulls back on his team-mates' despair.
  clearance(e) {
    const R = rnd(e.v ?? (e.no ?? 9) * 53), svg = stage(e.side), w = svg.world, G = goalFrame(svg), atk = K(e.side).kit, dfk = K(other(e.side)).kit
    const kp = keeper(svg, other(e.side), Math.floor(R() * 40))
    const mates = [0, 1].map(() => player(w, atk, '', 1, { look: Math.floor(R() * 40) }))
    const sh = player(w, atk, e.no, 1, { look: Math.floor(R() * 40) }), df = player(w, dfk, e.defNo ?? '', 1, { look: Math.floor(R() * 40) })
    const b = ball(svg), sl = speedLines(svg, w, 7), dst = dust(svg, w, 10), kick = boom(svg, w, 'WHACK!', '#E9EEF6', '#1E3A8A')
    const bang = el('text', { 'text-anchor': 'middle', 'font-family': 'Barlow Condensed, sans-serif', 'font-weight': 900, 'font-size': 34, fill: '#FFD400', stroke: '#040B1C', 'stroke-width': 4, 'paint-order': 'stroke', opacity: 0 }, w); bang.textContent = '!'
    const tt = title(svg, tr('أنقذها من على الخط!'), '#7FB4FF')
    const KT = 2.4, dir = R() < 0.5 ? -1 : 1, from = [320 + dir * 30, 236], line = [320 - dir * 20, LINE + 4], away = [320 + dir * 230, 120]
    return { dur: 4.2, svg, update(t) {
      // The camera on the goal, then pulled back for the despair.
      const back = ease(seg(t, KT + 0.2, KT + 1.2)); cam(svg, lerp(1.22, 0.96, back), 320, lerp(170, 200, back))
      // The striker shoots past the keeper (0.5), then stands there, hands on his head.
      put(sh, from[0] + dir * 6, from[1] + 10)
      if (t < 0.35) sh.run(t * 12, 0.6); else if (t < 0.65) sh.kick(seg(t, 0.35, 0.6)); else if (t < KT) sh.pose(3, -3, 30, -30); else { sh.face?.('front'); sh.mood('shock'); sh.pose(3, -3, 150, -150) }
      const [hx, hy] = [from[0] + dir * 6, from[1] + 10 - 100 * persp(from[1] + 10)]
      sa(bang, 'opacity', seg(t, KT + 0.05, KT + 0.15)); sa(bang, 'x', hx); sa(bang, 'y', hy - Math.abs(Math.sin(t * 9)) * 4)
      // The keeper dives the wrong way and stays down.
      if (t < 0.55) ready(kp, 320, LINE + 2, t, 1.3); else dive(kp, 320, LINE + 2, 320 + dir * 70, 120, seg(t, 0.55, 0.95), seg(t, 1.0, 1.5))
      // The ball: a slow, slow roll towards the line, then kicked away.
      let p, gr
      if (t < 0.6) { p = [from[0] - dir * 4, from[1] + 2]; gr = p[1] }
      else if (t < KT) { const f = 1 - Math.pow(1 - seg(t, 0.6, KT), 1.6); p = [lerp(from[0], line[0], f), lerp(from[1], line[1], f)]; gr = p[1] }
      else { const f = ease(seg(t, KT, KT + 0.8)); p = bez([line, [lerp(line[0], away[0], 0.5), 60], away], f); gr = lerp(line[1], 200, f) }
      b.set(p[0], p[1], gr, t * (t < KT ? 300 : 2200), 1 - seg(t, KT + 0.7, KT + 0.85))
      // The defender: from nowhere, a slide at full speed along the line, dust everywhere.
      const s = seg(t, 1.75, KT), dx = lerp(320 - dir * 260, line[0] - dir * 4, ease(s))
      if (t < 1.75) sa(df.g, 'opacity', 0)
      else {
        sa(df.g, 'opacity', 1); put(df, dx, line[1] + 6, dir * 70, 1, -14 * persp(line[1])); df.pose(6, -6, -30, -120)
        sl(dx, line[1] - 12, dir, 0, s < 1 ? 1 : 1 - seg(t, KT, KT + 0.3), t)
      }
      dst(line[0] - dir * 6, line[1] + 10, seg(t, KT - 0.2, KT + 0.9))
      kick(line[0], line[1] - 14, seg(t, KT - 0.02, KT + 0.6))
      shakeIt(svg, 4 * seg(t, KT, KT + 0.03) * (1 - seg(t, KT + 0.05, KT + 0.4)), t)
      // His team-mates, seen as the camera pulls back: arms up, then heads in hands.
      mates.forEach((m, i) => { put(m, 320 + (i ? 120 : -130) * dir, 300 + i * 12); if (t < KT) m.run(t * 10, 0.5); else { m.face?.('front'); m.mood('sad'); m.pose(3, -3, 150, -150) } })
      tt(seg(t, KT + 0.3, KT + 0.7))
    } }
  },
  // [Sprint 42 F3] The offside trap: the through ball is played, and in one step the whole back line jumps forward
  // together. The striker stops dead, white dashed lines appear on the grass, and the assistant's flag waves in the
  // corner of the screen with a sharp whistle.
  trap(e) {
    const R = rnd((e.no || 9) * 61), svg = stage(e.side), w = svg.world, atk = K(e.side).kit, dfk = K(other(e.side)).kit
    const defs = [214, 282, 358, 426].map(() => player(w, dfk, '', 1, { look: Math.floor(R() * 40) }))
    const st = player(w, atk, e.no, 1, { look: Math.floor(R() * 40) }), pm = player(w, atk, '', 1, { look: Math.floor(R() * 40) }), b = ball(svg)
    const lines = el('g', { stroke: '#FFFFFF', 'stroke-width': 2, 'stroke-dasharray': '10 7', fill: 'none', opacity: 0 }, w)
    lines.innerHTML = `<path data-l="d" d="M110 0 H530"/><path data-l="a" d="M110 0 H530" stroke="#FFD36B"/>`
    const lD = lines.querySelector('[data-l="d"]'), lA = lines.querySelector('[data-l="a"]')
    const skid = dust(svg, w, 6), blow = burst(svg, w)
    // The assistant's flag in the corner of the screen.
    const flag = el('g', { opacity: 0 }, svg)
    flag.innerHTML = '<rect x="520" y="78" width="104" height="104" rx="10" fill="rgba(4,11,28,.8)" stroke="#F5B82E" stroke-width="2"/><path d="M552 170 V96" stroke="#C9D2E1" stroke-width="4" stroke-linecap="round"/><path data-flag="1" fill="#EF4444" stroke="#B91C1C" stroke-width="1"/>'
    const cloth = flag.querySelector('[data-flag]')
    const tt = title(svg, tr('مصيدة التسلل!'), '#EF4444')
    const KT = 1.5
    return { dur: 3.6, svg, update(t) {
      cam(svg, 1.08, 320, 210)
      // The back line: level, then all four step up at once (a little hop) at 0.95 s.
      const up = inout(seg(t, 0.95, 1.25)), hop = Math.sin(Math.PI * seg(t, 0.95, 1.25)) * 8
      const dy = lerp(214, 250, up)
      defs.forEach((d, i) => { const x = [214, 282, 358, 426][i]; put(d, x, dy, 0, 1, hop * persp(dy)); d.face?.('front'); t > 0.95 && t < 1.25 ? d.pose(10, -10, 40, -40, 0.4, 0.4) : t > 1.3 ? (d.mood('joy'), d.pose(3, -3, i % 2 ? 150 : 14, i % 2 ? -14 : -150)) : d.run(t * 9, 0.3) })
      // The striker sets off for the ball, and stops dead, skidding.
      const go = ease(seg(t, 0.8, 1.3)), sy = lerp(222, 196, go)
      put(st, 330, sy); t < 1.3 ? st.run(t * 13, 0.3 + go) : (st.face?.('front'), st.mood('shock'), st.pose(20, -20, 60, -60))
      skid(330, sy + 4, seg(t, 1.3, 1.9))
      // The playmaker plays it through at 0.85 s.
      put(pm, 300, 300); t < 0.7 ? pm.run(t * 10, 0.4) : pm.kick(seg(t, 0.7, 0.95))
      const f = seg(t, 0.85, 1.6), p = [lerp(300, 344, f), lerp(296, 168, ease(f))]
      b.set(p[0], p[1], p[1], t * 900)
      // The lines on the grass: the defence's, and the striker beyond it.
      sa(lines, 'opacity', seg(t, KT, KT + 0.15))
      sa(lD, 'transform', `translate(0 ${dy + 58 * persp(dy) * 0 + 2})`); sa(lA, 'transform', `translate(0 ${sy + 2})`)
      sa(flag, 'opacity', seg(t, KT, KT + 0.1))
      const wv = Math.sin(t * 18) * 6
      sa(cloth, 'd', `M554 98 Q574 ${98 + wv} 596 98 L596 128 Q574 ${128 - wv} 554 128 Z`)
      const [hx, hy] = headOf(320, 186, 1)
      blow(hx + 220, hy - 40, seg(t, KT, KT + 0.4))
      tt(seg(t, KT + 0.25, KT + 0.6))
    } }
  },
  // [Sprint 42 F7] The coach's megaphone: play stops for a moment, he stands on the line and shouts through a huge
  // megaphone; angry letters and symbols fly out and bounce off his players, who shake and sweat. No instruction is
  // shown (the other side's stay private).
  rant(e) {
    const R = rnd(e.v ?? 37), svg = stage(e.side), w = svg.world, kit = K(e.side).kit
    const pls = [0, 1, 2].map(() => player(w, kit, '', 1.1, { look: Math.floor(R() * 40) }))
    const co = player(w, '#1F2937', '', 1.7, { look: Math.floor(R() * 40), shorts: '#1F2937', socks: '#111827', trim: kit })
    const mega = el('g', {}, w)
    mega.innerHTML = '<path d="M0 -6 L34 -22 L34 22 L0 6 Z" fill="#F5B82E" stroke="#8A5A00" stroke-width="2"/><rect x="-8" y="-6" width="10" height="12" rx="2" fill="#333"/><ellipse cx="34" cy="0" rx="5" ry="22" fill="#FFD36B" stroke="#8A5A00" stroke-width="2"/>'
    const SYM = ['#@!', '!!', '%&$', '?!', '@#!', '!!!']
    const sym = SYM.map((x) => { const e2 = el('text', { 'font-family': 'Barlow Condensed, sans-serif', 'font-weight': 900, 'font-size': 22, fill: '#EF4444', stroke: '#fff', 'stroke-width': 3, 'paint-order': 'stroke', opacity: 0 }, w); e2.textContent = x; return e2 })
    const waves = burst(svg, w, '#FFD36B', 6), vn = vein(svg)
    const drops = pls.map(() => el('path', { d: 'M0 -5 Q4 1 0 3 Q-4 1 0 -5 Z', fill: '#9AD4FF', opacity: 0 }, w))
    const tt = title(svg, tr('المدرب غاضب!'), '#EF4444')
    return { dur: 3.6, svg, update(t) {
      cam(svg, 1.04, 320, 200)
      co.face?.('side', 1); co.mood('angry'); co.at(120, 214 + Math.sin(t * 30) * 1.5, 0, 1.7); co.pose(4, -4, 20, -95 + Math.sin(t * 20) * 6)
      const [hx, hy] = headOf(120, 214, 1.7), mx = hx + 22, my = hy + 6
      sa(mega, 'transform', `translate(${mx} ${my}) rotate(${(-6 + Math.sin(t * 20) * 4).toFixed(1)}) scale(${(1 + 0.08 * Math.sin(t * 30)).toFixed(2)})`)
      vn(hx - 8, hy - 18, seg(t, 0.2, 0.3), t)
      waves(mx + 40, my, ((t * 3) % 1), 18)
      // The words fly out of the megaphone to the players and bounce off them.
      sym.forEach((x, i) => {
        const ph = ((t - 0.3) * 1.1 + i / SYM.length) % 1, on = t > 0.3 && t < 3.3, to = [400 + (i % 3) * 70, 150]
        const px = lerp(mx + 40, to[0], ph), py = lerp(my, to[1], ph) - Math.sin(Math.PI * ph) * 40
        sa(x, 'opacity', on ? (ph < 0.85 ? 1 : (1 - ph) * 6.6).toFixed(2) : 0); sa(x, 'x', px.toFixed(1)); sa(x, 'y', py.toFixed(1)); sa(x, 'font-size', (16 + ph * 14).toFixed(1))
      })
      pls.forEach((p, i) => {
        const x = 400 + i * 70, y = 196 + (i % 2) * 14, sh = t > 0.6 ? Math.sin(t * 50 + i) * 2.5 : 0
        p.face?.('front'); p.mood(t > 0.6 ? 'shock' : 'idle'); p.at(x + sh, y, 0, 1.1); p.pose(4, -4, t > 0.6 ? 40 : 10, t > 0.6 ? -40 : -10)
        sa(drops[i], 'opacity', t > 0.7 ? 0.9 : 0); sa(drops[i], 'transform', `translate(${x + 12} ${(y - 30 + ((t * 40 + i * 5) % 14)).toFixed(1)})`)
      })
      tt(seg(t, 0.3, 0.7))
    } }
  },
  // [Sprint 42 F8] A slip in the rain: a downpour, he runs with the ball, loses his feet and slides a long way on his
  // belly like a penguin in a spray of water and mud, the ball stops where he left it, and the other side takes it.
  slip(e) {
    const R = rnd((e.no || 7) * 67), svg = stage(e.side), w = svg.world, k = 1.4
    const pl = player(w, K(e.side).kit, e.no, k, { look: Math.floor(R() * 40) }), df = player(w, K(other(e.side)).kit, e.defNo ?? '', k, { look: Math.floor(R() * 40) }), b = ball(svg)
    const rain = el('g', { stroke: 'rgba(200,220,245,.75)', 'stroke-width': 1.6, 'stroke-linecap': 'round' }, svg)
    const dropsR = Array.from({ length: SMOOTH ? 40 : 110 }, (_, i) => el('line', {}, rain))
    el('rect', { width: 640, height: 340, fill: 'rgba(40,60,90,.22)', 'pointer-events': 'none' }, svg)
    const splash = dust(svg, w, 10, ['#7FB4FF', '#5B3A1E', '#A7D3FF', '#6B4A2A']), splash2 = dust(svg, w, 8, ['#A7D3FF', '#5B3A1E'])
    const tt = title(svg, tr('انزلاق!'), '#7FB4FF')
    const KT = 1.0
    return { dur: 3.6, svg, update(t) {
      cam(svg, 1.06, 320, 210)
      dropsR.forEach((l, i) => { const x = (i * 73) % 680 - 20, y = ((i * 41 + t * 700) % 380) - 30; sa(l, 'x1', x); sa(l, 'y1', y.toFixed(0)); sa(l, 'x2', x - 6); sa(l, 'y2', (y + 18).toFixed(0)) })
      // He runs with it, his feet go (1.0), up in the air, then a long slide on his belly.
      let x, y, r = 0, lift = 0
      if (t < KT) { x = lerp(80, 280, seg(t, 0, KT)); y = 200; pl.face?.('side', 1); pl.mood('focus'); pl.run(t * 14, 1) }
      else if (t < KT + 0.3) { const f = seg(t, KT, KT + 0.3); x = lerp(280, 320, f); y = lerp(200, 262, f) - Math.sin(Math.PI * f) * 40; r = f * 90; pl.mood('shock'); pl.pose(-60, 40, -160, -160) }
      else { const f = 1 - Math.pow(1 - seg(t, KT + 0.3, 2.6), 2); x = lerp(320, 560, f); y = 262; r = 90; pl.mood('shock'); pl.pose(4, -4, -170, -170) }
      pl.at(x, y, r, k)
      splash(x + 30, 282, t > KT + 0.3 && t < 2.7 ? ((t - KT) % 0.32) / 0.32 : 0)
      splash2(300, 282, seg(t, KT + 0.25, KT + 0.9))
      // The ball stops where he left it; the defender comes in and takes it away.
      let bx = t < KT ? x + 14 : lerp(294, 300, seg(t, KT, KT + 0.4)), by = 284 - 0
      const take = seg(t, 1.9, 2.4), dx = t < 1.9 ? lerp(-60, 260, seg(t, 1.2, 1.9)) : lerp(290, -60, seg(t, 2.4, 3.6))
      df.face?.('side', t < 2.4 ? 1 : -1); df.mood(t > 2.0 ? 'joy' : 'focus'); df.at(dx, 200, 0, k); df.run(t * 13, t > 1.2 ? 1 : 0)
      if (t > 2.4) bx = dx - 16
      b.set(bx, by, by, t < KT ? t * 900 : t > 2.4 ? t * 900 : 0)
      tt(seg(t, KT + 0.4, KT + 0.8))
    } }
  },
  // [Sprint 42 F6] The coach's meltdown after a chance blasted over: hands on his head, he pulls his hair, kicks the
  // bench away, throws his jacket down, fire coming out of his eyes.
  meltdown(e) {
    const R = rnd(e.v ?? 71), svg = stage(e.side), w = svg.world, kit = K(e.side).kit
    el('rect', { x: -80, y: 236, width: 800, height: 110, fill: 'rgba(4,11,28,.55)' }, w)
    const bench = el('g', {}, w)
    bench.innerHTML = '<rect x="-60" y="-24" width="120" height="10" rx="3" fill="#0B1626" stroke="#4A5A78"/><rect x="-60" y="-14" width="120" height="6" fill="#16243A"/><rect x="-54" y="-8" width="6" height="22" fill="#4A5A78"/><rect x="48" y="-8" width="6" height="22" fill="#4A5A78"/>'
    const co = player(w, '#1F2937', '', 1.8, { look: Math.floor(R() * 40), shorts: '#1F2937', socks: '#111827', trim: kit })
    const jacket = el('path', { d: 'M-16 -14 L16 -14 L20 18 L-20 18 Z', fill: '#1F2937', stroke: kit, 'stroke-width': 2, opacity: 0 }, w)
    const fireL = el('g', { opacity: 0 }, w)
    fireL.innerHTML = '<path data-f="1" stroke="#FF7A1A" stroke-width="4" stroke-linecap="round"/><path data-f="1" stroke="#FFD400" stroke-width="2" stroke-linecap="round"/><path data-f="2" stroke="#FF7A1A" stroke-width="4" stroke-linecap="round"/><path data-f="2" stroke="#FFD400" stroke-width="2" stroke-linecap="round"/>'
    const hairs = el('g', { stroke: '#2A1A10', 'stroke-width': 1.6, opacity: 0 }, w)
    hairs.innerHTML = Array.from({ length: 6 }, (_, i) => `<path d="M${-10 + i * 4} 0 q2 -6 0 -10"/>`).join('')
    const redT = tint(svg, '#FF1E1E'), boomB = boom(svg, w, 'BANG!'), vn = vein(svg)
    const tt = title(svg, tr('المدرب ينفجر!'), '#EF4444')
    return { dur: 2.8, svg, update(t) {
      cam(svg, 1.1, 320, 190)
      redT(0.18 * seg(t, 0.05, 0.15) * (1 - seg(t, 0.6, 1.2)))
      const kick = seg(t, 0.9, 1.15), thr = seg(t, 1.5, 1.8)
      co.face?.('front'); co.mood('angry'); co.at(300, 190, 0, 1.8)
      if (t < 0.9) { const p = Math.sin(t * 28) * 10; co.pose(4, -4, 150 + p, -150 - p) }
      else if (t < 1.3) co.kick(kick)
      else if (t < 1.9) co.pose(4, -4, lerp(150, 60, thr), -lerp(150, 60, thr))
      else { const p = Math.sin(t * 20) * 8; co.pose(6, -6, 150 + p, -150 - p) }
      const [hx, hy] = headOf(300, 190, 1.8)
      vn(hx + 16, hy - 20, 1, t)
      // Tufts of hair pulled out, flying.
      sa(hairs, 'opacity', t > 0.3 && t < 1.0 ? 1 : 0); sa(hairs, 'transform', `translate(${hx} ${(hy - 20 - (t - 0.3) * 40).toFixed(1)}) rotate(${Math.round(t * 200)})`)
      // Fire from his eyes.
      const fl = Math.sin(t * 40) * 3, on = t > 0.25
      sa(fireL, 'opacity', on ? 1 : 0)
      for (const [i, e2] of [...fireL.children].entries()) { const sx = hx + (i < 2 ? -6 : 6), sy = hy + 0, d = i < 2 ? -1 : 1; sa(e2, 'd', `M${sx} ${sy} L${sx + d * (26 + fl)} ${sy - 8 + fl}`) }
      // The bench kicked away, spinning.
      const bf = ease(seg(t, 1.05, 1.9)); sa(bench, 'transform', `translate(${lerp(420, 700, bf).toFixed(1)} ${(250 - Math.sin(Math.PI * bf) * 90).toFixed(1)}) rotate(${Math.round(bf * 540)})`)
      boomB(430, 228, seg(t, 1.05, 1.6))
      // The jacket thrown to the ground.
      const jf = ease(seg(t, 1.7, 2.1)); sa(jacket, 'opacity', t > 1.7 ? 1 : 0); sa(jacket, 'transform', `translate(${lerp(300, 230, jf).toFixed(1)} ${lerp(150, 280, jf).toFixed(1)}) rotate(${Math.round(jf * 200)}) scale(${lerp(1.4, 1, jf).toFixed(2)} ${lerp(1.4, 0.35, jf).toFixed(2)})`)
      tt(seg(t, 0.15, 0.5))
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
    const g = el('g', {}, w)
    const skins = ['#C99A78', '#8D5A3B', '#E2B48F', '#6B4027', '#B07B57', '#D9A982']
    const n = e.count ?? 90
    // [Sprint 42 I1] The fans in blocks (a row by an eighth of the stand) that jump together, each block on its own
    // beat: about 48 moves a frame instead of three for every fan (the cutaway was the slowest drawing of all).
    // Made in order, back row first, so the front rows stand in front.
    const blocks = new Map()
    for (let row = 0; row < 6; row++) for (let col = 0; col < 8; col++) blocks.set(row * 8 + col, { g: el('g', {}, g), x: col * 88 + 14, row, ph: R() * 6.3 })
    for (let i = 0; i < n; i++) {
      const row = i % 6, x = ((i * 53 + row * 29) % 700) - 30, y = 120 + row * 38, s = 0.7 + row * 0.12, col = Math.max(0, Math.min(7, Math.floor((x + 30) / 88)))
      const key = row * 8 + col
      const bl = blocks.get(key), shirt = R() < 0.7 ? k.kit : k.trim ?? '#fff', arms = i % 2 ? 'up' : 'v'
      const f = el('g', { transform: `translate(${x} ${y}) scale(${s})` }, bl.g)
      f.innerHTML = `<rect x="-9" y="0" width="18" height="26" rx="6" fill="${shirt}"/><circle cy="-8" r="8" fill="${skins[i % skins.length]}"/>`
        + (arms === 'up' ? `<rect x="-13" y="-22" width="5" height="18" rx="2.5" fill="${shirt}" transform="rotate(-12 -10 -4)"/><rect x="8" y="-22" width="5" height="18" rx="2.5" fill="${shirt}" transform="rotate(12 10 -4)"/>` : `<rect x="-16" y="-14" width="5" height="18" rx="2.5" fill="${shirt}" transform="rotate(-40 -9 2)"/><rect x="11" y="-14" width="5" height="18" rx="2.5" fill="${shirt}" transform="rotate(40 9 2)"/>`)
        + (i % 4 === 0 ? `<rect x="-16" y="-34" width="32" height="7" rx="2" fill="${k.trim ?? '#F5B82E'}"/>` : '')
    }
    const fans = [...blocks.values()]
    const flags = [140, 470].map((x) => { const p = el('path', { fill: k.kit, stroke: k.trim ?? '#fff', 'stroke-width': 3, opacity: 0.95 }, w); return { p, x } })
    const flares = (e.flares ? [90, 330, 560] : []).map((x) => el('circle', { cx: x, cy: 150, r: 26, fill: '#FF8A3D', opacity: 0, filter: ref(svg, 'soft') }, w))
    const paper = (e.flares ? Array.from({ length: 40 }, (_, i) => el('rect', { width: 5, height: 3, fill: ['#fff', k.kit, '#F5B82E'][i % 3], opacity: 0.9 }, w)) : [])
    // [Sprint 42 H2] One crowd in two does a Mexican wave; and the club's mascot dances in front of them.
    const wave = rnd((e.v ?? 7) * 5 + 3)() < 0.5
    const masc = el('g', {}, w)
    masc.innerHTML = `<ellipse cx="0" cy="62" rx="34" ry="7" fill="rgba(0,0,0,.4)"/><ellipse cx="0" cy="20" rx="30" ry="38" fill="${k.kit}" stroke="${k.trim ?? '#fff'}" stroke-width="3"/><circle cy="-30" r="26" fill="${k.trim ?? '#F5B82E'}" stroke="${k.kit}" stroke-width="3"/><circle cx="-9" cy="-34" r="8" fill="#fff"/><circle cx="9" cy="-34" r="8" fill="#fff"/><circle cx="-8" cy="-33" r="3.5" fill="#111"/><circle cx="10" cy="-33" r="3.5" fill="#111"/><path d="M-12 -18 Q0 -6 12 -18" fill="#5A1A14"/><path d="M-22 -50 L-14 -62 L-8 -50 M8 -50 L14 -62 L22 -50" fill="${k.kit}"/><rect data-m="1" x="-44" y="0" width="14" height="40" rx="7" fill="${k.kit}"/><rect data-m="2" x="30" y="0" width="14" height="40" rx="7" fill="${k.kit}"/>`
    const mArm = [masc.querySelector('[data-m="1"]'), masc.querySelector('[data-m="2"]')]
    const tt = title(svg, wave ? tr('موجة في المدرجات') : tr('فرحة الجماهير'))
    return { dur: 2.6, svg, update(t) {
      cam(svg, 1.25 - 0.08 * ease(seg(t, 0, 2.6)), 320, 200)
      const mx = 320 + Math.sin(t * 2) * 120, md = Math.sin(t * 10)
      sa(masc, 'transform', `translate(${mx.toFixed(1)} ${(250 - Math.abs(md) * 12).toFixed(1)}) rotate(${(md * 8).toFixed(1)})`)
      sa(mArm[0], 'transform', `rotate(${(150 + md * 30).toFixed(0)} -37 4)`); sa(mArm[1], 'transform', `rotate(${(-150 + md * 30).toFixed(0)} 37 4)`)
      for (const q of fans) {
        const j = wave ? Math.max(0, Math.sin(t * 4 - q.x / 70)) ** 3 * 22 : Math.abs(Math.sin(t * 7 + q.ph)) * 10
        sa(q.g, 'transform', `translate(0 ${(-j).toFixed(1)})`)
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
  // [Sprint 38 S2] Stoppage time: the fourth official holds up the lit board with the minutes added.
  board(e) {
    const svg = stage('home'), w = svg.world
    const fo = player(w, officialKit(), '', 1.5, { look: 9, shorts: '#111827', socks: '#111827', trim: '#F5B82E' })
    const bd = el('g', {}, w)
    bd.innerHTML = `<rect x="-62" y="-40" width="124" height="64" rx="6" fill="#05080F" stroke="#3A4256" stroke-width="2"/><text y="12" text-anchor="middle" font-family="Barlow Condensed, sans-serif" font-weight="800" font-size="46" fill="#3BFF8A" filter="${ref(svg, 'glow')}">+${e.plus ?? ''}</text><rect x="-6" y="24" width="12" height="22" rx="3" fill="#1B2233"/>`
    const tt = title(svg, tr('الوقت بدل الضائع'), '#2BB673')
    return { dur: 3, svg, update(t) {
      cam(svg, 1.05, 320, 200)
      const up = ease(seg(t, 0.05, 0.5))
      fo.face?.('front'); fo.mood('focus'); fo.at(320, 196, 0, 1.5); fo.pose(3, -3, 150 * up, -150 * up)
      sa(bd, 'transform', `translate(320 ${lerp(170, 96, up)}) scale(${0.85 + 0.15 * up + 0.02 * Math.sin(t * 8)})`)
      tt(seg(t, 0.4, 0.8))
    } }
  },
}

// ---------------------------------------------------------------- [Sprint 42 J1] the variety layer
// The owner's (2026-11-03): "500 different clips, so no match feels like the last". Every scene above already has its
// own variants (finishes, saves, celebrations, the server's dramas and gags); on top of them each scene now draws, from
// its own seed, one of 5 cameras, one of 4 headlines and one of 6 accents at its key moment: 120 looks for each of
// them. The same on every screen (the seed is the minute's), drawing only.
const CAMS = 5, TITLES = 4, ACCENTS = 6
export const VARIETY = { cams: CAMS, titles: TITLES, accents: ACCENTS }
const WORDS = {
  goal: ['GOAL!!', 'BOOM!', 'WOW!'], save: ['DENIED!', 'NO WAY!', 'WOW!'], miss: ['OHH!', 'SO CLOSE!', 'NOO!'], blocked: ['BLOCKED!', 'THUD!'],
  penalty: ['ICE COLD!', 'BOOM!', 'OH!'], freekick: ['WHOOSH!', 'CURL!'], card: ['OUCH!', 'TROUBLE!', 'OH NO!'], foul: ['OUCH!', 'CRUNCH!'],
  injury: ['OUCH!', 'OOF!'], sub: ['FRESH!', 'IN!'], var: ['CHECK!', 'HOLD ON!'], clearance: ['SAVED!', 'PHEW!'], trap: ['STEP UP!', 'CAUGHT!'],
  slip: ['SPLASH!', 'OOPS!'], rant: ['LISTEN!'], meltdown: ['ARGH!'], crowd: ['YEAH!', 'OLE!'], brawl: ['HEY!'],
}
const hashOf = (str) => { let h = 2166136261; for (let i = 0; i < str.length; i++) { h ^= str.charCodeAt(i); h = Math.imul(h, 16777619) } return (h >>> 0) % 1000000 }
function vary(name, make) {
  return (e) => {
    const R = rnd(((e.v ?? hashOf(name + JSON.stringify(e))) * 13 + 7) >>> 0)
    VARIANT.cam = Math.floor(R() * CAMS); VARIANT.title = Math.floor(R() * TITLES); VARIANT.accent = Math.floor(R() * ACCENTS)
    const word = (WORDS[name] ?? ['WOW!'])[Math.floor(R() * (WORDS[name]?.length ?? 1))], cam = VARIANT.cam, acc = SMOOTH ? 0 : VARIANT.accent
    const sc = make(e)
    VARIANT.title = 0
    const svg = sc.svg, w = svg.world, KT = SCENE_TIME[name]?.[1] ?? 1, D = sc.dur ?? SCENE_TIME[name]?.[0] ?? 4
    // The camera: a frame round the world the scene moves itself, so the two add up.
    let rig = null
    if (w && cam) { rig = document.createElementNS(NS, 'g'); w.parentNode.insertBefore(rig, w); rig.appendChild(w) }
    // The accent, over everything, at the key moment.
    const fx = el('g', { opacity: 0, 'pointer-events': 'none' }, svg)
    if (acc === 1) fx.innerHTML = Array.from({ length: 14 }, (_, i) => `<polygon points="0,-6 1.6,-1.6 6,0 1.6,1.6 0,6 -1.6,1.6 -6,0 -1.6,-1.6" fill="${i % 2 ? '#FFD36B' : '#FFFFFF'}" transform="translate(${60 + ((i * 97) % 520)} ${40 + ((i * 53) % 240)})"/>`).join('')
    if (acc === 2) fx.innerHTML = Array.from({ length: 28 }, (_, i) => { const a = (i / 28) * Math.PI * 2, r0 = 150 + (i % 3) * 20; return `<path d="M${(320 + Math.cos(a) * r0).toFixed(0)} ${(170 + Math.sin(a) * r0 * 0.6).toFixed(0)} L${(320 + Math.cos(a) * 420).toFixed(0)} ${(170 + Math.sin(a) * 260).toFixed(0)}" stroke="#fff" stroke-width="${1.5 + (i % 3)}" opacity=".7"/>` }).join('')
    if (acc === 3) fx.innerHTML = `<g transform="translate(520 280) rotate(-8)"><rect x="-74" y="-24" width="148" height="44" rx="8" fill="#FFD400" stroke="#071733" stroke-width="4"/><text y="9" text-anchor="middle" font-family="Barlow Condensed, sans-serif" font-weight="900" font-style="italic" font-size="26" fill="#071733">${word}</text></g>`
    if (acc === 4) fx.innerHTML = '<rect width="640" height="340" fill="#FFFFFF"/>'
    if (acc === 5) fx.innerHTML = `<radialGradient id="vg${svg.dataset.id}" cx=".5" cy=".5" r=".7"><stop offset=".55" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity=".4"/></radialGradient><rect width="640" height="340" fill="url(#vg${svg.dataset.id})"/>`
    const update = sc.update
    sc.update = (t) => {
      update(t)
      if (rig) {
        const k = t / D, p = seg(t, KT - 0.05, KT + 0.12) * (1 - seg(t, KT + 0.3, KT + 1.1))
        const tr = cam === 1 ? `translate(320 170) scale(${(1 + 0.07 * inout(k)).toFixed(3)}) translate(-320 -170)`
          : cam === 2 ? `translate(320 170) rotate(${(-3 + 1.5 * Math.sin(t * 0.8)).toFixed(2)}) scale(1.08) translate(-320 -170)`
          : cam === 3 ? `translate(${(Math.sin(t * 0.9) * 14).toFixed(1)} ${(Math.cos(t * 0.7) * 4).toFixed(1)}) translate(320 170) scale(1.05) translate(-320 -170)`
          : `translate(320 170) scale(${(1 + 0.13 * p).toFixed(3)}) translate(-320 -170)`
        sa(rig, 'transform', tr)
      }
      if (acc) {
        const on = acc === 4 ? 0.55 * seg(t, KT - 0.02, KT + 0.04) * (1 - seg(t, KT + 0.06, KT + 0.3))
          : acc === 5 ? seg(t, KT - 0.1, KT + 0.1) * (1 - seg(t, KT + 0.8, KT + 1.4))
          : seg(t, KT, KT + 0.12) * (1 - seg(t, KT + (acc === 3 ? 1.2 : 0.5), KT + (acc === 3 ? 1.5 : 0.9)))
        sa(fx, 'opacity', on.toFixed(2))
        if (acc === 1 && on > 0) [...fx.children].forEach((c, i) => sa(c, 'opacity', (0.5 + 0.5 * Math.sin(t * 20 + i)).toFixed(2)))
        if (acc === 3 && on > 0) sa(fx.firstElementChild, 'transform', `translate(520 280) rotate(-8) scale(${(lerp(1.8, 1, ease(seg(t, KT, KT + 0.18)))).toFixed(2)})`)
      }
    }
    return sc
  }
}
for (const k of Object.keys(SCENES)) SCENES[k] = vary(k, SCENES[k])
