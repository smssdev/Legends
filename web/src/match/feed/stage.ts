// [Sprint 57 W4] Where the scenes happen: the stadium and the pitch behind the goal, and the TV studio between them.
import { player } from './figures'
import { K, KITS, type Kit, LIGHT, RAIN, RICH, SMOOTH, type Side, type Svg, type SvgNode, el, mix, nextId, rnd, sa, seg } from './kit'

export const LINE = 150,
  POSTS = [246, 394],
  BAR = 72
export const persp = (y: number) => 0.55 + (y - LINE) * 0.0055

// [Sprint 42 K1] The stadium behind every scene, drawn in place (a picture of it, Sprint 42 I1, could show black until
// it was decoded, or not at all on some phones). Built as text once per club and light, then reused with the scene's
// own ids (@ is replaced by them). Closer to a real ground: two tiers of stands under a roof, the crowd, floodlight
// towers and their beams, the boards, and the grass in mowing stripes, brighter under the lights.
export const STADIUMS = new Map()
export function stadium(id: string, c: string, home: string) {
  const key = [c, home, KITS.home?.trim, SMOOTH, RICH, LIGHT].join('|')
  let txt = STADIUMS.get(key)
  if (!txt) {
    const L = {
      night: {
        sky: ['#030916', '#0B1C3D'],
        halo: ['#FFFFFF', 0.28],
        grass: ['#23864A', '#0F4A27'],
        stand: ['#0E1A33', '#16264A'],
        beam: 0.12,
      },
      dusk: {
        sky: ['#1E1238', '#D06A3E'],
        halo: ['#FFC08A', 0.3],
        grass: ['#2F8A3E', '#145226'],
        stand: ['#2A1C34', '#3A2742'],
        beam: 0.07,
      },
      day: { sky: ['#5C9FDB', '#CBE6F7'], halo: ['#FFFFFF', 0.1], grass: ['#3FA24C', '#1E6A2E'], stand: ['#3A4A66', '#4E5F7E'], beam: 0 },
    }[LIGHT]
    const fans = SMOOTH ? 90 : RICH ? 240 : 150,
      cols = [mix('#2B4F8C', home, 0.35), home, c, KITS.home?.trim ?? '#F5B82E', '#E6EAF2', '#C99A78']
    const CR = rnd(97)
    const crowd = Array.from({ length: fans }, (_, i) => {
      const upper = i % 3 === 0,
        x = CR() * 840 - 100,
        y = upper ? 4 + CR() * 48 : 66 + CR() * 48
      return `<circle cx="${x}" cy="${y}" r="${(upper ? 1.3 : 1.8) + (i % 3) * 0.5}" fill="${cols[i % cols.length]}" opacity="${(upper ? 0.5 : 0.7) + (i % 4) * 0.08}"/>`
    }).join('')
    const tower = (x: number) =>
      `<rect x="${x - 3}" y="-40" width="6" height="70" fill="#1A2236"/><rect x="${x - 26}" y="-46" width="52" height="20" rx="3" fill="#2A3350"/>${Array.from({ length: 8 }, (_, i) => `<rect x="${x - 23 + (i % 4) * 12}" y="${-43 + Math.floor(i / 4) * 9}" width="9" height="6" rx="1.5" fill="#FFF6DA" opacity="${LIGHT === 'day' ? 0.5 : 0.95}"/>`).join('')}`
    const beams = L.beam
      ? `<path d="M-40 -30 L140 160 L20 160 Z" fill="url(#@beam)"/><path d="M680 -30 L500 160 L620 160 Z" fill="url(#@beam)"/>`
      : ''
    txt = {
      defs: `<linearGradient id="@sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${L.sky[0]}"/><stop offset="1" stop-color="${L.sky[1]}"/></linearGradient>
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
      ${Array.from({ length: 10 }, (_, i) => {
        const y0 = LINE - 12 + Math.pow(i / 10, 1.5) * 242,
          y1 = LINE - 12 + Math.pow((i + 1) / 10, 1.5) * 242,
          k0 = y0 - LINE + 12,
          k1 = y1 - LINE + 12
        return i % 2
          ? ''
          : `<path d="M${120 - k0} ${y0} L${520 + k0} ${y0} L${520 + k1} ${y1} L${120 - k1} ${y1} Z" fill="#FFFFFF" fill-opacity=".06"/>`
      }).join('')}
      <g fill="none" stroke="#FFFFFF" stroke-opacity=".75" stroke-width="1.8"><path d="M108 ${LINE} H532"/><path d="M196 ${LINE} L160 226 H480 L444 ${LINE}"/><path d="M258 ${LINE} L250 172 H390 L382 ${LINE}"/><path d="M262 226 Q320 254 378 226"/></g>
      <ellipse cx="320" cy="207" rx="2.4" ry="1.1" fill="#fff" opacity=".9"/>`,
    }
    STADIUMS.set(key, txt)
  }
  return { defs: txt.defs.replaceAll('@', id), body: txt.body.replaceAll('@', id) }
}

