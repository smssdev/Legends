// @ts-nocheck
// The match feed's art (docs/MATCH_VIEW.md 4.6): our own flat cartoon characters,
// crests, card icons and the short animated SVG scenes for each kind of moment.
// Drawing only: which scene plays, and with whom, comes from story.ts.

const NS = 'http://www.w3.org/2000/svg'
// The two kits of the match: { kit, ink, trim, name } per side, set by the feed.
let KITS = { home: { kit: '#F2F2F2', ink: '#0A1F42', trim: '#F5B82E', name: '' }, away: { kit: '#C8102E', ink: '#FFFFFF', trim: '#F6C343', name: '' } }
export function setKits(k) { KITS = k }
const K = (s) => KITS[s] ?? KITS.home
function shade(hex, p) { const n = parseInt(hex.slice(1), 16); const f = (v) => Math.max(0, Math.min(255, v + p)); return '#' + [f(n >> 16), f((n >> 8) & 255), f(n & 255)].map((v) => v.toString(16).padStart(2, '0')).join('') }
function lum(hex) { const n = parseInt(hex.slice(1), 16); return 0.3 * (n >> 16) + 0.59 * ((n >> 8) & 255) + 0.11 * (n & 255) }
export const crest = ([c1, c2, t]) => `<svg viewBox="0 0 60 70"><defs><linearGradient id="cg${t}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${c1}"/><stop offset="1" stop-color="${shade(c1, -30)}"/></linearGradient></defs><path d="M30 3 L55 11 V34 C55 52 43 62 30 67 C17 62 5 52 5 34 V11 Z" fill="url(#cg${t})" stroke="${c2}" stroke-width="4"/><path d="M30 11 L47 16 V33 C47 46 39 54 30 58" fill="none" stroke="rgba(255,255,255,.25)" stroke-width="3"/><text x="30" y="40" text-anchor="middle" font-family="Alexandria" font-weight="900" font-size="${t.length > 2 ? 13 : 16}" fill="${lum(c1) > 150 ? '#0A1F42' : '#fff'}">${t}</text></svg>`

// ---------------------------------------------------------------- characters (our own, flat cartoon)
export function person(o) {
  const s = o.skin, sd = shade(s, -28), hair = o.hair
  const hairBack = o.long ? `<path d="M50 112 C40 40 160 40 150 112 L156 205 C140 214 126 200 128 168 L72 168 C74 200 60 214 44 205 Z" fill="${hair}"/>` : ''
  const hairTop = o.long
    ? `<path d="M56 112 C50 52 150 52 144 112 C140 84 126 70 110 66 C112 82 90 92 62 98 Z" fill="${hair}"/>`
    : o.curly
      ? `<path d="M56 104 C44 52 156 46 146 104 C142 88 136 80 128 76 C120 84 104 80 100 74 C92 84 76 82 70 78 C62 84 58 94 56 104 Z" fill="${hair}"/><circle cx="66" cy="70" r="12" fill="${hair}"/><circle cx="88" cy="58" r="14" fill="${hair}"/><circle cx="114" cy="57" r="14" fill="${hair}"/><circle cx="136" cy="69" r="12" fill="${hair}"/>`
      : `<path d="M57 104 C50 50 152 46 145 104 C142 86 132 74 116 72 C106 80 82 80 70 76 C62 84 58 94 57 104 Z" fill="${hair}"/>`
  const beard = o.beard ? `<path d="M68 128 C70 160 90 170 100 170 C110 170 130 160 132 128 C124 146 112 150 100 150 C88 150 76 146 68 128 Z" fill="${hair}" opacity=".85"/>` : ''
  const headset = o.headset ? `<path d="M56 110 C50 40 150 40 144 110" fill="none" stroke="#1C2333" stroke-width="8" stroke-linecap="round"/><rect x="46" y="98" width="18" height="30" rx="8" fill="#1C2333"/><rect x="136" y="98" width="18" height="30" rx="8" fill="#1C2333"/><path d="M58 126 C62 150 74 156 88 152" fill="none" stroke="#1C2333" stroke-width="4" stroke-linecap="round"/><circle cx="90" cy="151" r="6" fill="#2B3448"/>` : ''
  const glasses = o.glasses ? `<g fill="none" stroke="#1C2333" stroke-width="3"><rect x="72" y="100" width="22" height="16" rx="6"/><rect x="106" y="100" width="22" height="16" rx="6"/><path d="M94 107 H106"/></g>` : ''
  const tie = o.tie ? `<path d="M96 184 L104 184 L108 196 L100 236 L92 196 Z" fill="${o.tie}"/>` : ''
  const mic = o.mic ? `<g class="mic"><rect x="128" y="196" width="16" height="44" rx="5" fill="#1C2333" transform="rotate(-12 136 218)"/><circle cx="132" cy="192" r="13" fill="#3A4256"/><rect x="122" y="206" width="22" height="12" rx="3" fill="${o.micTag || '#F5B82E'}" transform="rotate(-12 133 212)"/><ellipse cx="148" cy="240" rx="14" ry="11" fill="${s}"/></g>` : ''
  return `<svg viewBox="0 0 200 260" class="person">
    ${hairBack}
    <path d="M22 260 C22 206 54 182 100 178 C146 182 178 206 178 260 Z" fill="${o.jacket}"/>
    <path d="M78 180 L100 238 L122 180 C114 176 86 176 78 180 Z" fill="${o.shirt}"/>
    ${tie}
    <path d="M78 180 L100 238 L86 260 L60 196 Z" fill="${shade(o.jacket, -18)}"/><path d="M122 180 L100 238 L114 260 L140 196 Z" fill="${shade(o.jacket, -18)}"/>
    <rect x="86" y="140" width="28" height="44" rx="12" fill="${sd}"/>
    <ellipse cx="58" cy="112" rx="9" ry="13" fill="${sd}"/><ellipse cx="142" cy="112" rx="9" ry="13" fill="${sd}"/>
    <ellipse cx="100" cy="108" rx="43" ry="52" fill="${s}"/>
    ${beard}
    ${hairTop}
    <g class="eyes"><ellipse cx="83" cy="108" rx="8" ry="6.5" fill="#fff"/><ellipse cx="117" cy="108" rx="8" ry="6.5" fill="#fff"/><circle cx="84" cy="109" r="4.2" fill="${o.eye || '#3B2A20'}"/><circle cx="118" cy="109" r="4.2" fill="${o.eye || '#3B2A20'}"/><circle cx="85.5" cy="107.5" r="1.4" fill="#fff"/><circle cx="119.5" cy="107.5" r="1.4" fill="#fff"/></g>
    <path d="M72 96 Q83 89 94 95" fill="none" stroke="${shade(hair, 10)}" stroke-width="4" stroke-linecap="round"/><path d="M106 95 Q117 89 128 96" fill="none" stroke="${shade(hair, 10)}" stroke-width="4" stroke-linecap="round"/>
    ${glasses}
    <path d="M100 112 Q95 126 101 129" fill="none" stroke="${shade(s, -45)}" stroke-width="2.6" stroke-linecap="round"/>
    <circle cx="74" cy="128" r="7" fill="#F28B82" opacity=".22"/><circle cx="126" cy="128" r="7" fill="#F28B82" opacity=".22"/>
    <g class="mouth"><path d="M86 138 Q100 152 114 138 Q100 144 86 138 Z" fill="#8E2F2F"/><path d="M89 139 Q100 143 111 139 L110 141 Q100 145 90 141 Z" fill="#fff"/></g>
    ${headset}${mic}
  </svg>`
}
export const CASTER = { skin: '#D9A07A', hair: '#2A1B14', curly: true, jacket: '#F5B82E', shirt: '#FFFFFF', headset: true, mic: true, micTag: '#1B4FB8' }
export const HOST_A = { skin: '#F1C7A5', hair: '#7A3E22', long: true, jacket: '#E9DCC8', shirt: '#FFFFFF', eye: '#2E5E3A' }
export const HOST_B = { skin: '#E8B992', hair: '#4A3426', jacket: '#3A3F4B', shirt: '#D9DEE6', tie: '#1B4FB8', beard: true }
const COACH = (side) => ({ skin: side === 'home' ? '#E9BE98' : '#D7A47C', hair: side === 'home' ? '#B8B8B8' : '#2B2017', jacket: '#1F2633', shirt: '#FFFFFF', tie: K(side).kit === '#F2F2F2' ? '#F5B82E' : K(side).kit, glasses: side === 'home' })

