// The match feed's art (docs/MATCH_VIEW.md 4.6): broadcast motion graphics in the
// brand's navy and gold, with each team's colour as light. A night pitch in
// perspective, clean player silhouettes with numbers, light trails, flashes and
// particles; crests and line icons for the timeline. Drawing only: which scene
// plays, and with whom, is the server's (tick.story, written by told.ts).
// [Sprint 57 W4] Split into parts (kit, stage, figures, effects, play, and a file per scene in clips/); this file keeps
// the public face it always had, and the variety layer over the scenes.
import { blocked } from './clips/blocked'
import { board } from './clips/board'
import { brawl } from './clips/brawl'
import { card } from './clips/card'
import { clearance } from './clips/clearance'
import { coach } from './clips/coach'
import { coachReact } from './clips/coachReact'
import { corner } from './clips/corner'
import { crowd } from './clips/crowd'
import { foul } from './clips/foul'
import { freekick } from './clips/freekick'
import { goal } from './clips/goal'
import { handshake } from './clips/handshake'
import { injury } from './clips/injury'
import { meltdown } from './clips/meltdown'
import { miss } from './clips/miss'
import { offside } from './clips/offside'
import { penalty } from './clips/penalty'
import { rant } from './clips/rant'
import { save } from './clips/save'
import { slip } from './clips/slip'
import { sub } from './clips/sub'
import { trap } from './clips/trap'
import { tunnel } from './clips/tunnel'
import { varCheck } from './clips/var'
import { whistle } from './clips/whistle'
import { SCENE_TIME } from './timing'
import { NS, SMOOTH, VARIANT, ease, el, esc, inout, lerp, rnd, sa, seg, type Scene, type SceneData, type SvgNode } from './kit'

export { setKits, setSmooth, setRich, setLight, setRain, lum, shade, mix, keeperKit, officialKit, esc, crest, ICON } from './kit'
export { SKINS, HAIR, player } from './figures'
export { REACT_COUNT, studio } from './stage'

// ---------------------------------------------------------------- scenes: one per kind of moment
// Lengths and key moments are SCENE_TIME in timing.ts; keep them in step.
export const SCENES: Record<string, (e: SceneData) => Scene> = {
  goal,
  save,
  miss,
  blocked,
  penalty,
  freekick,
  corner,
  card,
  foul,
  brawl,
  offside,
  sub,
  injury,
  clearance,
  trap,
  rant,
  slip,
  meltdown,
  coach,
  whistle,
  var: varCheck,
  tunnel,
  handshake,
  crowd,
  coachReact,
  board,
}

// ---------------------------------------------------------------- [Sprint 42 J1] the variety layer
// The owner's (2026-11-03): "500 different clips, so no match feels like the last". Every scene above already has its
// own variants (finishes, saves, celebrations, the server's dramas and gags); on top of them each scene now draws, from
// its own seed, one of 5 cameras, one of 4 headlines and one of 6 accents at its key moment: 120 looks for each of
// them. The same on every screen (the seed is the minute's), drawing only.
const CAMS = 5,
  TITLES = 4,
  ACCENTS = 6
