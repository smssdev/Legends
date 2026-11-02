// @ts-nocheck
// [Sprint 37 R1] What each player on the live pitch is doing this instant (kick, header, slide, dive, celebration,
// the keeper's catch and throw, the fouled player down and the referee's call), as a pure function of the minute's
// Keyframes and events, so the node check (scripts/feed.mjs) runs it without a screen. Drawing only: nothing here
// decides the game, and it reads the plan and the ball, never the tactics.
import { segment } from '../frames.ts'

export type ActionCtx = {
  /** The keepers' ids, as strings. */
  gks: Set<string>
  /** Which side a player is on. */
  sideOf: (id: any) => 'home' | 'away' | undefined
}
export type Actions = {
  by: Record<string, any>
  holder: any
  call: { at: any; card: string | null; w: number } | null
  /** [key, sound]: the screen plays each key once a minute. */
  sounds: [string, string][]
}

export function pitchActions(tick, f, u: number, ctx: ActionCtx): Actions {
  const by: Record<string, any> = {}, sounds: [string, string][] = [], gks = ctx.gks
  if (!f || f.length < 2) return { by, holder: f?.[0]?.h ?? null, call: null, sounds }
  const say = (key: string, name: string) => { sounds.push([key, name]) }
  const { i, k } = segment(f.length, u), A = f[i], B = f[i + 1] ?? A
  const far = Math.hypot(B.b[0] - A.b[0], B.b[1] - A.b[1])
  const sideOf = ctx.sideOf
  // [Sprint 34 K2] From the touchline it is a throw-in: both hands over the head.
  const line = A.b[1] <= 20 || A.b[1] >= 660
  if (A.h != null && far > 60 && k < 0.3) { const head = (A.b[2] ?? 0) > 12; by[A.h] = { kind: line ? 'throwin' : head ? 'head' : 'kick', f: k / 0.3 }; say('t' + i, head ? 'head' : 'touch') }
  if (B.h != null && B.h !== A.h && (B.b[2] ?? 0) > 12 && k > 0.7) { by[B.h] = { kind: 'head', f: (k - 0.7) / 0.3 }; if (k > 0.85) say('h' + i, 'head') }
  const foul = (tick.events ?? []).some((e) => e.type === 'foul')
  if (A.h != null && B.h != null && sideOf(A.h) && sideOf(B.h) && sideOf(A.h) !== sideOf(B.h) && k > 0.55 && (foul || (tick.tick * 7 + i) % 3 === 0)) by[B.h] = { kind: 'slide', f: (k - 0.55) / 0.45 }
  const shot = (tick.events ?? []).some((e) => e.type === 'attack' && ['goal', 'saved', 'missed'].includes(e.result))
  // A shot reaching the goal's area (a save stops at 4.5 m from the line), going that way.
  const end = B.b[0] < 60 && B.b[0] < A.b[0] ? 0 : B.b[0] > 990 && B.b[0] > A.b[0] ? 1050 : null
  if (shot && end !== null && Math.abs(B.b[1] - 340) < 120 && k > 0.45) {
    let gk = null, gd = 1e9
    for (const id in A.p) if (gks.has(String(id))) { const d = Math.abs(A.p[id][0] - end); if (d < gd) { gd = d; gk = id } }
    if (gk && gd < 120) by[gk] = { kind: 'dive', f: (k - 0.45) / 0.55, dir: B.b[1] > A.p[gk][1] ? 1 : -1 }
  }
  const ev = tick.events ?? [], at = u * (f.length - 1)
  // The Keyframe nearest a goal line (the path need not land on the line itself): where a shot ends.
  let g = 0
  f.forEach((x, n) => { if (Math.abs(x.b[0] - 525) > Math.abs(f[g].b[0] - 525)) g = n })
  const shotEnd = Math.abs(f[g].b[0] - 525) > 440 ? g : -1
  // The goal: from the Keyframe where the ball is in the net, the scorers' side celebrates and the other hangs its head.
  const goal = ev.find((e) => e.type === 'goal')
  if (goal && shotEnd >= 0 && Math.abs(f[g].b[0] - 525) > 470 && at >= shotEnd) {
    say('net', 'net')
    for (const id in B.p) if (!gks.has(String(id))) by[id] = sideOf(id) === goal.team ? { kind: 'party' } : { kind: 'down' }
  }
  // [Sprint 33 L4] A chance missed: the shooter's hands on his head once the ball has gone wide.
  const miss = ev.find((e) => e.type === 'attack' && e.result === 'missed')
  if (miss?.shooter != null && shotEnd >= 0 && at >= shotEnd) by[miss.shooter] = { kind: 'head-hands' }
  // [Sprint 33 L1] A save: from the Keyframe of the save the keeper holds the ball, then throws it out.
  const saved = ev.find((e) => (e.type === 'attack' && e.result === 'saved') || ((e.type === 'free_kick' || e.type === 'penalty') && !e.scored))
  if (saved && shotEnd >= 0 && at >= shotEnd) {
    const S = f[shotEnd], end = S.b[0] < 525 ? 0 : 1050
    let gk = null, gd = 1e9
    for (const id in S.p) if (gks.has(String(id))) { const d = Math.abs(S.p[id][0] - end); if (d < gd) { gd = d; gk = id } }
    if (gk) {
      const after = i === shotEnd && B !== A ? k : shotEnd === f.length - 1 ? 0 : 1
      if (after < 0.3) by[gk] = { kind: 'gather' }
      else if (after < 0.7) { by[gk] = { kind: 'throw', f: (after - 0.3) / 0.4 }; if (after > 0.5) say('gk', 'touch') }
    }
  }
  // [Sprint 33 L2] A foul: the fouled player goes down where he had the ball (or mid-minute), the whistle, the
  // referee runs over and, when the minute has a card for the fouler, holds it up.
  const fouled = ev.find((e) => e.type === 'foul')
  let call: Actions['call'] = null
  if (fouled?.victim != null) {
    const n = f.findIndex((x) => String(x.h) === String(fouled.victim))
    const from = n >= 0 ? n / (f.length - 1) : 0.4
    if (u >= from && u < from + 0.32) {
      const w = (u - from) / 0.32
      by[fouled.victim] = { kind: 'fallen', f: w }
      say('foul', 'whistle')
      const card = ev.find((e) => e.type === 'card' && String(e.player) === String(fouled.player))
      call = { at: fouled.victim, card: card && w > 0.35 ? (card.color === 'red' ? '#D3122F' : '#F2E205') : null, w }
    }
  }
  return { by, holder: k < 0.5 ? A.h : B.h, call, sounds }
}