// The stage: a night stadium, the pitch in perspective, boards behind the goal, the team's light.
// Everything that the camera moves sits in svg.world; titles and flashes go on top of it.
export function stage(side: Side) {
  // [Sprint 37 N5] The stadium is the home club's: its stand and the board under it take its colours.
  const c = K(side).kit,
    home = KITS.home?.kit ?? '#2B4F8C',
    id = 's' + nextId()
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
  ${[60, 220, 380, 540].map((x) => `<text x="${x}" y="134" font-family="Tajawal, sans-serif" font-weight="800" font-size="10" letter-spacing="3" fill="#FFD36B" opacity=".8">LEGENDS</text>`).join('')}
  </g>
  <rect width="640" height="340" fill="url(#${id}c)" pointer-events="none"/>${RAIN ? `<style>.rain{animation:rainfall .5s linear infinite}@keyframes rainfall{to{transform:translate(-5px,30px)}}@media (prefers-reduced-motion:reduce){.rain{animation:none}}</style><g class="rain" stroke="rgba(200,215,235,.45)" stroke-width="1.1">${Array.from({ length: SMOOTH ? 30 : 90 }, (_, i) => `<line x1="${(i * 73) % 680}" y1="${((i * 41) % 360) - 20}" x2="${((i * 73) % 680) - 5}" y2="${((i * 41) % 360) + 10}"/>`).join('')}</g><rect width="640" height="340" fill="rgba(40,55,75,.18)"/>` : ''}`
  svg.dataset.id = id
  svg.world = svg.querySelector<SvgNode>('[data-world]')!
  return svg
}
export const ref = (svg: Svg, name: string) => ((SMOOTH || !RICH) && name === 'glow' ? 'none' : `url(#${name}${svg.dataset.id})`)
// The camera: zoom z around a point that stays put on screen.
export const cam = (svg: Svg, z: number, fx = 320, fy = 170, dx = 0, dy = 0) =>
  sa(svg.world, 'transform', `translate(${fx + dx} ${fy + dy}) scale(${z}) translate(${-fx} ${-fy})`)

// The goal with a net that bulges where the ball hits it.
export function goalFrame(svg: Svg, p = svg.world) {
  const g = el('g', {}, p),
    net = el('g', { fill: 'none', stroke: '#C2CDE3', 'stroke-width': 0.65, opacity: 0.6 }, g)
  const lines: { e: SvgNode; pts: number[][] }[] = []
  const line = (pts: number[][]) => {
    const e = el('polyline', { points: pts.map((q) => q.join(',')).join(' ') }, net)
    lines.push({ e, pts })
  }
  // The back of the net seen through the mouth, its roof, and its sides.
  for (let i = 0; i <= 16; i++) {
    const x = 250 + i * 8.75
    line(Array.from({ length: 9 }, (_, j) => [x, 60 + j * 10.5]))
  }
  for (let j = 0; j <= 8; j++) line(Array.from({ length: 17 }, (_, i) => [250 + i * 8.75, 60 + j * 10.5]))
  for (let i = 0; i <= 14; i++)
    line([
      [POSTS[0] + i * 10.57, BAR],
      [250 + i * 10, 60],
    ])
  for (const [a, b] of [
    [POSTS[0], 250],
    [POSTS[1], 390],
  ])
    for (let j = 0; j <= 6; j++)
      line([
        [a, BAR + j * 13],
        [b, 60 + j * 12.7],
      ])
  el(
    'path',
    {
      d: `M${POSTS[0] + 3} ${LINE + 1} L${POSTS[0] - 10} ${LINE + 5} M${POSTS[1] - 3} ${LINE + 1} L${POSTS[1] + 10} ${LINE + 5}`,
      stroke: 'rgba(0,0,0,.35)',
      'stroke-width': 4,
    },
    g,
  )
  const frame = el(
    'path',
    {
      d: `M${POSTS[0]} ${LINE} V${BAR} H${POSTS[1]} V${LINE}`,
      fill: 'none',
      stroke: '#fff',
      'stroke-width': 4.5,
      'stroke-linejoin': 'round',
      filter: ref(svg, 'glow'),
    },
    g,
  )
  let bulged = false
  return {
    g,
    frame,
    bulge(x0: number, y0: number, f: number) {
      if (f <= 0 && !bulged) return
      bulged = f > 0
      for (const { e, pts } of lines)
        sa(
          e,
          'points',
          pts
            .map(([x, y]) => {
              const k = f * Math.exp(-((x - x0) ** 2 + (y - y0) ** 2) / 1300)
              return `${x + (x - x0) * 0.18 * k},${y - 13 * k + (y - y0) * 0.1 * k}`
            })
            .join(' '),
        )
    },
  }
}

// A player: legs, shorts, shirt with the number, arms and head, each part posable (running, striking, diving,
// celebrating). look picks the skin and hair. Seen from behind by default; face() turns him to the camera or to his
// side (mirrored for the other side) [Sprint 31 M4]: the live pitch picks it from where he runs.

// ---------------------------------------------------------------- [Sprint 42 H1] the TV studio
// The owner's (2026-11-03): the match shown like TV, with commentators in a studio. Between the moments the picture
// is the studio: an LED wall with the score and the running clock, and two cartoon commentators at their desk with
// headsets, talking in turn when a line is said, and on their feet at a goal. Drawing only (MatchFeed feeds it).
// [Sprint 42 J2] The commentators' reactions. f: 0..1 over about three seconds; side: 1 the left one, -1 the right one
// (each faces the other). Returns how far he moves (dx towards the other, dy up), his lean, his arms (as pose()), his
// face and the word over his head.
/** A commentator's reaction at f (0..1 of it) and t: how he moves, his face, his pose, the word over his head. */
type React = { dx?: number; dy?: number; r?: number; pose?: number[]; mood?: string; face?: string; sym?: string }
export const REACTIONS: Record<string, (f: number, t: number, m?: number) => React> = {
  jump: (_f: number, t: number) => ({
    dy: Math.abs(Math.sin(t * 9)) * 16,
    pose: [6, -6, 155 + Math.sin(t * 12) * 12, -155 - Math.sin(t * 12) * 12],
    mood: 'joy',
    sym: 'GOAL!',
  }),
  hug: (f: number) => ({ dx: 70 * Math.sin(Math.PI * f), r: 8 * Math.sin(Math.PI * f), pose: [4, -4, 95, -40], mood: 'joy', sym: '♥' }),
  desk: (_f: number, t: number) => ({
    dy: -2,
    pose: [4, -4, 20 + Math.abs(Math.sin(t * 14)) * 70, -20 - Math.abs(Math.sin(t * 14 + 1)) * 70],
    mood: 'joy',
    sym: 'BAM!',
  }),
  spin: (f: number) => ({
    face: f > 0.2 && f < 0.6 ? 'back' : 'front',
    dy: 8 * Math.sin(Math.PI * f),
    pose: [4, -4, 120, -120],
    mood: 'joy',
    sym: 'YES!',
  }),
  applaud: (_f: number, t: number) => ({ pose: [4, -4, 70 + Math.sin(t * 22) * 22, -70 + Math.sin(t * 22) * 22], mood: 'joy', sym: '★★★' }),
  wow: (f: number) => ({ r: -6 * Math.sin(Math.PI * f), pose: [4, -4, 100, -100], mood: 'shock', sym: 'WOW!' }),
  headhands: () => ({ pose: [4, -4, 150, -150], mood: 'shock', sym: '!?' }),
  facepalm: () => ({ r: 6, pose: [4, -4, 22, 160], mood: 'sad', sym: '...' }),
  leanback: (f: number) => ({ r: -10 * Math.sin(Math.PI * f), dy: -4, pose: [4, -4, 40, -40], mood: 'sad', sym: 'OHH' }),
  point: (_f: number, t: number) => ({ pose: [4, -4, 88 + Math.sin(t * 10) * 6, -22], mood: 'angry', sym: '!' }),
  headshake: (_f: number, t: number) => ({ r: Math.sin(t * 16) * 6, pose: [4, -4, 22, -22], mood: 'angry', sym: 'NO!' }),
  crossarms: () => ({ pose: [4, -4, -30, 30], mood: 'focus', sym: 'hmm' }),
  laugh: (_f: number, t: number) => ({
    dy: Math.abs(Math.sin(t * 18)) * 5,
    r: Math.sin(t * 9) * 4,
    pose: [4, -4, 40, -40],
    mood: 'joy',
    sym: 'HAHA',
  }),
  eyeroll: (_f: number) => ({ r: 4, pose: [4, -4, -20, 20], mood: 'peek', sym: '¬_¬' }),
  worried: (_f: number, t: number) => ({ r: Math.sin(t * 3) * 2, pose: [4, -4, -20, 20], mood: 'sad', sym: '...' }),
  nails: (_f: number, t: number) => ({ dy: Math.sin(t * 20) * 1.5, pose: [4, -4, 150, -22], mood: 'shock', sym: '!!' }),
  nod: (_f: number, t: number) => ({ dy: Math.max(0, Math.sin(t * 8)) * 3, pose: [4, -4, 22, -22], mood: 'focus', sym: '✓' }),
  notes: (_f: number, t: number) => ({ pose: [4, -4, 30 + Math.sin(t * 14) * 6, -30], mood: 'focus', sym: '✎' }),
  monitor: (f: number) => ({
    face: 'side',
    dx: 22 * Math.sin(Math.PI * Math.min(1, f * 1.4)),
    pose: [4, -4, 30, -30],
    mood: 'focus',
    sym: '?',
  }),
  handshake: (f: number) => ({ dx: 50 * Math.sin(Math.PI * f), pose: [4, -4, 22, -85], mood: 'joy', sym: '' }),
  dance: (_f: number, t: number) => ({
    dy: Math.abs(Math.sin(t * 10)) * 8,
    r: Math.sin(t * 10) * 8,
    pose: [4, -4, 90 + Math.sin(t * 10) * 40, -90 + Math.sin(t * 10) * 40],
    mood: 'joy',
    sym: '♪♪',
  }),
}
// What each moment may draw from them (MatchFeed names the moment). Each commentator picks his own.
export const REACT_POOLS: Record<string, string[]> = {
  goal: ['jump', 'hug', 'desk', 'spin', 'dance', 'applaud'],
  save: ['applaud', 'wow', 'headhands', 'point'],
  miss: ['facepalm', 'headhands', 'leanback', 'wow'],
  post: ['headhands', 'wow', 'facepalm'],
  yellow: ['point', 'headshake', 'crossarms', 'nod'],
  red: ['wow', 'headshake', 'point', 'headhands'],
  brawl: ['wow', 'headhands', 'laugh', 'headshake'],
  foul: ['worried', 'headshake', 'point'],
  dive: ['laugh', 'eyeroll', 'headshake'],
  injury: ['worried', 'nails'],
  sub: ['nod', 'notes', 'crossarms'],
  var: ['monitor', 'crossarms', 'headshake'],
  offside: ['monitor', 'point', 'nod'],
  penalty_goal: ['jump', 'applaud', 'nails'],
  penalty_miss: ['headhands', 'wow', 'nails'],
  freekick: ['wow', 'applaud', 'leanback'],
  corner: ['nod', 'notes'],
  coach: ['laugh', 'notes', 'nod'],
  slip: ['laugh', 'wow', 'facepalm'],
  whistle: ['handshake', 'notes', 'nod'],
  clearance: ['wow', 'applaud', 'headhands'],
  double: ['applaud', 'wow', 'jump'],
  blackout: ['wow', 'laugh', 'headhands'],
  calm: ['nod', 'notes'],
}
export const REACT_COUNT = Object.keys(REACTIONS).length

/** The studio's moment: the clock, the score, the clock frozen, who talks, the goal's hype, the clip just seen. */
export type StudioState = {
  clock: string
  score: string
  frozen?: boolean
  talk?: number
  hype?: number
  react?: { key: string; seed: number; t0: number } | null
}
export function studio(kits: Record<Side, Kit>, seed = 1, day = false) {
  // [Sprint 42 J2] Each match its studio: the LED wall's colours, the desk's trim and the two commentators (their
  // faces, hair, suits and ties), all from the match's seed. [Sprint 43 C7] By day in the day look.
  const SR = rnd((Number(seed) || 1) * 101 + 17)
  const THEMES = [
    ['#0E2A5C', '#123A7A', '#0A2148', '#0B1A3A'],
    ['#2A1352', '#3B1D74', '#1E0E3D', '#170B30'],
    ['#063F45', '#0B5C63', '#052E33', '#06232A'],
    ['#4A0E1E', '#6B1428', '#330915', '#210610'],
  ]
  const TH = THEMES[Math.floor(SR() * THEMES.length)],
    TRIM = SR() < 0.6 ? ['#C08A0C', '#FFD36B'] : ['#8C96A8', '#F2F5FA']
  const SUITS = ['#22304F', '#2A2F45', '#3A2A2A', '#1F3B34', '#2E2E2E', '#3A3150', '#1C2A3F'],
    TIES = ['#F5B82E', '#7FB4FF', '#D21F1F', '#2BB673', '#E85D9A', '#FFFFFF']
  const crew = [0, 1].map(() => ({
    suit: SUITS[Math.floor(SR() * SUITS.length)],
    tie: TIES[Math.floor(SR() * TIES.length)],
    look: Math.floor(SR() * 42),
  }))
  const svg = el('svg', { viewBox: '0 0 640 340', preserveAspectRatio: 'xMidYMid slice', direction: 'ltr' }),
    id = 's' + nextId()
  svg.style.direction = 'ltr'
  svg.dataset.id = id
  const H = kits?.home?.kit ?? '#C8102E',
    A = kits?.away?.kit ?? '#1E4FA8'
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
  const suit = (trim: string) => ({ look: 0, shorts: '#1F2937', socks: '#111827', trim })
  const c1 = player(g, crew[0].suit, '', 2.1, { ...suit(crew[0].tie), look: crew[0].look }),
    c2 = player(g, crew[1].suit, '', 2.1, { ...suit(crew[1].tie), look: crew[1].look })
  // Headsets with their mics.
  const hs = [0, 1].map(() => {
    const e = el('g', {}, g)
    e.innerHTML =
      '<path d="M-11 -24 Q0 -38 11 -24" fill="none" stroke="#111" stroke-width="2.4"/><rect x="-12.5" y="-25" width="4" height="7" rx="1.5" fill="#111"/><rect x="8.5" y="-25" width="4" height="7" rx="1.5" fill="#111"/><path d="M-10.5 -19 Q-9 -12 -3 -13" fill="none" stroke="#111" stroke-width="1.6"/><circle cx="-2.5" cy="-13" r="1.6" fill="#F5B82E"/>'
    return e
  })
  // The desk in front of them: curved, with the channel's mark, two mics and a laptop.
  const desk = el('g', {}, svg)
  desk.innerHTML = `<path d="M40 236 Q320 206 600 236 L620 340 L20 340 Z" fill="url(#${id}desk)" stroke="url(#gold${id})" stroke-width="3"/>
    <path d="M70 262 Q320 236 570 262" fill="none" stroke="rgba(127,180,255,.25)" stroke-width="2"/>
    <text x="320" y="262" text-anchor="middle" font-family="Barlow Condensed, sans-serif" font-weight="800" font-size="22" letter-spacing="6" fill="url(#gold${id})">GLM TV</text>
    <rect x="290" y="214" width="60" height="22" rx="3" fill="#0A0F1C" stroke="#3A4256"/><rect x="294" y="217" width="52" height="15" fill="#123A7A" opacity=".8"/>
    <g fill="#111"><rect x="196" y="206" width="4" height="26"/><ellipse cx="198" cy="204" rx="6" ry="8"/><rect x="438" y="206" width="4" height="26"/><ellipse cx="440" cy="204" rx="6" ry="8"/></g>`
  const score = svg.querySelector<SvgNode>('[data-score]')!,
    clockT = svg.querySelector<SvgNode>('[data-clock]')!,
    spot = svg.querySelector<SvgNode>('[data-spot]')!
  const POS = [
    [190, 196],
    [450, 196],
  ]
  // [Sprint 42 J2] Over each head, the word of his reaction.
  const syms = [0, 1].map(() =>
    el(
      'text',
      {
        'text-anchor': 'middle',
        'font-family': 'Barlow Condensed, sans-serif',
        'font-weight': 800,
        'font-size': 22,
        fill: '#FFD36B',
        stroke: '#040B1C',
        'stroke-width': 4,
        'paint-order': 'stroke',
        opacity: 0,
      },
      svg,
    ),
  )
  let lastScore: string | null = null,
    react: StudioState['react'] = null,
    picks: string[] | null = null
  return {
    svg,
    /** t: seconds. st: { clock, score ('away - home', home on the right as on the scorebar), frozen, talk (0 none, 1 or 2: who is talking), hype (0..1, a goal) } */
    update(t: number, st: StudioState) {
      if (st.score !== lastScore) {
        lastScore = st.score
        score.textContent = st.score
      }
      if (clockT.textContent !== st.clock) clockT.textContent = st.clock
      sa(clockT, 'opacity', st.frozen ? (Math.floor(t * 2.5) % 2 ? 0.35 : 1) : 1)
      const hype = st.hype ?? 0
      sa(spot, 'opacity', (hype * (0.6 + 0.4 * Math.sin(t * 9))).toFixed(2))
      // [Sprint 42 J2] Back from a clip, each commentator reacts to it, each in his own way (from the pool for that
      // moment, by the minute's seed): about three seconds, then back to talking.
      if (st.react && st.react !== react) {
        react = st.react
        const R = rnd((react.seed >>> 0) + 1),
          pool = REACT_POOLS[react.key] ?? REACT_POOLS.calm
        picks = [pool[Math.floor(R() * pool.length)], pool[Math.floor(R() * pool.length)]]
      }
      const rf = react ? (t - react.t0) / 3 : 2
      ;[c1, c2].forEach((c, i) => {
        const [x0, y0] = POS[i]
        if (rf >= 0 && rf < 1 && picks) {
          const r = REACTIONS[picks[i]]?.(rf, t, i ? -1 : 1) ?? {}
          const dx = (r.dx ?? 0) * (i ? -1 : 1),
            y = y0 - (r.dy ?? 0)
          c.face?.(r.face ?? 'front', i ? -1 : 1)
          c.mood(r.mood ?? 'idle')
          c.at(x0 + dx, y, (r.r ?? 0) * (i ? -1 : 1), 2.1)
          const P = r.pose ?? [4, -4, 22, -22]
          c.pose(...(i ? [P[1] * -1, P[0] * -1, -P[3], -P[2]] : P))
          sa(
            hs[i],
            'transform',
            `translate(${(x0 + dx).toFixed(1)} ${y.toFixed(1)}) rotate(${((r.r ?? 0) * (i ? -1 : 1)).toFixed(1)}) scale(2.1)`,
          )
          const so = seg(rf, 0.05, 0.15) * (1 - seg(rf, 0.8, 0.95))
          syms[i].textContent = r.sym ?? ''
          sa(syms[i], 'opacity', r.sym ? so.toFixed(2) : 0)
          sa(syms[i], 'x', (x0 + dx).toFixed(1))
          sa(syms[i], 'y', (y - 78 - so * 6).toFixed(1))
          return
        }
        sa(syms[i], 'opacity', 0)
        const talking = st.talk === i + 1,
          [x, y] = POS[i],
          up = hype > 0 ? 18 * hype + Math.abs(Math.sin(t * 8 + i)) * 6 * hype : 0
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