export const VARIETY = { cams: CAMS, titles: TITLES, accents: ACCENTS }
const WORDS: Record<string, string[]> = {
  goal: ['GOAL!!', 'BOOM!', 'WOW!'],
  save: ['DENIED!', 'NO WAY!', 'WOW!'],
  miss: ['OHH!', 'SO CLOSE!', 'NOO!'],
  blocked: ['BLOCKED!', 'THUD!'],
  penalty: ['ICE COLD!', 'BOOM!', 'OH!'],
  freekick: ['WHOOSH!', 'CURL!'],
  card: ['OUCH!', 'TROUBLE!', 'OH NO!'],
  foul: ['OUCH!', 'CRUNCH!'],
  injury: ['OUCH!', 'OOF!'],
  sub: ['FRESH!', 'IN!'],
  var: ['CHECK!', 'HOLD ON!'],
  clearance: ['SAVED!', 'PHEW!'],
  trap: ['STEP UP!', 'CAUGHT!'],
  slip: ['SPLASH!', 'OOPS!'],
  rant: ['LISTEN!'],
  meltdown: ['ARGH!'],
  crowd: ['YEAH!', 'OLE!'],
  brawl: ['HEY!'],
}
const hashOf = (str: string) => {
  let h = 2166136261
  for (let i = 0; i < str.length; i++) {
    h ^= str.charCodeAt(i)
    h = Math.imul(h, 16777619)
  }
  return (h >>> 0) % 1000000
}
function vary(name: string, make: (e: SceneData) => Scene) {
  return (e: SceneData) => {
    const R = rnd(((e.v ?? hashOf(name + JSON.stringify(e))) * 13 + 7) >>> 0)
    VARIANT.cam = Math.floor(R() * CAMS)
    VARIANT.title = Math.floor(R() * TITLES)
    VARIANT.accent = Math.floor(R() * ACCENTS)
    const word = (WORDS[name] ?? ['WOW!'])[Math.floor(R() * (WORDS[name]?.length ?? 1))],
      cam = VARIANT.cam,
      acc = SMOOTH ? 0 : VARIANT.accent
    const sc = make(e)
    VARIANT.title = 0
    const svg = sc.svg,
      w = svg.world,
      KT = SCENE_TIME[name]?.[1] ?? 1,
      D = sc.dur ?? SCENE_TIME[name]?.[0] ?? 4
    // The camera: a frame round the world the scene moves itself, so the two add up.
    let rig = null
    if (w && cam) {
      rig = document.createElementNS(NS, 'g')
      w.parentNode.insertBefore(rig, w)
      rig.appendChild(w)
    }
    // The accent, over everything, at the key moment.
    const fx = el('g', { opacity: 0, 'pointer-events': 'none' }, svg)
    if (acc === 1)
      fx.innerHTML = Array.from(
        { length: 14 },
        (_, i) =>
          `<polygon points="0,-6 1.6,-1.6 6,0 1.6,1.6 0,6 -1.6,1.6 -6,0 -1.6,-1.6" fill="${i % 2 ? '#FFD36B' : '#FFFFFF'}" transform="translate(${60 + ((i * 97) % 520)} ${40 + ((i * 53) % 240)})"/>`,
      ).join('')
    if (acc === 2)
      fx.innerHTML = Array.from({ length: 28 }, (_, i) => {
        const a = (i / 28) * Math.PI * 2,
          r0 = 150 + (i % 3) * 20
        return `<path d="M${(320 + Math.cos(a) * r0).toFixed(0)} ${(170 + Math.sin(a) * r0 * 0.6).toFixed(0)} L${(320 + Math.cos(a) * 420).toFixed(0)} ${(170 + Math.sin(a) * 260).toFixed(0)}" stroke="#fff" stroke-width="${1.5 + (i % 3)}" opacity=".7"/>`
      }).join('')
    if (acc === 3)
      fx.innerHTML = `<g transform="translate(520 280) rotate(-8)"><rect x="-74" y="-24" width="148" height="44" rx="8" fill="#FFD400" stroke="#071733" stroke-width="4"/><text y="9" text-anchor="middle" font-family="Barlow Condensed, sans-serif" font-weight="800" font-style="italic" font-size="26" fill="#071733">${esc(word)}</text></g>`
    if (acc === 4) fx.innerHTML = '<rect width="640" height="340" fill="#FFFFFF"/>'
    if (acc === 5)
      fx.innerHTML = `<radialGradient id="vg${svg.dataset.id}" cx=".5" cy=".5" r=".7"><stop offset=".55" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity=".4"/></radialGradient><rect width="640" height="340" fill="url(#vg${svg.dataset.id})"/>`
    const update = sc.update
    sc.update = (t: number) => {
      update(t)
      if (rig) {
        const k = t / D,
          p = seg(t, KT - 0.05, KT + 0.12) * (1 - seg(t, KT + 0.3, KT + 1.1))
        const tr =
          cam === 1
            ? `translate(320 170) scale(${(1 + 0.07 * inout(k)).toFixed(3)}) translate(-320 -170)`
            : cam === 2
              ? `translate(320 170) rotate(${(-3 + 1.5 * Math.sin(t * 0.8)).toFixed(2)}) scale(1.08) translate(-320 -170)`
              : cam === 3
                ? `translate(${(Math.sin(t * 0.9) * 14).toFixed(1)} ${(Math.cos(t * 0.7) * 4).toFixed(1)}) translate(320 170) scale(1.05) translate(-320 -170)`
                : `translate(320 170) scale(${(1 + 0.13 * p).toFixed(3)}) translate(-320 -170)`
        sa(rig, 'transform', tr)
      }
      if (acc) {
        const on =
          acc === 4
            ? 0.55 * seg(t, KT - 0.02, KT + 0.04) * (1 - seg(t, KT + 0.06, KT + 0.3))
            : acc === 5
              ? seg(t, KT - 0.1, KT + 0.1) * (1 - seg(t, KT + 0.8, KT + 1.4))
              : seg(t, KT, KT + 0.12) * (1 - seg(t, KT + (acc === 3 ? 1.2 : 0.5), KT + (acc === 3 ? 1.5 : 0.9)))
        sa(fx, 'opacity', on.toFixed(2))
        if (acc === 1 && on > 0)
          [...fx.children].forEach((c, i) => sa(c as SvgNode, 'opacity', (0.5 + 0.5 * Math.sin(t * 20 + i)).toFixed(2)))
        if (acc === 3 && on > 0)
          sa(
            fx.firstElementChild as SvgNode,
            'transform',
            `translate(520 280) rotate(-8) scale(${lerp(1.8, 1, ease(seg(t, KT, KT + 0.18))).toFixed(2)})`,
          )
      }
    }
    return sc
  }
}
for (const k of Object.keys(SCENES)) SCENES[k] = vary(k, SCENES[k])