// ---------------------------------------------------------------- stadium background (painted once)
export function paintBg(c) {
  const r = c.getBoundingClientRect(), d = Math.min(2, devicePixelRatio || 1)
  c.width = r.width * d; c.height = r.height * d; const g = c.getContext('2d'); g.scale(d, d)
  const W = r.width, H = r.height
  const sky = g.createLinearGradient(0, 0, 0, H); sky.addColorStop(0, '#060E22'); sky.addColorStop(.5, '#0B1E44'); sky.addColorStop(1, '#06112A'); g.fillStyle = sky; g.fillRect(0, 0, W, H)
  // stands: three tiers of crowd dots
  let seed = 7; const rnd = () => (seed = (seed * 16807) % 2147483647) / 2147483647
  const tiers = [[H * 0.12, H * 0.3], [H * 0.3, H * 0.47]]
  for (const [y0, y1] of tiers) { g.fillStyle = '#0E2551'; g.fillRect(0, y0, W, y1 - y0); for (let i = 0; i < W * (y1 - y0) / 55; i++) { const x = rnd() * W, y = y0 + rnd() * (y1 - y0); g.fillStyle = ['#3355A0', '#C8102E', '#DDE3F0', '#F5B82E', '#21407F'][(rnd() * 5) | 0]; g.globalAlpha = .55; g.fillRect(x, y, 2.2, 2.6) } g.globalAlpha = 1 }
  // advertising board
  g.fillStyle = '#12306A'; g.fillRect(0, H * 0.47, W, H * 0.025); for (let x = 0; x < W; x += 120) { g.fillStyle = 'rgba(245,184,46,.55)'; g.fillRect(x + 20, H * 0.476, 60, H * 0.012) }
  // pitch in perspective
  const top = H * 0.495, bot = H * 1.02
  for (let i = 0; i < 12; i++) { const a = top + (bot - top) * Math.pow(i / 12, 1.6), b = top + (bot - top) * Math.pow((i + 1) / 12, 1.6); g.fillStyle = i % 2 ? '#1E7A3E' : '#1A6E37'; g.fillRect(0, a, W, b - a + 1) }
  g.strokeStyle = 'rgba(255,255,255,.55)'; g.lineWidth = 2
  g.beginPath(); g.moveTo(W * 0.04, top + 6); g.lineTo(W * 0.96, top + 6); g.stroke()
  g.beginPath(); g.moveTo(W * 0.5, top + 6); g.lineTo(W * 0.5, bot); g.stroke()
  g.beginPath(); g.ellipse(W * 0.5, H * 0.72, W * 0.13, H * 0.06, 0, 0, 7); g.stroke()
  // floodlight glow
  for (const x of [W * 0.12, W * 0.88]) { const gl = g.createRadialGradient(x, H * 0.06, 0, x, H * 0.06, W * 0.35); gl.addColorStop(0, 'rgba(220,235,255,.55)'); gl.addColorStop(1, 'rgba(220,235,255,0)'); g.fillStyle = gl; g.fillRect(0, 0, W, H) }
}


