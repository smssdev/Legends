// @ts-nocheck
// [Sprint 57 W4] The art's kit, shared by every part: the match's looks (kits, smooth, rich, light, rain), the colours,
// the escaping, the crests and icons, and the motion helpers. Drawing only.

export const NS = 'http://www.w3.org/2000/svg'
// The two kits of the match: { kit, ink, trim, name } per side, set by the feed.
export let KITS = { home: { kit: '#E8ECF4', ink: '#0A1F42', trim: '#F5B82E', name: '' }, away: { kit: '#D3122F', ink: '#FFFFFF', trim: '#F6C343', name: '' } }
export function setKits(k) { KITS = k }
// The smooth mode [X30]: no glow filter (redrawn every frame on the phone's processor for every line and trail) and a third of the crowd.
export let SMOOTH = false
export function setSmooth(v) { SMOOTH = !!v }
// [Sprint 42 I1] Only the full tier draws the blurred glows: an SVG blur makes every repaint of the picture costly.
export let RICH = true
export function setRich(v) { RICH = !!v }
// [Sprint 42 J1] The owner's (2026-11-03): no two matches alike. Each scene gets its looks from its own seed (a camera,
// a headline, an accent at its key moment, VARIANT), and each match its light (LIGHT: night, dusk or day).
export const VARIANT = { cam: 0, title: 0, accent: 0 }
export let LIGHT = 'night'
export function setLight(v) { LIGHT = ['night', 'dusk', 'day'].includes(v) ? v : 'night' }
// [Sprint 36 F3] The match's rain (the live pitch's, from its seed) falls in the scenes too.
export let RAIN = false
export function setRain(v) { RAIN = !!v }
export const K = (s) => KITS[s] ?? KITS.home
export const other = (s) => (s === 'home' ? 'away' : 'home')
export const lum = (hex) => { const n = parseInt(String(hex).slice(1), 16); return 0.3 * (n >> 16) + 0.59 * ((n >> 8) & 255) + 0.11 * (n & 255) }
export const shade = (hex, p) => { const n = parseInt(hex.slice(1), 16), f = (v) => Math.max(0, Math.min(255, v + p)); return '#' + [f(n >> 16), f((n >> 8) & 255), f(n & 255)].map((v) => v.toString(16).padStart(2, '0')).join('') }
// [Sprint 37 N5] Between two colours (f 0..1): the stands take a little of the home club's colour.
export const mix = (a, b, f) => { const x = parseInt(String(a).slice(1), 16), y = parseInt(String(b).slice(1), 16), c = (sh) => Math.round(((x >> sh) & 255) * (1 - f) + ((y >> sh) & 255) * f); return '#' + [c(16), c(8), c(0)].map((v) => v.toString(16).padStart(2, '0')).join('') }
// A keeper's kit that stands apart from both teams.
// [Sprint 31 D3] Chosen from a few, the first that stands apart from both teams' shirts (and from the other keeper's).
export const rgbOf = (hex) => { const n = parseInt(String(hex).slice(1, 7), 16); return [n >> 16, (n >> 8) & 255, n & 255] }
export const apart = (a, b) => { const x = rgbOf(a), y = rgbOf(b); return Math.abs(x[0] - y[0]) + Math.abs(x[1] - y[1]) + Math.abs(x[2] - y[2]) > 150 }
export const pickKit = (choices, avoid) => choices.find((c) => avoid.every((a) => !a || apart(c, a))) ?? choices[0]
export const keeperKit = (side) => {
  const shirts = [KITS.home?.kit, KITS.away?.kit]
  const home = pickKit(['#2BB673', '#7B3FE4', '#F2994A', '#14B8C4'], shirts)
  return side === 'home' ? home : pickKit(['#F2994A', '#14B8C4', '#7B3FE4', '#2BB673'], [...shirts, home])
}
/** [Sprint 31 D1, D3] The officials' shirt: black, or another colour when a team plays in a dark kit. */
export const officialKit = () => pickKit(['#15171C', '#F2E205', '#E85D9A', '#7B3FE4'], [KITS.home?.kit, KITS.away?.kit, keeperKit('home'), keeperKit('away')])

// Writes an attribute only when it changes [X30]: every write, even of the same value, makes the browser lay the
// scene out again, and a scene sets hundreds of them a frame (most of them unchanged, like the flashes at rest).
export const sa = (e, k, v) => { const key = '_' + k; if (e[key] === v) return; e[key] = v; e.setAttribute(k, v) }

export let uid = 0
/** A fresh id for a gradient or a pattern in a scene. */
export const nextId = () => ++uid
// [2026-11-09] Text that goes into markup (v-html): a club's code, colour or logo address can never become HTML.
export const ENTITY = { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }
export const esc = (v) => String(v ?? '').replace(/[&<>"']/g, (c) => ENTITY[c])

export const crest = ([c1, c2, t]) => {
  const id = 'cr' + nextId()
  c1 = esc(c1)
  c2 = esc(c2)
  t = esc(t)
  return `<svg viewBox="0 0 64 72"><defs><linearGradient id="${id}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${c1}"/><stop offset="1" stop-color="${shade(c1, -50)}"/></linearGradient></defs><path d="M32 2 L60 10 V36 C60 54 47 65 32 70 C17 65 4 54 4 36 V10 Z" fill="url(#${id})" stroke="${c2}" stroke-width="3"/><path d="M32 9 L53 15 V35 C53 49 43 58 32 62" fill="none" stroke="rgba(255,255,255,.35)" stroke-width="2"/><text x="32" y="42" text-anchor="middle" font-family="Barlow Condensed, Tajawal, sans-serif" font-weight="800" font-size="${t.length > 2 ? 17 : 20}" fill="${lum(c1) > 150 ? '#0A1F42' : '#fff'}">${t}</text></svg>`
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
export const el = (tag, a, p) => { const e = document.createElementNS(NS, tag); for (const k in a) sa(e, k, a[k]); p && p.appendChild(e); return e }
export const clamp = (v) => Math.max(0, Math.min(1, v))
export const seg = (t, a, b) => clamp((t - a) / (b - a))
export const ease = (f) => 1 - Math.pow(1 - f, 3)
export const inout = (f) => (f < 0.5 ? 4 * f * f * f : 1 - Math.pow(-2 * f + 2, 3) / 2)
export const lerp = (a, b, f) => a + (b - a) * f
export const bez = (p, f) => { const u = 1 - f; return [u * u * p[0][0] + 2 * u * f * p[1][0] + f * f * p[2][0], u * u * p[0][1] + 2 * u * f * p[1][1] + f * f * p[2][1]] }
// The same scene for the same minute: every choice (the corner aimed at, the keeper's dive) comes from the minute's seed.
export function rnd(seed) {
  let a = (seed >>> 0) || 7
  return () => { a = (a + 0x6d2b79f5) >>> 0; let t = a; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296 }
}

// The camera looks at the goal from behind the attack. The goal line is at y 150 (posts at
// x 246 and 394, bar at y 72); a player standing at ground y is drawn at scale persp(y).
