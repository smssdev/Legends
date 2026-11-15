// [Sprint 09 G1] A minute's timeline on the feed, pure (it was inside MatchFeed.vue's play(), moved as it was): how long
// the minute is, how long its scene, the director's cutaways after it, and a goal's slow replay. Unity's MinutePlan.cs is
// its port, held to it by the golden vectors (docs/api/director-golden.json, scripts/director-golden.mjs): a change
// here is written there and in the vectors together.
import { director, type Cut, type DirectorCtx, type StoryView, type TickView } from './director.ts'
import { SCENE_TIME } from './timing.ts'

/** What the plan reads of a minute: its number, its moods and its moment's length (ms). */
export type MinuteView = TickView & { moment?: { ms?: number } | null }
export type PlanCtx = DirectorCtx & { smooth?: boolean }
export type MinutePlan = {
  total: number
  sceneT: number
  cuts: Cut[]
  cutT: number
  /** How much faster than its own length the scene plays (1 for no scene). */
  rate: number
  /** A goal's replay: when it starts (s), how slow (rate), and from how far into the scene (s). */
  replay: { at: number; rate: number; off: number } | null
}

export function planMinute(s: StoryView, tick: MinuteView, ctx: PlanCtx): MinutePlan {
  const total = (tick.moment?.ms ?? 3000) / 1000
  const nominal = s.scene ? SCENE_TIME[s.scene]![0] : 0
  // The scene takes most of the minute; the commentator sums it up after.
  // At the broadcast's fixed pace a minute is 3.3 s [X35]: the scene takes up to nine tenths of it, a little faster.
  const sceneT = s.scene ? Math.min(nominal, total * ((tick.moment?.ms ?? 0) <= 3400 ? 0.9 : 0.72)) : 0
  // [Sprint 35 C1] The director's cutaways after the scene, as many as the tier and the minute's length allow; then
  // [X41] a goal's replay in slow motion, as on TV.
  const cuts = director(s, tick, total, sceneT, ctx),
    cutT = cuts.reduce((a, c) => a + c.dur, 0)
  const at = sceneT + (cuts.length ? cutT + 0.5 : 2.6),
    room = total - at - 0.8
  // [Sprint 33 Q1] No replay at the lowest tier. Too little room for the whole scene slowed: its last part, the shot.
  const rate = s.goal && s.scene && room > 1.6 && !ctx.smooth ? Math.max(0.4, Math.min(0.8, nominal / room)) : 0
  const replay = rate ? { at, rate, off: Math.max(0, nominal - room * rate) } : null
  return { total, sceneT, cuts, cutT, rate: s.scene ? nominal / sceneT : 1, replay }
}