// ---------------------------------------------------------------- icons for the timeline cards
const ball = (x, y, r, cls = '') => `<g class="${cls}" transform="translate(${x} ${y})"><circle r="${r}" fill="#fff" stroke="#111" stroke-width="${r * 0.08}"/><path d="M0 ${-r * 0.42} L${r * 0.4} ${-r * 0.12} L${r * 0.25} ${r * 0.36} L${-r * 0.25} ${r * 0.36} L${-r * 0.4} ${-r * 0.12} Z" fill="#111"/><path d="M0 ${-r * 0.42} V${-r} M${r * 0.4} ${-r * 0.12} L${r * 0.95} ${-r * 0.3} M${r * 0.25} ${r * 0.36} L${r * 0.6} ${r * 0.8} M${-r * 0.25} ${r * 0.36} L${-r * 0.6} ${r * 0.8} M${-r * 0.4} ${-r * 0.12} L${-r * 0.95} ${-r * 0.3}" stroke="#111" stroke-width="${r * 0.08}"/></g>`
export const ICON = {
  goal: `<svg viewBox="0 0 32 32"><path d="M3 26 V8 H29 V26" fill="none" stroke="#fff" stroke-width="2.4"/><path d="M6 8 V26 M10 8 V26 M14 8 V26 M18 8 V26 M22 8 V26 M26 8 V26 M3 12 H29 M3 17 H29 M3 22 H29" stroke="rgba(255,255,255,.35)" stroke-width="1"/>${ball(20, 19, 6)}</svg>`,
  miss: `<svg viewBox="0 0 32 32"><path d="M8 28 V6 H12" fill="none" stroke="#fff" stroke-width="2.6"/>${ball(22, 12, 5.5)}<path d="M13 22 C16 18 18 16 20 14" stroke="#F5B82E" stroke-width="2" stroke-dasharray="2 2" fill="none"/></svg>`,
  save: `<svg viewBox="0 0 32 32"><path d="M9 28 C7 20 7 14 9 8 C10 6 12 6 12.5 8 L13 15 L14 5 C14.5 3 17 3 17 5 L17 14 L18 6 C18.5 4 21 4 21 6 L20.5 15 L22 9 C22.5 7 25 7.5 24.5 9.5 L23 20 C22 25 20 28 17 28 Z" fill="#3DDC97" stroke="#0B2350" stroke-width="1.4"/></svg>`,
  yellow: `<svg viewBox="0 0 32 32"><rect x="9" y="5" width="14" height="21" rx="2.5" fill="#FFD400" transform="rotate(8 16 16)"/></svg>`,
  red: `<svg viewBox="0 0 32 32"><rect x="9" y="5" width="14" height="21" rx="2.5" fill="#E5262B" transform="rotate(8 16 16)"/></svg>`,
  whistle: `<svg viewBox="0 0 32 32"><rect x="4" y="13" width="17" height="11" rx="5.5" fill="#F5B82E"/><rect x="18" y="14.5" width="10" height="5" rx="1.5" fill="#F5B82E"/><circle cx="10" cy="18.5" r="2.5" fill="#0B2350"/><path d="M7 8 Q12 4 17 8 M4 5 Q12 -1 20 5" stroke="#F5B82E" stroke-width="1.8" fill="none" stroke-linecap="round"/></svg>`,
  penalty: `<svg viewBox="0 0 32 32"><path d="M4 14 V5 H28 V14" fill="none" stroke="#fff" stroke-width="2.2"/><ellipse cx="16" cy="24" rx="3" ry="1.5" fill="#fff" opacity=".7"/>${ball(16, 21, 4.5)}</svg>`,
  flag: `<svg viewBox="0 0 32 32"><path d="M9 29 V4" stroke="#DDE3F0" stroke-width="2.4"/><path d="M10 5 H24 L21 9.5 L24 14 H10 Z" fill="#EF4444"/><path d="M10 5 H17 V9.5 H10 Z M17 9.5 H24 L24 14 H17 Z" fill="#F5B82E"/></svg>`,
  corner: `<svg viewBox="0 0 32 32"><path d="M6 28 V6" stroke="#DDE3F0" stroke-width="2.2"/><path d="M7 6 L20 10 L7 14 Z" fill="#F5B82E"/><path d="M6 28 A10 10 0 0 1 16 18" fill="none" stroke="#fff" stroke-width="2"/></svg>`,
  sub: `<svg viewBox="0 0 32 32"><path d="M11 26 V9 M5 14 L11 7 L17 14" fill="none" stroke="#3DDC97" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/><path d="M21 6 V23 M15 18 L21 25 L27 18" fill="none" stroke="#EF4444" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/></svg>`,
  injury: `<svg viewBox="0 0 32 32"><rect x="5" y="5" width="22" height="22" rx="6" fill="#fff"/><path d="M13 9 H19 V13 H23 V19 H19 V23 H13 V19 H9 V13 H13 Z" fill="#E5262B"/></svg>`,
  coach: `<svg viewBox="0 0 32 32"><rect x="7" y="6" width="18" height="23" rx="3" fill="#DDE3F0"/><rect x="12" y="3.5" width="8" height="5" rx="1.5" fill="#F5B82E"/><path d="M10 14 L14 18 M14 14 L10 18 M18 22 a2.2 2.2 0 1 0 0.1 0 M15 19 C18 14 20 13 22 11" stroke="#0B2350" stroke-width="1.8" fill="none" stroke-linecap="round"/></svg>`,
  foul: `<svg viewBox="0 0 32 32"><path d="M5 22 C10 22 13 18 16 14 L21 17" stroke="#fff" stroke-width="3" fill="none" stroke-linecap="round"/><circle cx="24" cy="10" r="3.5" fill="#fff"/><path d="M8 27 L26 27" stroke="#F5B82E" stroke-width="2"/><path d="M19 22 l4 -4 M23 22 l-4 -4" stroke="#EF4444" stroke-width="2.4" stroke-linecap="round"/></svg>`,
}


// ---------------------------------------------------------------- scene kit: players and goal drawn in SVG
function el(tag, attrs, parent) { const e = document.createElementNS(NS, tag); for (const k in attrs) e.setAttribute(k, attrs[k]); parent && parent.appendChild(e); return e }
function sceneBase() {
  const svg = el('svg', { viewBox: '0 0 360 210' })
  svg.innerHTML = `<defs>
    <linearGradient id="grass" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#2A8A47"/><stop offset="1" stop-color="#1C6634"/></linearGradient>
    <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0A1B3D"/><stop offset="1" stop-color="#16346E"/></linearGradient>
    <radialGradient id="flood" cx=".5" cy="0" r=".9"><stop offset="0" stop-color="rgba(255,255,255,.35)"/><stop offset="1" stop-color="rgba(255,255,255,0)"/></radialGradient>
    <pattern id="net" width="7" height="7" patternUnits="userSpaceOnUse"><path d="M0 0 L7 7 M7 0 L0 7" stroke="rgba(255,255,255,.55)" stroke-width=".8"/></pattern>
  </defs>
  <rect width="360" height="210" fill="url(#sky)"/>
  <g opacity=".7">${Array.from({ length: 160 }, (_, i) => `<rect x="${(i * 37) % 360}" y="${18 + ((i * 53) % 70)}" width="2.4" height="3" fill="${['#3355A0', '#C8102E', '#DDE3F0', '#F5B82E'][i % 4]}"/>`).join('')}</g>
  <rect y="88" width="360" height="10" fill="#12306A"/><rect y="90" width="360" height="3" fill="rgba(245,184,46,.5)"/>
  <rect y="98" width="360" height="112" fill="url(#grass)"/>
  ${Array.from({ length: 6 }, (_, i) => `<rect y="${98 + i * 19}" width="360" height="9" fill="rgba(255,255,255,.035)"/>`).join('')}
  <rect width="360" height="210" fill="url(#flood)"/>`
  return svg
}
function goalFrame(svg, x = 120, y = 52, w = 150, h = 72) {
  const g = el('g', {}, svg)
  const net = el('path', { d: `M${x} ${y} L${x + 14} ${y - 10} L${x + w - 14} ${y - 10} L${x + w} ${y} L${x + w} ${y + h} L${x} ${y + h} Z`, fill: 'url(#net)', stroke: 'rgba(255,255,255,.4)', 'stroke-width': 1 }, g)
  el('path', { d: `M${x} ${y + h} L${x} ${y} L${x + w} ${y} L${x + w} ${y + h}`, fill: 'none', stroke: '#fff', 'stroke-width': 5, 'stroke-linejoin': 'round' }, g)
  el('line', { x1: x - 30, y1: y + h, x2: x + w + 30, y2: y + h, stroke: 'rgba(255,255,255,.7)', 'stroke-width': 2 }, g)
  return { g, net, x, y, w, h }
}
// A footballer: head, hair, shirt with number, shorts, socks. pose angles in degrees.
function figure(svg, kit, opt = {}) {
  const g = el('g', {}, svg), sk = opt.skin || '#D9A07A', sc = opt.scale || 1
  const legL = el('g', {}, g), legR = el('g', {}, g)
  for (const leg of [legL, legR]) { el('rect', { x: -4, y: 0, width: 8, height: 16, rx: 3.5, fill: sk }, leg); el('rect', { x: -4.5, y: 10, width: 9, height: 14, rx: 3.5, fill: opt.socks || kit.trim }, leg); el('ellipse', { cx: 1.5, cy: 25, rx: 6, ry: 3, fill: '#111' }, leg) }
  legL.setAttribute('transform', 'translate(-6 30)'); legR.setAttribute('transform', 'translate(6 30)')
  el('rect', { x: -12, y: 22, width: 24, height: 13, rx: 4, fill: opt.shorts || shade(kit.kit, -25) }, g)
  const armL = el('g', {}, g), armR = el('g', {}, g)
  for (const arm of [armL, armR]) { el('rect', { x: -4, y: 0, width: 8, height: 12, rx: 4, fill: kit.kit }, arm); el('rect', { x: -3.5, y: 9, width: 7, height: 13, rx: 3.5, fill: opt.gloves || sk }, arm) }
  armL.setAttribute('transform', 'translate(-15 2)'); armR.setAttribute('transform', 'translate(15 2)')
  el('path', { d: 'M-15 0 C-15 -6 -9 -9 0 -9 C9 -9 15 -6 15 0 L13 25 L-13 25 Z', fill: kit.kit, stroke: shade(kit.kit, -30), 'stroke-width': 1 }, g)
  if (opt.no) { const t = el('text', { x: 0, y: 14, 'text-anchor': 'middle', 'font-family': 'Alexandria', 'font-weight': 900, 'font-size': 13, fill: kit.ink }, g); t.textContent = opt.no }
  el('rect', { x: -4, y: -14, width: 8, height: 7, fill: shade(sk, -20) }, g)
  el('circle', { cx: 0, cy: -22, r: 10.5, fill: sk }, g)
  el('path', { d: 'M-10.5 -23 C-11 -36 11 -36 10.5 -23 C8 -30 -6 -31 -10.5 -23 Z', fill: opt.hair || '#2A1B14' }, g)
  const parts = { g, legL, legR, armL, armR }
  parts.pose = (x, y, a = {}) => {
    g.setAttribute('transform', `translate(${x} ${y}) rotate(${a.body || 0}) scale(${sc * (a.flip ? -1 : 1)} ${sc})`)
    legL.setAttribute('transform', `translate(-6 30) rotate(${a.ll || 0})`); legR.setAttribute('transform', `translate(6 30) rotate(${a.lr || 0})`)
    armL.setAttribute('transform', `translate(-15 2) rotate(${a.al || 0})`); armR.setAttribute('transform', `translate(15 2) rotate(${a.ar || 0})`)
  }
  return parts
}
function bigBall(svg) { const g = el('g', {}, svg); g.innerHTML = ball(0, 0, 7); return g }
const at = (g, x, y, r = 0, s = 1) => g.setAttribute('transform', `translate(${x} ${y}) rotate(${r}) scale(${s})`)
const lerp = (a, b, f) => a + (b - a) * f
const clamp01 = (v) => Math.max(0, Math.min(1, v))
const seg = (t, a, b) => clamp01((t - a) / (b - a))
const ease = (f) => f * f * (3 - 2 * f)
const quad = (p0, p1, p2, f) => [(1 - f) * (1 - f) * p0[0] + 2 * (1 - f) * f * p1[0] + f * f * p2[0], (1 - f) * (1 - f) * p0[1] + 2 * (1 - f) * f * p1[1] + f * f * p2[1]]
function bigText(svg, text, color) { const t = el('text', { x: 180, y: 112, 'text-anchor': 'middle', 'dominant-baseline': 'middle', 'font-family': 'Alexandria', 'font-weight': 900, 'font-size': 52, fill: color, stroke: '#071733', 'stroke-width': 6, 'paint-order': 'stroke', opacity: 0 }, svg); t.textContent = text; return (f) => { t.setAttribute('opacity', f); t.setAttribute('transform', `translate(180 112) scale(${0.5 + 0.5 * ease(f)}) translate(-180 -112)`) } }
const KEEPER = (side) => ({ kit: side === 'home' ? '#3DDC97' : '#2B2F3A', ink: '#0A1F42', trim: side === 'home' ? '#1B8F5E' : '#F5B82E' })

// ---------------------------------------------------------------- scenes
export const SCENES = {
  goal(e) {
    const svg = sceneBase(), G = goalFrame(svg), atk = K(e.side), kp = figure(svg, KEEPER(e.side === 'home' ? 'away' : 'home'), { gloves: '#F5B82E', scale: 0.95 })
    const sh = figure(svg, atk, { no: e.no, scale: 1.25, hair: e.hair }), b = bigBall(svg), txt = bigText(svg, 'هدف!', '#F5B82E')
    const sparks = Array.from({ length: 14 }, (_, i) => el('circle', { r: 2.5, fill: i % 2 ? '#F5B82E' : '#fff', opacity: 0 }, svg))
    return { dur: 5.2, svg, update(t) {
      const run = seg(t, 0, 1.1), kick = t > 1.1, fly = ease(seg(t, 1.15, 1.75))
      sh.pose(lerp(70, 112, ease(run)), 150, kick ? { lr: -55 * (1 - seg(t, 1.1, 1.5)), ll: 15, al: 30, ar: -40 } : { ll: Math.sin(t * 14) * 28, lr: -Math.sin(t * 14) * 28, al: -Math.sin(t * 14) * 25, ar: Math.sin(t * 14) * 25 })
      if (t > 2.2) sh.pose(lerp(112, 140, seg(t, 2.2, 3)), 150 - 12 * Math.abs(Math.sin(t * 6)), { al: -150, ar: 150, ll: 10, lr: -10 })
      const [bx, by] = t < 1.15 ? [lerp(86, 126, ease(run)), 178] : quad([126, 178], [190, 70], [238, 78], fly)
      at(b, t > 1.75 ? 238 + Math.sin(t * 30) * seg(t, 1.75, 2.3) * (1 - seg(t, 2, 2.6)) * 3 : bx, t > 1.75 ? 78 + seg(t, 1.75, 2.6) * 40 : by, t * 500, t > 1.15 ? 1 - fly * 0.35 : 1)
      const dive = ease(seg(t, 1.45, 1.95))
      kp.pose(lerp(196, 162, dive), lerp(116, 108, dive), { body: -70 * dive, al: -160 * dive, ar: -150 * dive, ll: 10, lr: -10 })
      const bulge = seg(t, 1.75, 1.95) * (1 - seg(t, 2.1, 2.8))
      G.net.setAttribute('transform', `translate(${bulge * 6} ${-bulge * 8})`)
      txt(seg(t, 1.85, 2.2))
      sparks.forEach((s, i) => { const a = (i / sparks.length) * 6.28, f = seg(t, 1.85, 2.9); s.setAttribute('cx', 238 + Math.cos(a) * f * 70); s.setAttribute('cy', 80 + Math.sin(a) * f * 50); s.setAttribute('opacity', (1 - f) * (f > 0 ? 1 : 0)) })
    } }
  },
  save(e) {
    const svg = sceneBase(), G = goalFrame(svg), atk = K(e.side), def = e.side === 'home' ? 'away' : 'home'
    const sh = figure(svg, atk, { no: e.shooterNo, scale: 1.2 }), kp = figure(svg, KEEPER(def), { gloves: '#F5B82E', no: 1, scale: 1.05 }), b = bigBall(svg), txt = bigText(svg, 'تصدٍّ!', '#3DDC97')
    return { dur: 4.6, svg, update(t) {
      const run = seg(t, 0, 1), fly = ease(seg(t, 1.05, 1.55)), dive = ease(seg(t, 1.1, 1.55))
      sh.pose(lerp(70, 110, ease(run)), 150, t > 1 ? { lr: -50, ll: 15, al: 30, ar: -40 } : { ll: Math.sin(t * 14) * 28, lr: -Math.sin(t * 14) * 28 })
      if (t > 2.2) sh.pose(110, 150, { al: -170, ar: 170 })
      kp.pose(lerp(195, 158, dive), lerp(116, 100, dive), { body: -72 * dive, al: -165 * dive, ar: -150 * dive })
      const [bx, by] = t < 1.05 ? [lerp(84, 124, ease(run)), 178] : t < 1.55 ? quad([124, 178], [150, 100], [150, 88], fly) : [150 - seg(t, 1.55, 2.4) * 50, 88 + seg(t, 1.55, 2.4) * 90]
      at(b, bx, by, t * 400)
      txt(seg(t, 1.6, 1.95))
    } }
  },
  penalty(e) {
    const svg = sceneBase(), G = goalFrame(svg, 105, 40, 150, 78), atk = K(e.side), def = e.side === 'home' ? 'away' : 'home'
    el('ellipse', { cx: 180, cy: 182, rx: 9, ry: 3, fill: 'rgba(255,255,255,.85)' }, svg)
    const kp = figure(svg, KEEPER(def), { gloves: '#F5B82E', no: 1, scale: 1.05 }), tk = figure(svg, atk, { no: e.no, scale: 1.3 }), b = bigBall(svg)
    const txt = bigText(svg, e.scored ? 'هدف!' : 'تصدّى!', e.scored ? '#F5B82E' : '#3DDC97')
    const hush = el('text', { x: 180, y: 30, 'text-anchor': 'middle', 'font-family': 'IBM Plex Sans Arabic', 'font-weight': 700, 'font-size': 13, fill: '#A9B6CC', opacity: 0 }, svg); hush.textContent = 'الملعب يحبس أنفاسه...'
    return { dur: 5.6, svg, update(t) {
      hush.setAttribute('opacity', seg(t, 0.2, 0.6) * (1 - seg(t, 1.9, 2.2)))
      const run = ease(seg(t, 1.2, 2.2)), fly = ease(seg(t, 2.25, 2.7))
      tk.pose(lerp(120, 166, run), 150, t > 2.2 ? { lr: -55, ll: 10, al: 30, ar: -40 } : t > 1.2 ? { ll: Math.sin(t * 12) * 25, lr: -Math.sin(t * 12) * 25 } : { al: 10, ar: -10 })
      if (t > 3.3) tk.pose(166, 150, e.scored ? { al: -160, ar: 160 } : { al: -40, ar: 40 })
      // the keeper sways, then guesses
      const guess = e.scored ? 1 : -1, dive = ease(seg(t, 2.3, 2.8))
      kp.pose(180 + Math.sin(t * 5) * 4 * (1 - seg(t, 2.2, 2.3)) + guess * 40 * dive, lerp(110, 98, dive), { body: guess * 75 * dive, al: guess * 160 * dive, ar: guess * 150 * dive })
      const target = e.scored ? [130, 62] : [138, 70]
      const [bx, by] = t < 2.25 ? [180, 178] : t < 2.7 ? quad([180, 178], [160, 120], target, fly) : e.scored ? [130 - seg(t, 2.7, 3) * 4, 62 + seg(t, 2.7, 3.4) * 50] : [138 - seg(t, 2.7, 3.4) * 70, 70 + seg(t, 2.7, 3.4) * 90]
      at(b, bx, by, t * 400, t > 2.25 ? 1 - fly * 0.3 : 1)
      if (e.scored) G.net.setAttribute('transform', `translate(${-seg(t, 2.65, 2.85) * (1 - seg(t, 3, 3.6)) * 6} ${-seg(t, 2.65, 2.85) * (1 - seg(t, 3, 3.6)) * 7})`)
      txt(seg(t, 2.8, 3.15))
    } }
  },
  freekick(e) {
    const svg = sceneBase(), G = goalFrame(svg, 150, 50, 150, 72), atk = K(e.side), def = K(e.side === 'home' ? 'away' : 'home')
    const kp = figure(svg, KEEPER(e.side === 'home' ? 'away' : 'home'), { gloves: '#F5B82E', scale: 0.9 })
    const wall = [0, 1, 2, 3].map(() => figure(svg, def, { scale: 0.95 }))
    const tk = figure(svg, atk, { no: e.no, scale: 1.3 }), b = bigBall(svg), txt = bigText(svg, e.scored ? 'هدف!' : 'فوق العارضة', e.scored ? '#F5B82E' : '#A9B6CC')
    return { dur: 5.2, svg, update(t) {
      wall.forEach((w, i) => w.pose(126 + i * 17, 132 - (t > 1.9 && t < 2.4 ? 10 : 0), { al: 160, ar: -160 }))
      const run = ease(seg(t, 0.6, 1.8)), fly = ease(seg(t, 1.85, 2.6))
      tk.pose(lerp(36, 66, run), 160, t > 1.8 ? { lr: -55, al: 30, ar: -40 } : t > 0.6 ? { ll: Math.sin(t * 12) * 25, lr: -Math.sin(t * 12) * 25 } : {})
      const dive = ease(seg(t, 2.1, 2.6))
      kp.pose(lerp(232, 270, dive), lerp(112, 100, dive), { body: 70 * dive, al: 150 * dive, ar: 160 * dive })
      const end = e.scored ? [288, 58] : [292, 30]
      const [bx, by] = t < 1.85 ? [82, 188] : t < 2.6 ? quad([82, 188], [170, 10], end, fly) : e.scored ? [288, 58 + seg(t, 2.6, 3.3) * 60] : [292 + seg(t, 2.6, 3.2) * 50, 30 - seg(t, 2.6, 3.2) * 20]
      at(b, bx, by, t * 500, t > 1.85 ? 1 - fly * 0.4 : 1)
      if (e.scored) G.net.setAttribute('transform', `translate(${seg(t, 2.55, 2.75) * (1 - seg(t, 2.9, 3.5)) * 6} ${-seg(t, 2.55, 2.75) * (1 - seg(t, 2.9, 3.5)) * 7})`)
      txt(seg(t, 2.7, 3.05))
    } }
  },
  card(e) {
    const svg = sceneBase(), col = e.type === 'red' ? '#E5262B' : '#FFD400'
    const ref = figure(svg, { kit: '#1C1C1C', ink: '#fff', trim: '#1C1C1C' }, { scale: 2.1, hair: '#111' })
    const fouler = figure(svg, K(e.side), { no: e.no, scale: 1.5 })
    const card = el('rect', { x: -14, y: -20, width: 28, height: 40, rx: 4, fill: col, stroke: shade(col, -40), 'stroke-width': 1.5 }, svg)
    const glow = el('circle', { r: 46, fill: col, opacity: 0 }, svg); svg.insertBefore(glow, card)
    const txt = bigText(svg, e.type === 'red' ? 'طرد!' : 'إنذار', col)
    return { dur: 4.4, svg, update(t) {
      fouler.pose(118, 136, t > 1.6 ? { al: -60, ar: 60, body: 4 } : { al: -20, ar: 20 })
      const up = ease(seg(t, 0.5, 1.1))
      ref.pose(236, 112, { ar: -175 * up, al: 12 })
      const hx = 236 + 15 * 2.1 + Math.sin((-175 * up + 180) * Math.PI / 180) * 0, hy = 112 + 4 - up * 50
      at(card, 236 + 34, lerp(150, 34, up), 10 * (1 - up))
      at(glow, 270, lerp(150, 34, up), 0, 0.6 + 0.4 * Math.sin(t * 8))
      glow.setAttribute('opacity', 0.25 * up)
      txt(seg(t, 1.3, 1.7))
    } }
  },
  coach(e) {
    const svg = sceneBase()
    const g = el('g', {}, svg); g.innerHTML = person(COACH(e.side)).replace('<svg viewBox="0 0 200 260" class="person">', '').replace('</svg>', '')
    const board = el('g', {}, svg)
    board.innerHTML = `<rect x="-40" y="-52" width="80" height="104" rx="8" fill="#E9EEF7" stroke="#0A1F42" stroke-width="3"/><rect x="-14" y="-60" width="28" height="14" rx="4" fill="#F5B82E"/><rect x="-32" y="-40" width="64" height="84" rx="4" fill="#2A8A47"/><path d="M-32 2 H32" stroke="#fff" stroke-width="1.2"/><circle r="9" fill="none" stroke="#fff" stroke-width="1.2"/>
      <g class="arrows" stroke="#F5B82E" stroke-width="3" fill="none" stroke-linecap="round"><path d="M-18 30 L-18 -18 M-24 -12 L-18 -20 L-12 -12"/><path d="M0 30 L0 -26 M-6 -20 L0 -28 L6 -20"/><path d="M18 30 L18 -18 M12 -12 L18 -20 L24 -12"/></g>`
    const chip = el('g', { opacity: 0 }, svg)
    chip.innerHTML = `<rect x="-78" y="-17" width="156" height="34" rx="17" fill="#F5B82E"/><text x="0" y="6" text-anchor="middle" font-family="Alexandria" font-weight="800" font-size="15" fill="#0A1F42">${e.tactic}</text>`
    return { dur: 4.6, svg, update(t) {
      const s = ease(seg(t, 0, 0.6))
      g.setAttribute('transform', `translate(${lerp(-120, 20, s)} 40) scale(0.66)`)
      const mouth = g.querySelector('.mouth'); if (mouth) mouth.setAttribute('transform', `translate(100 140) scale(1 ${1 + (t > 0.7 && t < 3.6 ? Math.abs(Math.sin(t * 11)) * 0.9 : 0)}) translate(-100 -140)`)
      at(board, lerp(420, 250, ease(seg(t, 0.4, 1))), 112, Math.sin(t * 2) * 3)
      const ar = board.querySelector('.arrows'); ar.setAttribute('transform', `translate(0 ${-((t * 18) % 10)})`)
      at(chip, 250, 188, 0, ease(seg(t, 1.1, 1.5))); chip.setAttribute('opacity', seg(t, 1.1, 1.4))
    } }
  },
  sub(e) {
    const svg = sceneBase(), k = K(e.side)
    const out = figure(svg, k, { no: e.outNo, scale: 1.5 }), inn = figure(svg, k, { no: e.inNo, scale: 1.5, hair: '#7A4A22' })
    const board = el('g', {}, svg)
    board.innerHTML = `<rect x="-46" y="-34" width="92" height="68" rx="8" fill="#111" stroke="#3A3F4B" stroke-width="3"/><text x="-18" y="-6" text-anchor="middle" font-family="Alexandria" font-weight="900" font-size="22" fill="#EF4444">${e.outNo}</text><text x="18" y="-6" text-anchor="middle" font-family="Alexandria" font-weight="900" font-size="22" fill="#3DDC97">${e.inNo}</text><path d="M-18 6 V24 M-24 18 L-18 26 L-12 18" stroke="#EF4444" stroke-width="3" fill="none"/><path d="M18 26 V8 M12 14 L18 6 L24 14" stroke="#3DDC97" stroke-width="3" fill="none"/><rect x="-6" y="34" width="12" height="40" fill="#2B2F3A"/>`
    return { dur: 4.2, svg, update(t) {
      at(board, 180, lerp(250, 96, ease(seg(t, 0, 0.6))))
      const w = Math.sin(t * 12) * 22
      out.pose(lerp(110, 30, ease(seg(t, 0.8, 3))), 150, { ll: w, lr: -w, al: -w * 0.6, ar: w * 0.6, flip: true })
      inn.pose(lerp(330, 252, ease(seg(t, 0.8, 3))), 150, { ll: w, lr: -w, al: -w, ar: w })
    } }
  },
  offside(e) {
    const svg = sceneBase(), k = K(e.side)
    const runner = figure(svg, k, { no: e.no, scale: 1.4 })
    const lin = figure(svg, { kit: '#F5B82E', ink: '#0A1F42', trim: '#111' }, { scale: 1.6, hair: '#111' })
    const flag = el('g', {}, svg); flag.innerHTML = '<rect x="-1.5" y="0" width="3" height="46" fill="#DDE3F0"/><path d="M1.5 2 H30 L24 12 L30 22 H1.5 Z" fill="#F5B82E"/><path d="M1.5 2 H15 V12 H1.5 Z M15 12 H30 L30 22 H15 Z" fill="#EF4444"/>'
    const line = el('line', { x1: 0, y1: 110, x2: 360, y2: 190, stroke: '#EF4444', 'stroke-width': 3, 'stroke-dasharray': '8 6', opacity: 0 }, svg)
    const txt = bigText(svg, 'تسلل', '#EF4444')
    return { dur: 4.2, svg, update(t) {
      const w = Math.sin(t * 12) * 24 * (1 - seg(t, 1.2, 1.4))
      runner.pose(lerp(70, 160, ease(seg(t, 0, 1.3))), 152, t > 1.6 ? { al: -150, ar: 150 } : { ll: w, lr: -w, al: -w, ar: w })
      lin.pose(286, 128, { ar: -170 * ease(seg(t, 0.9, 1.3)) })
      at(flag, 286 + 30, lerp(140, 30, ease(seg(t, 0.9, 1.3))), Math.sin(t * 10) * 8 * seg(t, 1.3, 1.5))
      line.setAttribute('opacity', seg(t, 1.4, 1.7)); txt(seg(t, 1.5, 1.85))
    } }
  },
  corner(e) {
    const svg = sceneBase(), G = goalFrame(svg, 170, 54, 150, 70), k = K(e.side), d = K(e.side === 'home' ? 'away' : 'home')
    el('path', { d: 'M20 205 V140', stroke: '#DDE3F0', 'stroke-width': 3 }, svg); el('path', { d: 'M21 140 L44 147 L21 154 Z', fill: '#F5B82E' }, svg)
    const def = figure(svg, d, { scale: 1.15 }), hd = figure(svg, k, { no: e.no, scale: 1.25 }), b = bigBall(svg)
    const txt = bigText(svg, e.scored ? 'هدف!' : 'رأسية فوق العارضة', e.scored ? '#F5B82E' : '#A9B6CC')
    return { dur: 4.6, svg, update(t) {
      const fly = ease(seg(t, 0.6, 1.7)), jump = Math.sin(clamp01(seg(t, 1.4, 2.1)) * Math.PI)
      hd.pose(214, 150 - jump * 26, { al: -120 * jump, ar: 120 * jump })
      def.pose(194, 152 - jump * 14, { al: -100 * jump, ar: 100 * jump })
      const [bx, by] = t < 0.6 ? [30, 196] : t < 1.7 ? quad([30, 196], [110, 10], [216, 98], fly) : quad([216, 98], [228, 40], e.scored ? [262, 80] : [252, 30], ease(seg(t, 1.7, 2.2)))
      at(b, bx, by, t * 400)
      txt(seg(t, 2.2, 2.6))
    } }
  },
  injury(e) {
    const svg = sceneBase(), k = K(e.side)
    const p = figure(svg, k, { no: e.no, scale: 1.4 })
    const med = el('g', {}, svg); med.innerHTML = `<rect x="-26" y="-26" width="52" height="52" rx="12" fill="#fff"/><path d="M-8 -18 H8 V-8 H18 V8 H8 V18 H-8 V8 H-18 V-8 H-8 Z" fill="#E5262B"/>`
    return { dur: 3.8, svg, update(t) {
      p.pose(170, 176, { body: 82, al: -40, ar: 20, ll: 30, lr: -10 })
      at(med, 270, 78, 0, 0.9 + 0.12 * Math.sin(t * 6))
    } }
  },
  whistle(e) {
    const svg = sceneBase(), ref = figure(svg, { kit: '#1C1C1C', ink: '#fff', trim: '#1C1C1C' }, { scale: 2.2, hair: '#111' })
    const w = el('g', {}, svg); w.innerHTML = ICON.whistle.replace('<svg viewBox="0 0 32 32">', '').replace('</svg>', '')
    const waves = [0, 1, 2].map((i) => el('path', { d: 'M0 0 A 20 20 0 0 1 20 20', fill: 'none', stroke: '#F5B82E', 'stroke-width': 3, opacity: 0 }, svg))
    const txt = bigText(svg, e.big, '#F7F4EA')
    return { dur: 3.6, svg, update(t) {
      ref.pose(150, 116, { ar: -150, al: 20 })
      at(w, 196, 52, 0, 1.6)
      waves.forEach((p, i) => { const f = ((t * 1.4 + i / 3) % 1); p.setAttribute('transform', `translate(240 60) scale(${0.6 + f})`); p.setAttribute('opacity', (1 - f) * seg(t, 0.2, 0.4)) })
      txt(seg(t, 0.8, 1.2))
    } }
  },
  miss(e) {
    // Wide of the post, over the bar, or off the woodwork (e.how).
    const svg = sceneBase(), G = goalFrame(svg), atk = K(e.side), def = e.side === 'home' ? 'away' : 'home'
    const kp = figure(svg, KEEPER(def), { gloves: '#F5B82E', scale: 0.95 }), sh = figure(svg, atk, { no: e.no, scale: 1.25 }), b = bigBall(svg)
    const txt = bigText(svg, e.how === 'post' ? 'القائم!' : e.how === 'over' ? 'فوق العارضة' : 'بجانب القائم', '#A9B6CC')
    const end = e.how === 'post' ? [270, 70] : e.how === 'over' ? [212, 22] : [290, 96]
    return { dur: 4.2, svg, update(t) {
      const run = seg(t, 0, 1.1), fly = ease(seg(t, 1.15, 1.7))
      sh.pose(lerp(70, 112, ease(run)), 150, t > 1.1 ? { lr: -55 * (1 - seg(t, 1.1, 1.5)), ll: 15, al: 30, ar: -40 } : { ll: Math.sin(t * 14) * 28, lr: -Math.sin(t * 14) * 28 })
      if (t > 1.9) sh.pose(112, 150, { al: -150, ar: 150, body: Math.sin(t * 3) * 3 })
      const [bx, by] = t < 1.15 ? [lerp(86, 126, ease(run)), 178] : t < 1.7 ? quad([126, 178], [200, 40], end, fly) : e.how === 'post' ? [270 - seg(t, 1.7, 2.4) * 60, 70 + seg(t, 1.7, 2.4) * 100] : [end[0] + seg(t, 1.7, 2.3) * 40, end[1] - seg(t, 1.7, 2.3) * 10]
      at(b, bx, by, t * 500, t > 1.15 ? 1 - fly * 0.35 : 1)
      kp.pose(196 + (t > 1.3 ? 8 : 0), 116, { al: -30, ar: 30 })
      if (e.how === 'post') G.g.setAttribute('transform', `translate(${Math.sin(t * 60) * 2 * seg(t, 1.68, 1.75) * (1 - seg(t, 1.8, 2.2))} 0)`)
      txt(seg(t, 1.8, 2.15))
    } }
  },
  blocked(e) {
    const svg = sceneBase(), G = goalFrame(svg), atk = K(e.side), def = K(e.side === 'home' ? 'away' : 'home')
    const d = figure(svg, def, { no: e.defNo, scale: 1.2 }), sh = figure(svg, atk, { no: e.no, scale: 1.25 }), b = bigBall(svg), txt = bigText(svg, 'صدّها الدفاع!', '#7FB4FF')
    return { dur: 4, svg, update(t) {
      const run = seg(t, 0, 1.1), slide = ease(seg(t, 0.9, 1.3))
      sh.pose(lerp(70, 112, ease(run)), 150, t > 1.1 ? { lr: -50, ll: 15, al: 30, ar: -40 } : { ll: Math.sin(t * 14) * 28, lr: -Math.sin(t * 14) * 28 })
      d.pose(lerp(210, 160, slide), lerp(150, 168, slide), { body: -60 * slide, ll: -60 * slide, lr: -20 * slide, al: -40, ar: 40 })
      const [bx, by] = t < 1.15 ? [lerp(86, 126, ease(run)), 178] : t < 1.35 ? [lerp(126, 150, seg(t, 1.15, 1.35)), 168] : quad([150, 168], [110, 60], [40, 120], ease(seg(t, 1.35, 2.2)))
      at(b, bx, by, t * 500)
      txt(seg(t, 1.5, 1.85))
    } }
  },
  board(e) {
    // The fourth official's board: added time.
    const svg = sceneBase(), off = figure(svg, { kit: '#1C1C1C', ink: '#fff', trim: '#1C1C1C' }, { scale: 1.9, hair: '#111' })
    const bd = el('g', {}, svg)
    bd.innerHTML = `<rect x="-58" y="-36" width="116" height="72" rx="8" fill="#111" stroke="#3A3F4B" stroke-width="3"/><text x="0" y="16" text-anchor="middle" font-family="Alexandria" font-weight="900" font-size="46" fill="#3DDC97">+${e.plus}</text>`
    return { dur: 3, svg, update(t) {
      const up = ease(seg(t, 0.2, 0.8))
      off.pose(130, 128, { al: -150 * up, ar: 150 * up })
      at(bd, 130, lerp(220, 52, up), 0, 1 + 0.04 * Math.sin(t * 8))
    } }
  },
}
